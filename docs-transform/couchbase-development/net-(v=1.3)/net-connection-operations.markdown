## Connection Operations

<a id="table-couchbase-sdk_net_connect"></a>

**API Call**        | `object.new CouchbaseClient([ url ] [, username ] [, password ])`                                                                                                                                                                                                  
--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
**Asynchronous**    | no                                                                                                                                                                                                                                                                 
**Description**     | Create a connection to Couchbase Server with given parameters, such as node URL. The connection obtains the cluster configuration from the first host to which it has connected. Further communication operates directly with each node in the cluster as required.
**Returns**         | (none)                                                                                                                                                                                                                                                             
**Arguments**       |                                                                                                                                                                                                                                                                    
**string url**      | URL for Couchbase Server Instance, or node.                                                                                                                                                                                                                        
**string username** | Username for Couchbase bucket.                                                                                                                                                                                                                                     
**string password** | Password for Couchbase bucket.                                                                                                                                                                                                                                     

The easiest way to specify a connection, or a pool of connections is to provide
it in the `App.config` file of your.Net project. By doing so, you can change the
connection information without having to recompile. You can update `App.config`
in Visual Studio as follows:


```
<servers bucket="private" bucketPassword="private">
      <add uri="http://10.0.0.33:8091/pools"/>
      <add uri="http://10.0.0.34:8091/pools"/>
</servers>
```

You should change the URI above to point at your server by replacing 10.0.0.33
with the IP address or hostname of your Couchbase server machine. Be sure you
set your bucket name and password. You can also set the connection to use the
default bucket, by setting the bucket attribute to `default` and leaving the
`bucketPassword` attribute empty. In this case we have configured the server
with a bucket named 'private' and with a password 'private.'

Connections that you create with the.Net SDK are also thread-safe objects; for
persisted connections, you can use a connection pool which contains multiple
connection objects. You should create only a single static instance of a
Couchbase client per bucket, in accordance with.Net framework. The persistent
client will maintain connection pools per server node. For more information, see
<a href=http://msdn.microsoft.com/en-us/library/system.appdomain(v=vs.71).aspx>MSDN: AppDomain
Class</a>.

<a id="api-reference-set"></a>
