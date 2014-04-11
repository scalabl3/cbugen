# Update Operations

The update methods support different methods of updating and changing existing
information within Couchbase. A list of the available methods is listed below.

<a id="couchbase-sdk-net-update-append"></a>

## Append Methods

The `Append()` methods allow you to add information to an existing key/value
pair in the database. You can use this to add information to a string or other
data after the existing data.

The `Append()` methods append raw serialized data on to the end of the existing
data in the key. If you have previously stored a serialized object into
Couchbase and then use Append, the content of the serialized object will not be
extended. For example, adding an `List` of integers into the database, and then
using `Append()` to add another integer will result in the key referring to a
serialized version of the list, immediately followed by a serialized version of
the integer. It will not contain an updated list with the new integer appended
to it. De-serialization of objects that have had data appended may result in
data corruption.

<a id="table-couchbase-sdk_net_append"></a>

**API Call**     | `object.Append(key, value)`           
-----------------|---------------------------------------
**Asynchronous** | no                                    
**Description**  | Append a value to an existing key     
**Returns**      | `Object` ( Binary object )            
**Arguments**    |                                       
**string key**   | Document ID used to identify the value
**object value** | Value to be stored                    

The `Append()` method appends information to the end of an existing key/value
pair.

The sample below demonstrates how to create a csv string by appending new
values.


```
client.Store(StoreMode.Set, "beers", "Abbey Ale");
Func<string, byte[]> stringToBytes = (s) => Encoding.Default.GetBytes(s);
client.Append("beers", new ArraySegment<byte>(stringToBytes(",Three Philosophers")));
client.Append("beers", new ArraySegment<byte>(stringToBytes(",Witte")));
```

You can check if the Append operation succeeded by using the checking the return
value.


```
var result = client.Append("beers", new ArraySegment<byte>(stringToBytes(",Hennepin")));
if (result) {
    Console.WriteLine("Append succeeded");
} else {
    Console.WriteLine("Append failed");
}
```

<a id="table-couchbase-sdk_net_append-cas"></a>

**API Call**        | `object.Append(key, casunique, value)`             
--------------------|----------------------------------------------------
**Asynchronous**    | no                                                 
**Description**     | Append a value to an existing key                  
**Returns**         | `Object` ( Binary object )                         
**Arguments**       |                                                    
**string key**      | Document ID used to identify the value             
**ulong casunique** | Unique value used to verify a key/value combination
**object value**    | Value to be stored                                 

`Append()` may also be used with a CAS value. With this overload, the return
value is a `CasResult`, where success is determined by examining the CasResult's
Result property.


```
var casv = client.GetWithCas("beers");
var casResult = client.Append("beers", casv.Cas, new ArraySegment<byte>(stringToBytes(",Adoration")));

if (casResult.Result) {
    Console.WriteLine("Append succeeded");
} else {
    Console.WriteLine("Append failed");
}
```

<a id="couchbase-sdk-net-update-decrement"></a>

## Decrement Methods

The `Decrement()` methods reduce the value of a given key if the corresponding
value can be parsed to an integer value. These operations are provided at a
protocol level to eliminate the need to get, update, and reset a simple integer
value in the database. All the.NET Client Library methods support the use of an
explicit offset value that will be used to reduce the stored value in the
database.

<a id="table-couchbase-sdk_net_decrement"></a>

**API Call**            | `object.Decrement(key, defaultvalue, offset)`                                                                                                             
------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                        
**Description**         | Decrement the value of an existing numeric key. The Couchbase Server stores numbers as unsigned values. Therefore the lowest you can decrement is to zero.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                 
**Arguments**           |                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                   

Decrement the inventory counter by 1, defaulting to 100 if the key doesn't
exist.


```
client.Decrement("inventory", 100, 1);
```

<a id="table-couchbase-sdk_net_decrement-validfor"></a>

**API Call**            | `object.Decrement(key, defaultvalue, offset, validfor)`                                                                                                   
------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                        
**Description**         | Decrement the value of an existing numeric key. The Couchbase Server stores numbers as unsigned values. Therefore the lowest you can decrement is to zero.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                 
**Arguments**           |                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                   
**TimeSpan validfor**   | Expiry time (in seconds) for key                                                                                                                          

Decrement the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 60 seconds.


```
client.Decrement("inventory", 100, 1, TimeSpan.FromSeconds(60));
```

<a id="table-couchbase-sdk_net_decrement-expiresat"></a>

**API Call**            | `object.Decrement(key, defaultvalue, offset, expiresat)`                                                                                                  
------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                        
**Description**         | Decrement the value of an existing numeric key. The Couchbase Server stores numbers as unsigned values. Therefore the lowest you can decrement is to zero.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                 
**Arguments**           |                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                   
**DateTime expiresat**  | Explicit expiry time for key                                                                                                                              

