# Server Resources

Server resources enable you to interact with a server that hosts Couchbase Lite databases. 

The following table lists the server resources:.

|HTTP Method | URI pattern | Description  |
| ------	| ------	| ------	|  
| `GET` | `/`|Retrieves meta-information about the server  
| `GET` | `/_active_tasks`|Retrieves a list of tasks running on the server  
| `GET` | `/_all_dbs`|Retrieves a list of all databases on the server  
| `POST` | `_replicate` | Starts or cancels a replication operation  
|`GET` | `_session` | Returns a generic response for compatibility purposes
| `GET` | `/_uuids`|Retrieves a list of identifiers of the databases on the server  


## GET /

This request returns meta-information about the server.

###Request

**Request headers**

This request does not have any required headers.

**Query parameters**

This request does not use query parameters.

**Message body**

This request does not use a message body.
### Response

**Status codes**

**Response headers**

This response uses only standard HTTP headers.

**Message body**

The response message body contains a JSON document with the following objects:

|Name | Type | Description|  
| ------	| ------	|  
| `CouchbaseLite` | String | Contains the string "Welcome"  
| `couchdb` | String | Contains the string "Welcome"  
| `version` | String | Couchbase Lite version number  

### Example

The following example requests information about the server running at http://localhost:59840/.

**Request**

```
GET / HTTP/1.1
Host: localhost:59840
```

**Response**

```
HTTP/1.1 200 OK
Server: CouchbaseLite 1.485
Transfer-Encoding: chunked
Accept-Ranges: bytes
Content-Type: application/json
Cache-Control: must-revalidate
Date: Fri, 06 Dec 2013 19:21:48 GMT

{
  "couchdb" : "Welcome",
  "CouchbaseLite" : "Welcome",
  "version" : "1.485"
}
```
## GET /_active_tasks

This request retrieves a list of all tasks running on the server. 
### Request

**Request headers**

This request does not have any required headers.

**Query parameters**

This request does not use query parameters.

**Message body**

This request does not use a message body.
### Response

**Status codes**

**Response headers**

This response uses only standard HTTP headers.

**Message body**

The response message body contains a JSON document with an array of active tasks. If there are no active tasks, an empty array is returned in the response.

### Example

**Request**

```
GET /beer-db/_active_tasks HTTP/1.1
Host: localhost:59840
```


## GET _all_dbs

This request retrieves a list of all databases on the server.

### Request

**Request headers**

This request does not have any required headers.

**Query parameters**

This request does not use query parameters.

**Message body**

This request does not use a message body.

### Response

**Status codes**

**Response headers**

This response uses only standard HTTP headers.

**Message body**

The response message contains the following object:

| Name | Type | Description  
|  ------	| ------	| ------	|  
| not applicable | array | List of the names of the databases on the server |

### Example

The following example requests a list of databases on the server. The response lists the three databases on the server: `beer-db`, `cookbook`, and `genealogy`.

**Request**

```
GET /_all_dbs HTTP/1.1
Host: localhost:59840
```

**Response**

```
HTTP/1.1 200 OK
Server: CouchbaseLite 1.485
Transfer-Encoding: chunked
Accept-Ranges: bytes
Content-Type: application/json
Cache-Control: must-revalidate
Date: Mon, 09 Dec 2013 01:45:38 GMT

[
  "_replicator",
  "beer-db",
  "cookbook",
  "genealogy"
]
```


## POST _replicate

This request starts or cancels a replication operation.

### Request

**Request headers**

This request does not have any required headers.

**Query parameters**

This request does not use query parameters.

**Message body**

The request message body is a JSON document that contains the following objects:

|Name | Type | Description | Required|  
| ------	| ------	| ------	| ------	|  
|`create_target` | Boolean | Indicates whether to create the target database | No |  
|`source` | string | URI of the source database | Yes |  
|`target` | string | URI of the target database | Yes |  

### Response

**Status codes**

**Response headers**

This response uses only standard HTTP headers.

**Message body**

The response message body is a JSON document that contains the following objects.

| Name | Type | Description |  
|  ------	| ------	| ------	|  
| `ok` | Boolean | Indicates whether the replication operation was successful|  
| `session_id` | string | Session identifier |  


### Example

The following example replicates the database named `beer-db` located at `sync.couchbasecloud.com` to a database named `beer-db` on the local server.

**Request**

```
POST /_replicate HTTP/1.1
Host: localhost:59840

{
   "create_target" : true,
   "source" : "http://sync.couchbasecloud.com/beer-db/",
   "target" : "beer-db",
}
```

**Response**

```
Status Code: 200 OK
Accept-Ranges: bytes
Date: Fri, 06 Dec 2013 21:57:08 GMT
Server: CouchbaseLite 1.485
Transfer-Encoding: chunked

{
   "session_id":"repl001",
   "ok":true
}
```

## GET /_session
This request retrieves session information. Even though Couchbase Lite doesn't support user logins, it implements a generic response to the _session API for compatibility with apps, such as [Futon](http://docs.couchdb.org/en/latest/intro/futon.html), that might call it.
### Request

**Request headers**

This request does not have any required headers.

**Query parameters**

This request does not use query parameters.

**Message body**

This request does not use a message body.

### Response

**Status codes**

**Response headers**

This response uses only standard HTTP headers.

**Message body**

### Example

The following example shows request for session information.

**Request**

```
GET /_session
Host: localhost:59840
```

**Response**

```
HTTP/1.1 200 OK
Accept-Ranges: bytes
Cache-Control: must-revalidate
Content-Type: application/json
Date: Wed, 18 Dec 2013 21:34:56 GMT
Server: CouchbaseLite 1.486
Transfer-Encoding: chunked

{
  "userCtx" : {
    "name" : null,
    "roles" : [
      "_admin"
    ]
  },
  "ok" : true
}
```


## GET /_uuids

This request retrieves a list of the database identifiers.

### Request

**Request headers**

This request does not have any required headers.

**Query parameters**

This request does not use query parameters.

**Message body**

This request does not use a message body.


### Response

**Status codes**

**Response headers**

This response uses only standard HTTP headers.

**Message body**

The response message body is a JSON document that contains the following objects.

| Name | Type | Description  
|  ------	| ------	| ------	|  
| `uuids` | array | List of database identifiers  

### Example

The following example requests the UUIDs from the local server.

**Request**

```
GET /_uuids HTTP/1.1
Host: localhost:59840
```

**Response**

```
HTTP/1.1 200 OK
Server: CouchbaseLite 1.485
Content-Type: application/json
Accept-Ranges: bytes
Content-Length: 65
Cache-Control: must-revalidate
Date: Mon, 09 Dec 2013 03:20:40 GMT

{
  "uuids" : [
    "E29107F0-DF5F-4273-86C4-4FF2ED0229AD"
  ]
}
```
