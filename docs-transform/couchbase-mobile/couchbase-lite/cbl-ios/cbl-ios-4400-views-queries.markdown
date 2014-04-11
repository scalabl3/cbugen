## Working With Views and Queries


The basic document API gets you pretty far, but most apps need to work with multiple documents. In a typical app, the top-level UI usually shows either all the documents or a relevant subset of them &mdash; in other words, the results of a query.

Querying a Couchbase Lite database involves first creating a *view* that indexes the keys you're interested in and then running a *query* to get the results of the view for the key or range of keys you're interested in. The view is persistent, like a SQL index.

Because there's no fixed schema for the view engine to refer to and the interesting bits of a document that we want it to index could be located anywhere in the document (including nested values inside of arrays and subobjects), the view engine has to let us pick through each document to identify the relevant key (or keys) and values. That's what the view's *map function* is for: it's an app-defined function that's given a document's contents and returns, or *emits*, zero or more key-value pairs. These key-value pairs get indexed, ordered by key, and can then be queried efficiently, again by key.

### Example: An Address Book

For example, if you have an address book in a database, you might want to query the cards by first or last name, for display or filtering purposes. To do that, you create two views: one to grab the first-name field and return it as the key, and the other to return the last-name field as the key. (And what if you were originally just storing the full name as one string? Then your functions can detect that, split the full name at the space, and return the first or last name. That's how schema evolution works.)

You might also want to be able to look up people's names from phone numbers so you can do Caller ID on incoming calls. To do this, make a view whose keys are phone numbers. Now, a document might have multiple phone numbers in it, like the following example JSON document:

```json
{
   "first":"Bob",
   "last":"Dobbs",
   "phone":{
      "home":"408-555-1212",
      "cell":"408-555-3774",
      "work":"650-555-8333"
   }
}
```
No problem&mdash;the map function just needs to loop over the phone numbers and emit each one. You then have a view index that contains each phone number, even if several of them map to the same document.

### Getting All Documents

To start off, for simplicity, this section shows how you can retrieve all documents in the database without using a view.

To retrieve all the documents in the database, you need to create a `CBLQuery` object.
The  `createAllDocumentsQuery` method in the `CBLDatabase` class returns a new `CBLQuery` object that contains all documents in the database:

	CBLQuery* query = [database createAllDocumentsQuery];

After you obtain the new `CBLQuery` object, you can customize it (this is similar to the SQL `SELECT` statement `ORDER BY`, `OFFSET` and `LIMIT` clauses). The following example shows how to retrieve the ten documents with the highest keys:

	query.limit = 10;
	query.descending = YES;

As a side effect you get the documents in reverse order, but you can compensate for that if it's not appropriate. Now you can iterate over the results:

```
NSError *error;
CBLQueryEnumerator *rowEnum = [query run: &error];
for (CBLQueryRow* row in rowEnum) {
		NSLog(@"Doc ID = %@", row.key);
}
```

`[query run: &error]` evaluates the query and returns an `NSEnumerator` object that you can use with a `for...in` loop to iterate over the results. Each result is a `CBLQueryRow` object. You might expect the result to be a `CBLDocument`, but the key-value pairs emitted in views don't necessarily correspond one-to-one to documents and a document might be present multiple times under different keys. If you want the document that emitted a row, you can get it from the row's `document` property.

### Creating Views

To create a view, define its map (and optionally its reduce) function. When you define the MapReduce functions, you also assign a version identifier to the function. If you change the MapReduce function later, you must remember to change the version so Couchbase Lite rebuilds the index.

Here's how the Grocery Sync example app sets up its by-date view:

    CBLView* view = [db viewNamed: @"byDate"];
    
    [view setMapBlock: MAPBLOCK({
        id date = [doc objectForKey: @"created_at"];
        if (date) emit(date, doc);
    }) version: @"1.0"];

The name of the view is arbitrary, but you need to use it later on when querying the view. The interesting part here is the `MAPBLOCK` expression, which is a block defining the map function. If you get an error about "too many arguments provided to function-like macro invocation," it just means the preprocess is confused. Try putting parentheses around the expression with commas in it. `MAPBLOCK` is a preprocessor macro used to simplify the declaration of the block. Here's what a block looks like without it:

    ^(NSDictionary* doc, void (^emit)(id key, id value)) {
        id date = [doc objectForKey: @"created_at"];
        if (date) emit(date, doc);
    }

This is a block that takes the following parameters:

 * An NSDictionary&mdash;this is the contents of the document being indexed.
 * A function (a block) called `emit` that takes the parameters `key` and `value`. This is the function your code calls to emit a key-value pair into the view's index.

After you get that, the example map block is straightforward: it looks for a `created_at` property in the document, and if it's present, it emits it as the key, with the entire document contents as the value. Emitting the document as the value is fairly common. It makes it slightly faster to read the document at query time, at the expense of some disk space.

The view index then consists of the dates of all documents, sorted in order. This is useful for displaying the documents ordered by date (which Grocery Sync does), or for finding all documents created within a certain range of dates.

Any document without a `created_at` field is ignored and won't appear in the view index. This means you can put other types of documents in the same database (such as names and addresses of of grocery stores) without them messing up the display of the shopping list.

<div class="notebox">
<p>Note</p>
<p>The view index itself is persistent, but the <code>setMapBlock:reduceBlock:version:</code> and <code>setMapBlock:version:</code> methods must be called every time the app starts, before the view is accessed. You need to call them because the map function <em>is not</em> persistent&mdash;it's an ephemeral block pointer that needs to be hooked up to Couchbase Lite at run time.</p>
</div>

### Querying Views

Now that the view is created, querying it is very much like querying `createAllDocumentsQuery`, except that you get the `CBLQuery` object from the view rather than the database:

    CBLQuery* query = [[db viewNamed: @"byDate"] createQuery];

Every call to `createQuery` creates a new `CBLQuery` object, ready for you to customize. You can set a number of properties to specify key ranges, ordering, and so on. as described in the [view and query design](#view-and-query-design) section. Then you run the query exactly as described previously in [Getting All Documents](#getting-all-documents).

### Updating Queries

It can be useful to know whether the results of a query have changed. You might have generated some complex output, like a fancy graph, from the query rows, and would prefer to save the work of recomputing the graph if nothing has changed. You can accomplish this by keeping the `CBLQueryEnumerator` object around, and then later checking its `stale` property. This property returns `true` if the results are out of date:

```
if (rowEnum.stale) {
   rowEnum = [query run: &error];
}
```
### Using Live Queries

Even better than _checking_ for a query update is getting _notified_ when one happens. Users expect apps to be live and don't want to have to press a refresh button to see new data. This is especially true if data might arrive over the network at any time through synchronization &mdash; that new data needs to show up right away.

For this reason Couchbase Lite has a very useful subclass of `CBLQuery` called `CBLLiveQuery`, which has a `rows` property that updates automatically as the database changes. The `rows` property is _observable_ using Cocoa's key-value Observing (KVO) mechanism. That means you can register for immediate notifications when it changes, and use those to drive user-interface updates.

To create a `CBLLiveQuery` you just ask a regular query object for a live copy of itself. You can then register as an observer:

	self.liveQuery = query.asLiveQuery;
    [self.liveQuery addObserver: self forKeyPath: @"rows" options: 0 context: NULL];

Don't forget to remove the observer when cleaning up. The observation method might look like this:

	- (void) observeValueForKeyPath: (NSString*)keyPath 
	                       ofObject: (id)object
	                         change: (NSDictionary*)change
                            context: (void*)context
	{
	    if (object == self.liveQuery) {
			for (CBLQueryRow* row in object.rows) {
				// update the UI
			}
		}
	}

### Using an Automatic Table Source

And what's even better than a live query? A live query that automatically acts as the data source of a `UITableView`. That's what `CBLUITableSource` provides: it's an implementation of `UITableViewDataSource` that observes a `CBLLiveQuery` and syncs the table with the view rows. To use it, you need to:

 1. Instantiate a `CBLUITableSource` object. One easy way is to put one in the same .xib as the table view.
 2. Set its `tableView` property to the `UITableView`. This is an IBOutlet so you can wire it up.
 3. Set its `query` property to a `CBLLiveQuery`.
 4. Set its `labelProperty` property to the name of a property in the view row's value (or in the associated document). The value of this property is the text that is displayed in the table cell's label.

If you want more control over the label, or want to use a fancier cell with more than just text, you can implement the `CBLUITableDelegate` protocol and set that object as the table source's delegate. This gives you a number of optional methods you can implement that will allow you to substitute your own `UITableCell` and handle errors. 

### View and Query Design

#### All Matching Results

If you run the query without setting any key ranges, the result is all the emitted rows, in ascending order by key (date, in this example.) To reverse the order, set the query's `descending` property.

#### Exact Queries

To get only the rows with specific keys, set the query's `keys` property to an array of the desired keys:

    query.keys = @[aSpecificDate];

The order of the keys in the array doesn't matter; the results are returned in ascending-key order.

#### Key Ranges

To get a range of keys, set the query's `startKey` and `endKey` properties. The range is inclusive, that is, the result includes the rows with key equal to `endKey`.

One common source of confusion is combining key ranges with descending order. Remember that you're specifying the _starting_ and _ending_ keys, not the _minimum_ and _maximum_ values. In a descending query, the `startKey` should be the maximum value and the `endKey` the minimum value.

#### Compound Keys

The real power of views comes when you use compound keys. If your map function emits arrays as keys, they are sorted as you would expect: the first elements are compared, and if they're equal the second elements are compared, and so forth. This lets you sort the rows by multiple criteria (like store and item), or group together results that share a criterion.

For example, if a map function emitted the document's `store` and `item` properties as a compound key:

    emit(@[doc[@"store"], doc[@"item"]], nil);

then the view's index contains a series of keys ordered like this:

    ...
    ["Safeway", "goldfish crackers"]
    ["Safeway", "tonic water"]
    ["Trader Joe's", "chocolate chip cookies"]
    ["Whole Foods", "cruelty-free chakra lotion"]
    ...

##### Compound-Key Ordering

The ordering of compound keys depends entirely on how you want to query them; the broader criteria go to the left of the narrower ones. For some queries you might need a different ordering than for others. If so, you need to define a separate view for each ordering. For example, the above ordering is good for finding all the items to buy at a particular store. If instead you want to look up a specific item and see what stores to get it at, you'd want the compound keys in the opposite order. So you could define views called "stores" and "items", and query whichever one is appropriate.

##### Compound-Key Ranges

The way you specify the beginning and end of compound-key ranges can be a bit unintuitive. For example, you have a view whose keys are of the form `[store, item]` and you want to find all the items to buy at Safeway. What are the `startKey` and `endKey`? Clearly, their first elements are `@"Safeway"`, but what comes after that? You need a way to specify the minimum and maximum possible keys with a given first element. The code to set the start and keys looks like this:

    query.startKey = @[ @"Safeway" ];
    query.endKey = @[ @"Safeway", @{} ];

The minimum key with a given first element is just a length-1 array with that element. (This is just like the way that the word "A" sorts before any other word starting with "A".)

The maximum key contains an empty `NSDictionary` object. Couchbase Lite defines a sorting or collation order for all JSON types, and JSON objects (also known as dictionaries) sort after everything else. An empty dictionary is kind of like a "Z" on steroids: it's a placeholder that sorts after any string, number, or array. It looks weird at first, but it's a useful idiom used in queries to represent the end of a range.