Decrement the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 5 minutes.


```
client.Decrement("inventory", 100, 1, DateTime.Now.AddMinutes(5));
```

<a id="table-couchbase-sdk_net_decrement-cas"></a>

**API Call**            | `object.Decrement(key, defaultvalue, offset, casunique)`                                                                                                  
------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                        
**Description**         | Decrement the value of an existing numeric key. The Couchbase Server stores numbers as unsigned values. Therefore the lowest you can decrement is to zero.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                 
**Arguments**           |                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                   
**ulong casunique**     | Unique value used to verify a key/value combination                                                                                                       

Decrement the inventory counter by 1, defaulting to 100 if the key doesn't
exist.


```
var casv = client.GetWithCas("inventory");
client.Decrement("inventory", 100, 1, cas.Cas);
```

<a id="table-couchbase-sdk_net_decrement-cas-validfor"></a>

**API Call**            | `object.Decrement(key, defaultvalue, offset, validfor, casunique)`                                                                                        
------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                        
**Description**         | Decrement the value of an existing numeric key. The Couchbase Server stores numbers as unsigned values. Therefore the lowest you can decrement is to zero.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                 
**Arguments**           |                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                   
**TimeSpan validfor**   | Expiry time (in seconds) for key                                                                                                                          
**ulong casunique**     | Unique value used to verify a key/value combination                                                                                                       

Decrement the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 60 seconds.


```
var casv = client.GetWithCas("inventory");
client.Decrement("inventory", 100, 1, TimeSpan.FromSeconds(60), cas.Cas);
```

<a id="table-couchbase-sdk_net_decrement-cas-expiresat"></a>

**API Call**            | `object.Decrement(key, defaultvalue, offset, expiresat, casunique)`                                                                                       
------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                        
**Description**         | Decrement the value of an existing numeric key. The Couchbase Server stores numbers as unsigned values. Therefore the lowest you can decrement is to zero.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                 
**Arguments**           |                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                   
**DateTime expiresat**  | Explicit expiry time for key                                                                                                                              
**ulong casunique**     | Unique value used to verify a key/value combination                                                                                                       

Decrement the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 5 minutes.


```
var casv = client.GetWithCas("inventory");
client.Decrement("inventory", 100, 1, DateTime.Now.AddMinutes(5), cas.Cas);
```

<a id="couchbase-sdk-net-update-remove"></a>

## Remove Methods

<a id="table-couchbase-sdk_net_remove"></a>

**API Call**     | `object.Remove(key)`                  
-----------------|---------------------------------------
**Asynchronous** | no                                    
**Description**  | Delete a key/value                    
**Returns**      | `Object` ; supported values:          
                 | `COUCHBASE_ETMPFAIL`                  
                 | `COUCHBASE_KEY_ENOENT`                
                 | `COUCHBASE_NOT_MY_VBUCKET`            
                 | `COUCHBASE_NOT_STORED`                
                 | `docid`                               
**Arguments**    |                                       
**string key**   | Document ID used to identify the value

The `Remove()` method deletes an item in the database with the specified key.

Remove the item with a specified key


```
client.Remove("badkey");
```

<a id="couchbase-sdk-net-update-increment"></a>

## Increment Methods

The `Increment()` methods increase the value of a given key if the corresponding
value can be parsed to an integer value. These operations are provided at a
protocol level to eliminate the need to get, update, and reset a simple integer
value in the database. All the.NET Client Library methods support the use of an
explicit offset value that will be used to reduce the stored value in the
database.

<a id="table-couchbase-sdk_net_increment"></a>

**API Call**            | `object.Increment(key, defaultvalue, offset)`                                                                                                                                                                                                                                                                                             
------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                                                                                                                                                                                                        
**Description**         | Increment the value of an existing numeric key. Couchbase Server stores numbers as unsigned numbers, therefore if you try to increment an existing negative number, it will cause an integer overflow and return a non-logical numeric result. If a key does not exist, this method will initialize it with the zero or a specified value.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                                                                                                                                                                                                 
**Arguments**           |                                                                                                                                                                                                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                                                                                                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                                                                                                                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                                                                                                                                                                                                   

Increment the inventory counter by 1, defaulting to 100 if the key doesn't
exist.


```
client.Increment("inventory", 100, 1);
```

<a id="table-couchbase-sdk_net_increment-validfor"></a>

**API Call**            | `object.Increment(key, defaultvalue, offset, validfor)`                                                                                                                                                                                                                                                                                   
------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                                                                                                                                                                                                        
**Description**         | Increment the value of an existing numeric key. Couchbase Server stores numbers as unsigned numbers, therefore if you try to increment an existing negative number, it will cause an integer overflow and return a non-logical numeric result. If a key does not exist, this method will initialize it with the zero or a specified value.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                                                                                                                                                                                                 
**Arguments**           |                                                                                                                                                                                                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                                                                                                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                                                                                                                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                                                                                                                                                                                                   
**TimeSpan validfor**   | Expiry time (in seconds) for key                                                                                                                                                                                                                                                                                                          

