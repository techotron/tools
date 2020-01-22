# RDS

## Availability

- Multi-AZ RDS solutions are synchronous but read-only replicas are asynchronous.
- Updates during maintance periods will take place on secondary instance, then CNAME will change to "promote" secondary instance to new primary instance and update will then take place on the other instance.
- The following RDS types allow read-only replicas:
-- MySQL (Async)
-- MariaDB (Async)
-- PostgresDB (Async)
-- Oracle (Async)
-- Aurora (Virtualised SSD backed storage layer. Aurora replicas use same storage as the source instance.)
- The following RDS types allow cross region replication
-- MySQL (Async)
-- MariaDB (Async)
-- PostgreSQL (Async)
-- Oracle (Async)
- You can use a mixture of Multi-AZ (for synchronous replication) with read-replicas to benefit from both technologies for the following types:
-- MySQL
-- MariaDB
-- PostgreSQL
-- Oracle

### Aurora

- Compatible with MySQL or PostgreSQL engines
- 2 modes: single-master (read-write) and multi-master (write-write)
- Storage layer is a virtual volumes which is replicated across AZs.
- Maximum of 15 read replicas (plus 1 for the master)

#### Availability (Aurora)

- Global Database consists of primary AWS region where data is mastered and up to 5 read-only, secondary AWS regions.
- Replication latency to secondary regions is tpyically under a second.
- Write operations take place in one region only. 
- If primary region becomes unavailable you can promote one of the secondary regions to become primary. This process typically takes place in less than a minute
- Replication is handled on dedicated infrastructure (no impact on read/write workloads)
- Up to 16 replicas to any of the secondary clusters.
- You can only use `db.r4` or `db-r5` instance types.
- Not available in Stockholm, Hong kong, China, Bahrain and Sao Paulo regions
- Can't create a cross region read replica from the primary cluster in a region which is already part of a secondary cluster

#### Security (Aurora)

- Management actions can be controlled using IAM
- Can use TLS to connect to the endpoints.
- Can manage access with security groups also.
- Authentication and permissions you can use:
-- Same approach as a stand-alone instance of MySQL and PostgreSQL
-- IAM DB authentication. This uses an IAM user or role with an authentication token. The token is a unique value that is generated using Signature Version 4 signing process. Don't need a password with this method - tokens are granted on request and last 15 minutes.
- Can use encryption at rest

## Security

- Read replicas for MySQL, MariaDB and PostgreSQL use a secure communications channel using public key encryption between source and destination. 


## Backup Strategies

