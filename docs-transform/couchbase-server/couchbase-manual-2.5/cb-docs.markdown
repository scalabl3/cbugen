# Couchbase Server

This manual documents the Couchbase Server database system. For differences between individual version within this release series,
see the version-specific notes throughout the manual.

In addition to an introduction to Couchbase Server and a description of the relationship to NoSQL, 
this manual provides the following topics: 

* [Installation and Upgrade](cb-install/)

* [Administration](cb-admin/)  

* [CLI](cb-cli/)

* [REST API](cb-rest-api/)



## Couchbase Server introduction

Couchbase Server is a NoSQL document database for interactive web applications.
It has a flexible data model, is easily scalable, provides consistent high
performance and is 'always-on,' meaning it is can serve application data 24
hours, 7 days a week. Couchbase Server provides the following benefits:

 * **Flexible Data Model**

   With Couchbase Server, you use JSON documents to represent application objects
   and the relationships between objects. This document model is flexible enough so
   that you can change application objects without having to migrate the database
   schema, or plan for significant application downtime. Even the same type of
   object in your application can have a different data structures. For instance,
   you can initially represent a user name as a single document field. You can
   later structure a user document so that the first name and last name are
   separate fields in the JSON document without any downtime, and without having to
   update all user documents in the system.

   The other advantage in a flexible, document-based data model is that it is well
   suited to representing real-world items and how you want to represent them. JSON
   documents support nested structures, as well as field representing relationships
   between items which enable you to realistically represent objects in your
   application.

 * **Easy Scalability**

   It is easy to scale your application with Couchbase Server, both within a
   cluster of servers and between clusters at different data centers. You can add
   additional instances of Couchbase Server to address additional users and growth
   in application data without any interruptions or changes in your application
   code. With one click of a button, you can rapidly grow your cluster of Couchbase
   Servers to handle additional workload and keep data evenly distributed.

   Couchbase Server provides automatic sharding of data and rebalancing at runtime;
   this lets you resize your server cluster on demand. Cross-data center
   replication enables you to move data closer to
   your user at other data centers.

 * **Consistent High Performance**

   Couchbase Server is designed for massively concurrent data use and consistent
   high throughput. It provides consistent sub-millisecond response times which
   help ensure an enjoyable experience for users of your application. By providing
   consistent, high data throughput, Couchbase Server enables you to support more
   users with less servers. The server also automatically spreads workload across
   all servers to maintain consistent performance and reduce bottlenecks at any
   given server in a cluster.

 * **"Always Online"**

   Couchbase Server provides consistent sub-millisecond response times which help
   ensure an enjoyable experience for users of your application. By providing
   consistent, high data throughput, Couchbase Server enables you to support more
   users with less servers. The server also automatically spreads workload across
   all servers to maintain consistent performance and reduce bottlenecks at any
   given server in a cluster.

   Features such as cross-data center replication and auto-failover help ensure
   availability of data during server or datacenter failure.

All of these features of Couchbase Server enable development of web applications
where low–latency and high throughput are required by end users. Web
applications can quickly access the right information within a Couchbase cluster
and developers can rapidly scale up their web applications by adding servers.

<a id="couchbase-introduction-nosql"></a>

## Couchbase Server and NoSQL

NoSQL databases are characterized by their ability to store data without first
requiring one to define a database schema. In Couchbase Server, you can store
data as key-value pairs or JSON documents. Data does not need to confirm to a
rigid, pre-defined schema from the perspective of the database management
system. Due to this schema-less nature, Couchbase Server supports a *scale out*
approach to growth, increasing data and I/O capacity by adding more servers to a
cluster; and without any change to application software. In contrast, relational
database management systems *scale up* by adding more capacity including CPU,
memory and disk to accommodate growth.

Relational databases store information in relations which must be defined, or
modified, before data can be stored. A relation is simply a table of rows, where
each row in a given relation has a fixed set of columns. These columns are
consistent across each row in a relation. Tables can be further connected
through cross-table references. One table, could hold rows of all individual
citizens residing in a town. Another table, could have rows consisting of
parent, child and relationship fields. The first two fields could be references
to rows in the citizens table while the third field describes the parental
relationship between the persons in the first two fields such as father or
mother.