Increment the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 60 seconds.


```
client.Increment("inventory", 100, 1, TimeSpan.FromSeconds(60));
```

<a id="table-couchbase-sdk_net_increment-expiresat"></a>

**API Call**            | `object.Increment(key, defaultvalue, offset, expiresat)`                                                                                                                                                                                                                                                                                  
------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                                                                                                                                                                                                        
**Description**         | Increment the value of an existing numeric key. Couchbase Server stores numbers as unsigned numbers, therefore if you try to increment an existing negative number, it will cause an integer overflow and return a non-logical numeric result. If a key does not exist, this method will initialize it with the zero or a specified value.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                                                                                                                                                                                                 
**Arguments**           |                                                                                                                                                                                                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                                                                                                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                                                                                                                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                                                                                                                                                                                                   
**DateTime expiresat**  | Explicit expiry time for key                                                                                                                                                                                                                                                                                                              

Increment the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 5 minutes.


```
client.Increment("inventory", 100, 1, DateTime.Now.AddMinutes(5));
```

<a id="table-couchbase-sdk_net_increment-cas"></a>

**API Call**            | `object.Increment(key, defaultvalue, offset, casunique)`                                                                                                                                                                                                                                                                                  
------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                                                                                                                                                                                                        
**Description**         | Increment the value of an existing numeric key. Couchbase Server stores numbers as unsigned numbers, therefore if you try to increment an existing negative number, it will cause an integer overflow and return a non-logical numeric result. If a key does not exist, this method will initialize it with the zero or a specified value.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                                                                                                                                                                                                 
**Arguments**           |                                                                                                                                                                                                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                                                                                                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                                                                                                                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                                                                                                                                                                                                   
**ulong casunique**     | Unique value used to verify a key/value combination                                                                                                                                                                                                                                                                                       

Increment the inventory counter by 1, defaulting to 100 if the key doesn't
exist.


```
var casv = client.GetWithCas("inventory");
client.Increment("inventory", 100, 1, cas.Cas);
```

<a id="table-couchbase-sdk_net_increment-cas-validfor"></a>

**API Call**            | `object.Increment(key, defaultvalue, offset, validfor, casunique)`                                                                                                                                                                                                                                                                        
------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                                                                                                                                                                                                        
**Description**         | Increment the value of an existing numeric key. Couchbase Server stores numbers as unsigned numbers, therefore if you try to increment an existing negative number, it will cause an integer overflow and return a non-logical numeric result. If a key does not exist, this method will initialize it with the zero or a specified value.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                                                                                                                                                                                                 
**Arguments**           |                                                                                                                                                                                                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                                                                                                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                                                                                                                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                                                                                                                                                                                                   
**TimeSpan validfor**   | Expiry time (in seconds) for key                                                                                                                                                                                                                                                                                                          
**ulong casunique**     | Unique value used to verify a key/value combination                                                                                                                                                                                                                                                                                       

Increment the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 60 seconds.


```
var casv = client.GetWithCas("inventory");
client.Increment("inventory", 100, 1, TimeSpan.FromSeconds(60), cas.Cas);
```

<a id="table-couchbase-sdk_net_increment-cas-expiresat"></a>

**API Call**            | `object.Increment(key, defaultvalue, offset, expiresat, casunique)`                                                                                                                                                                                                                                                                       
------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**        | no                                                                                                                                                                                                                                                                                                                                        
**Description**         | Increment the value of an existing numeric key. Couchbase Server stores numbers as unsigned numbers, therefore if you try to increment an existing negative number, it will cause an integer overflow and return a non-logical numeric result. If a key does not exist, this method will initialize it with the zero or a specified value.
**Returns**             | `CasResult<ulong>` ( Cas result of bool )                                                                                                                                                                                                                                                                                                 
**Arguments**           |                                                                                                                                                                                                                                                                                                                                           
**string key**          | Document ID used to identify the value                                                                                                                                                                                                                                                                                                    
**object defaultvalue** | Value to be stored if key does not already exist                                                                                                                                                                                                                                                                                          
**Integer offset**      | Integer offset value to increment/decrement (default 1)                                                                                                                                                                                                                                                                                   
**DateTime expiresat**  | Explicit expiry time for key                                                                                                                                                                                                                                                                                                              
**ulong casunique**     | Unique value used to verify a key/value combination                                                                                                                                                                                                                                                                                       

Increment the inventory counter by 1, defaulting to 100 if the key doesn't exist
and set an expiry of 5 minutes.


```
var casv = client.GetWithCas("inventory");
client.Increment("inventory", 100, 1, DateTime.Now.AddMinutes(5), cas.Cas);
```

