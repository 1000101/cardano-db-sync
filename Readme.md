# Cardano DB Sync

## Purpose

The purpose of Cardano DB Sync is to follow the Cardano chain and take information from the chain
and an internally maintained copy of ledger state. Data is then extracted from the chain and
inserted into a PostgreSQL database. SQL queries can then be written directly against the database
schema or as queries embedded in any language with libraries for interacting with an SQL database.

Examples of what someone would be able to do via an SQL query against a Cardano DB Sync
instance fully synced fully synced to a specific network is:

* Look up any block, transaction, address, stake pool etc on that network, usually by the hash that
  identifies that item or the index into another table.
* Look up the balance of any stake address for any Shelley or later epoch.
* Look up the amount of ADA delegated to each pool for any Shelley or later epoch.

Example SQL queries are available at [Example Queries][ExampleQueries].

## Architecture

The cardano-db-sync component consists of a set of components:

* `cardano-db` which defines common data types and functions used by any application that needs
  to interact with the data base from Haskell. In particular, it defines the database schema.
* `cardano-db-sync` which acts as a Cardano node, following the chain and inserting
  data from the chain into a PostgreSQL database.
* `cardano-db-sync-extended` is a relatively simple extension to `cardano-db-sync` which maintains
  an extra table containing epoch data.

The two versions `cardano-db-sync` and `cardano-db-sync-extended` are fully compatible and use
identical database schema. The only difference is that the extended version maintains an `Epoch`
table. The non-extended version will still create this table but will not maintain it.

The db-sync node is written in a highly modular fashion to allow it to be as flexible as possible.

The `cardano-db-sync` node connects to a locally running `cardano-node` (ie one connected to other
nodes in the Cardano network over the internet with TCP/IP) using a Unix domain socket, retrieves
blocks, updates its internal ledger state and stores parts of each block in a local PostgreSQL
database. The database does not store things like cryptographic signatures but does store enough
information to follow the chain of blocks and look at the transactions within blocks.

The PostgreSQL database is designed to be accessed in a read-only fashion from other applications.
The database schema is highly normalised which helps prevent data inconsistencies (specifically
with the use of foreign keys from one table to another). More user friendly database queries can be
implemented using [Postgres Views][PostgresView] to implement joins between tables.

## System Requirements

The system requirements for `cardano-db-sync` (with both `db-sync` and the `node` running
on the same machine are:

* Any of the big well known Linux distributions (eg, Debian, Ubuntu, RHEL, CentOS, Arch
  etc).
* 8 Gigabytes of RAM.
* 2 CPU cores.
* 50 Gigabytes or more of disk storage.

## Troubleshooting

If you have any issues with this project, consult the [Troubleshooting][Troubleshooting] page for
possible solutions.

## Further Reading

* [BuildingRunning][BuildingRunning]: Building and running the db-sync node.
* [Docker][Docker]: Instruction for docker-compose, and building the images using nix.
* [Example SQL queries][ExampleQueries]: Some example SQL and Haskell/Esqueleto queries.
* [SchemaManagement][Schema Management]: How the database schema is managed and modified.
* [SQL DB Schema][DB Schema]: The current PostgreSQL DB schema, as generated by the code.
* [Validation][Validation]: Explanation of validation done by the db-sync node and assumptions made.

[BuildingRunning]: doc/building-running.md
[DB Schema]: https://hydra.iohk.io/job/Cardano/cardano-db-sync/native.haskellPackages.cardano-db.checks.test-db.x86_64-linux/latest/download/1
[Docker]: doc/docker.md
[ExampleQueries]: doc/interesting-queries.md
[PostgresView]: https://www.postgresql.org/docs/current/sql-createview.html
[Schema Management]: doc/schema-management.md
[Troubleshooting]: doc/troubleshooting.md
[Validation]: doc/validation.md
