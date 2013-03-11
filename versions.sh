#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=9.1.8
PG_TARBALL_PGADMIN=1.14.3
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=1.0.1a
PG_TARBALL_ZLIB=1.2.3
PG_TARBALL_GEOS=3.3.0
PG_TARBALL_PROJ=4.7.0
PG_TARBALL_LIBMEMCACHED=0.51
PG_TARBALL_LIBEVENT=2.0.13-stable

# Build nums
PG_BUILDNUM_APACHEPHP=2
PG_BUILDNUM_PHPPGADMIN=1
PG_BUILDNUM_PGJDBC=1
PG_BUILDNUM_PSQLODBC=1
PG_BUILDNUM_POSTGIS=1
PG_BUILDNUM_SLONY=1
PG_BUILDNUM_NPGSQL=1
PG_BUILDNUM_PGAGENT=1
PG_BUILDNUM_PGMEMCACHE=1
PG_BUILDNUM_PGBOUNCER=1
PG_BUILDNUM_MIGRATIONTOOLKIT=4
PG_BUILDNUM_REPLICATIONSERVER=5
PG_BUILDNUM_PLPGSQLO=1
PG_BUILDNUM_SQLPROTECT=1
PG_BUILDNUM_UPDATE_MONITOR=1

# Tags for source checkout
PG_TAG_REPLICATIONSERVER=''
PG_TAG_MIGRATIONTOOLKIT='EDBAS9_1_STABLE'

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=9.1
PG_MINOR_VERSION=8.1

# Other package versions
PG_VERSION_APACHE=2.2.22
PG_VERSION_PHP=5.3.10
PG_VERSION_PHPPGADMIN=5.0.4
PG_VERSION_PGJDBC=9.1-901
PG_VERSION_PSQLODBC=09.01.0100
PG_VERSION_POSTGIS=1.5.3
PG_VERSION_SLONY=2.0.7
PG_VERSION_NPGSQL=2.0.11.91
PG_VERSION_PGAGENT=3.2.1
PG_VERSION_PGMEMCACHE=2.0.6
PG_VERSION_PGBOUNCER=1.5
PG_VERSION_MIGRATIONTOOLKIT=1.0
PG_VERSION_REPLICATIONSERVER=2.56
PG_VERSION_PLPGSQLO=$PG_TARBALL_POSTGRESQL
PG_VERSION_SQLPROTECT=$PG_TARBALL_POSTGRESQL
PG_VERSION_UPDATE_MONITOR=1.0

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=9.1-901.jdbc3
BASE_URL=http://sbp.enterprisedb.com
