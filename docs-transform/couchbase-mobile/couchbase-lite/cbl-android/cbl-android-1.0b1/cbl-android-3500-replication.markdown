## Working With Replication

This section describes how to work with replication in an Android app. To learn more about replication, see [Replication](/couchbase-lite/cbl-concepts/#replication) in the *Couchbase Lite Concepts Guide*.

### Creating a Replication

**To create a replication:**

1.  Add the following static initializer block to the Application's main activity:

	```java
  {
      CBURLStreamHandlerFactory.registerSelfIgnoreError();
  }
```

2.  Add the following code to the `onCreate()` method of the Application's main activity:

	      // start Couchbase Lite
	      CBLServer server = null;
	      String filesDir = getFilesDir().getAbsolutePath();
	      try {
	        server = new CBLServer(filesDir);
	      } catch (IOException e) {
	        Log.e(TAG, "Error starting CBLServer", e);
	      }
	
	      // start Ektorp adapter
	      HttpClient httpClient = new CBLiteDBHttpClient(server);
	      CouchDbInstance dbInstance = new StdCouchDbInstance(httpClient);

	      // create a local database
	      CouchDbConnector dbConnector = dbInstance.createConnector("testdb", true);
	
	      // pull this database to the test replication server
	      ReplicationCommand pullCommand = new ReplicationCommand.Builder()
	          .source("https://sync.example.com/example_db")
	          .target("testdb")
	          .continuous(true)
	          .build();
	
	      ReplicationStatus status = dbInstance.replicate(pullCommand);



### Creating a Replication Without Credentials in the URL

You can perform authenticated replications *without* having to expose the credentials in the URL. To create the replication without credentials in the URL:

1. Implement your own `HttpClientFactory` class that knows how to build `HttpClient` instances that can authenticate themselves.

2.  Register your `HttpClientFactory` instance with `CBLServer` as the default client.

3.  Start a replication and do not include the credentials in the URL.



Here's an example:

	// start Couchbase Lite
	String filesDir = getContext().getFilesDir().getAbsolutePath();
	CBLServer cblserver = new CBLServer(filesDir);
	
	// register our own custom HttpClientFactory
	cblserver.setDefaultHttpClientFactory(new HttpClientFactory() {

	@Override
	public org.apache.http.client.HttpClient getHttpClient() {

		// start with a default http client
		DefaultHttpClient httpClient = new DefaultHttpClient();

		// create a credentials provider to store our credentials
		BasicCredentialsProvider credsProvider = new BasicCredentialsProvider();

		// store our credentials (make sure the URL is not prefixed by https:// if using SSL)
		AuthScope myScope = new AuthScope("sync.example.com", 5984);
		Credentials myCredentials = new UsernamePasswordCredentials("mschoch", "notMyPassword");
		credsProvider.setCredentials(myScope, myCredentials);

		// set the credentials provider
		httpClient.setCredentialsProvider(credsProvider);

		// add an interceptor to sent the credentials preemptively
		HttpRequestInterceptor preemptiveAuth = new HttpRequestInterceptor() {

			@Override
			public void process(HttpRequest request,
					HttpContext context) throws HttpException,
					IOException {
				AuthState authState = (AuthState) context.getAttribute(ClientContext.TARGET_AUTH_STATE);
				CredentialsProvider credsProvider = (CredentialsProvider) context.getAttribute(
						ClientContext.CREDS_PROVIDER);
				HttpHost targetHost = (HttpHost) context.getAttribute(ExecutionContext.HTTP_TARGET_HOST);

				if (authState.getAuthScheme() == null) {
					AuthScope authScope = new AuthScope(targetHost.getHostName(), targetHost.getPort());
					Credentials creds = credsProvider.getCredentials(authScope);
					authState.setCredentials(creds);
					authState.setAuthScheme(new BasicScheme());
				}
			}
		};

		httpClient.addRequestInterceptor(preemptiveAuth, 0);

		return httpClient;
	}
	});
	
	// start Ektorp adapter
	HttpClient httpClient = new CBLiteHttpClient(cblserver);
	CouchDbInstance server = new StdCouchDbInstance(httpClient);
	
	// create a local database
	CouchDbConnector db = server.createConnector("testdb", true);
	
	// push this database to the test replication server
	ReplicationCommand pushCommand = new ReplicationCommand.Builder()
	.source("https://sync.example.com/ektorp_replication_test")
	.target("testdb")
	.continuous(false)
	.build();
	
	ReplicationStatus status = server.replicate(pushCommand);
	
	// ...



### Using Filtered Replication

The following example shows how you can define a filter function, and then use the filter function when performing a push replication.

 This filter function only return strue for documents with an even value for the field "foo".


	        String filesDir = getContext().getFilesDir().getAbsolutePath();
	        CBLServer tdserver = new CBLServer(filesDir);
	
	        // install the filter
	        CBLDatabase database = tdserver.getDatabaseNamed("ektorp_filter_test");
	        database.defineFilter("evenFoo", new CBLFilterBlock() {
	
	            @Override
	            public boolean filter(CBLRevision revision) {
	                Integer foo = (Integer)revision.getProperties().get("foo");
	                if(foo != null && foo.intValue() % 2 == 0) {
	                    return true;
	                }
	                return false;
	            }
	        });
	
	        HttpClient httpClient = new CBLiteHttpClient(tdserver);
	        CouchDbInstance server = new StdCouchDbInstance(httpClient);
	
	        // create a local database
	        CouchDbConnector db = server.createConnector("ektorp_filter_test", true);
	
	        // create 3 objects
	        TestObject test1 = new TestObject(1, false, "ektorp-1");
	        TestObject test2 = new TestObject(2, false, "ektorp-2");
	        TestObject test3 = new TestObject(3, false, "ektorp-3");
	
	        // save these objects in the database
	        db.create(test1);
	        db.create(test2);
	        db.create(test3);
	
	        // push this database to the test replication server
	        ReplicationCommand pushCommand = new ReplicationCommand.Builder()
	            .source("ektorp_filter_test")
	            .target("http://@10.0.2.2:5984" + "/ektorp_filter_test")
	            .continuous(false)
	            .filter("evenFoo")
	            .build();
	
	        ReplicationStatus status = server.replicate(pushCommand);


Using this replication only one record will be replicated, the one where the "foo" value is 2.