<a id="couchbase-sdk-net-update-prepend"></a>

## Prepend Methods

The `Prepend()` methods allow you to add information to an existing key/value
pair in the database. You can use this to add information to a string or other
data before the existing data.

The `Prepend()` methods prepend raw serialized data on to the end of the
existing data in the key. If you have previously stored a serialized object into
Couchbase and then use Prepend, the content of the serialized object will not be
extended. For example, adding an `List` of integers into the database, and then
using `Prepend()` to add another integer will result in the key referring to a
serialized version of the list, immediately preceded by a serialized version of
the integer. It will not contain an updated list with the new integer prepended
to it. De-serialization of objects that have had data prepended may result in
data corruption.

<a id="table-couchbase-sdk_net_prepend"></a>

**API Call**     | `object.Prepend(key, value)`          
-----------------|---------------------------------------
**Asynchronous** | no                                    
**Description**  | Prepend a value to an existing key    
**Returns**      | `Object` ( Binary object )            
**Arguments**    |                                       
**string key**   | Document ID used to identify the value
**object value** | Value to be stored                    

The `Prepend()` method prepends information to the end of an existing key/value
pair.

The sample below demonstrates how to create a csv string by prepending new
values.


```
client.Store(StoreMode.Set, "beers", "Abbey Ale");
Func<string, byte[]> stringToBytes = (s) => Encoding.Default.GetBytes(s);
client.Prepend("beers", new ArraySegment<byte>(stringToBytes("Three Philosophers,")));
client.Prepend("beers", new ArraySegment<byte>(stringToBytes("Witte,")));
```

You can check if the Prepend operation succeeded by using the checking the
return value.


```
var result = client.Prepend("beers", new ArraySegment<byte>(stringToBytes("Hennepin,")));
if (result) {
    Console.WriteLine("Prepend succeeded");
} else {
    Console.WriteLine("Prepend failed");
}
```

<a id="table-couchbase-sdk_net_prepend-cas"></a>

**API Call**        | `object.Prepend(key, casunique, value)`            
--------------------|----------------------------------------------------
**Asynchronous**    | no                                                 
**Description**     | Prepend a value to an existing key                 
**Returns**         | `Object` ( Binary object )                         
**Arguments**       |                                                    
**string key**      | Document ID used to identify the value             
**ulong casunique** | Unique value used to verify a key/value combination
**object value**    | Value to be stored                                 

`Prepend()` may also be used with a CAS value. With this overload, the return
value is a `CasResult`, where success is determined by examining the CasResult's
Result property.


```
var casv = client.GetWithCas("beers");
var casResult = client.Prepend("beers", casv.Cas, new ArraySegment<byte>(stringToBytes("Adoration,")));

if (casResult.Result) {
    Console.WriteLine("Prepend succeeded");
} else {
    Console.WriteLine("Prepend failed");
}
```

<a id="couchbase-sdk-net-update-touch"></a>

## Touch Methods

The `Touch()` methods allow you to update the expiration time on a given key.
This can be useful for situations where you want to prevent an item from
expiring without resetting the associated value. For example, for a session
database you might want to keep the session alive in the database each time the
user accesses a web page without explicitly updating the session value, keeping
the user's session active and available.

<a id="table-couchbase-sdk_net_touch"></a>

**API Call**      | `object.Touch(key, expiry)`                                                                                                 
------------------|-----------------------------------------------------------------------------------------------------------------------------
**Asynchronous**  | no                                                                                                                          
**Description**   | Update the expiry time of an item                                                                                           
**Returns**       | `Boolean` ( Boolean (true/false) )                                                                                          
**Arguments**     |                                                                                                                             
**string key**    | Document ID used to identify the value                                                                                      
**object expiry** | Expiry time for key. Values larger than 30\*24\*60\*60 seconds (30 days) are interpreted as absolute times (from the epoch).

The `Touch` method provides a simple key/expiry call to update the expiry time
on a given key. For example, to update the expiry time on a session for another
60 seconds:


```
client.Touch("session", TimeSpan.FromSeconds(60));
```

To update the expiry time on the session for another day:


```
client.Touch("session", DateTime.Now.AddDays(1));
```

<a id="couchbase-sdk-net-update-sync"></a>

## Sync Methods



<a id="table-couchbase-sdk_net_sync"></a>

**API Call**         | `object.Sync(mode, keyn, replicationcount)`          
---------------------|------------------------------------------------------
**Asynchronous**     | no                                                   
**Description**      | Sync one or more key/value pairs on a Membase cluster
**Returns**          | (none)                                               
**Arguments**        |                                                      
**mode**             |                                                      
**keyn**             | One or more keys used to reference a value           
**replicationcount** |                                                      

Sync operations

<a id="couchbase-sdk-net-rn"></a>
