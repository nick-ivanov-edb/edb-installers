#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=9.4beta2
PG_TARBALL_PGADMIN=1.20.0-beta1
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=1.0.1h
PG_TARBALL_ZLIB=1.2.7
PG_TARBALL_GEOS=3.3.8

# Build nums
PG_BUILDNUM_APACHEPHP=3
PG_BUILDNUM_PHPPGADMIN=1
PG_BUILDNUM_PGJDBC=1
PG_BUILDNUM_PSQLODBC=2
PG_BUILDNUM_POSTGIS=2
PG_BUILDNUM_SLONY=1
PG_BUILDNUM_NPGSQL=1
PG_BUILDNUM_PGAGENT=4
PG_BUILDNUM_PGMEMCACHE=2
PG_BUILDNUM_PGBOUNCER=2
PG_BUILDNUM_MIGRATIONTOOLKIT=5
PG_BUILDNUM_REPLICATIONSERVER=2
PG_BUILDNUM_PLPGSQLO=1
PG_BUILDNUM_SQLPROTECT=1
PG_BUILDNUM_UPDATE_MONITOR=3

# Tags for source checkout
PG_TAG_REPLICATIONSERVER=''
PG_TAG_MIGRATIONTOOLKIT='V46_0_STABLE'

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=9.4
PG_MINOR_VERSION=0.beta2

# Other package versions
PG_VERSION_APACHE=2.4.7
PG_VERSION_PHP=5.4.23
PG_VERSION_PHPPGADMIN=5.1
PG_VERSION_PGJDBC=9.3-1100
PG_VERSION_PSQLODBC=09.03.0210
PG_VERSION_POSTGIS=2.1.1
PG_VERSION_SLONY=2.2.2
PG_VERSION_NPGSQL=2.0.14.3
PG_VERSION_PGAGENT=3.3.0
PG_VERSION_PGMEMCACHE=2.0.6
PG_VERSION_PGBOUNCER=1.5.4
PG_VERSION_MIGRATIONTOOLKIT=1.0
PG_VERSION_REPLICATIONSERVER=5.0
PG_VERSION_PLPGSQLO=$PG_TARBALL_POSTGRESQL
PG_VERSION_SQLPROTECT=$PG_TARBALL_POSTGRESQL
PG_VERSION_UPDATE_MONITOR=1.0

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=9.2-1000.jdbc4
BASE_URL=http://sbp.enterprisedb.com
JRE_VERSIONS_LIST="$PG_MAJOR_VERSION;9.1;9.0"
