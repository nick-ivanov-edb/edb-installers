#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=9.3rc1
PG_TARBALL_PGADMIN=1.18.0-rc1
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=1.0.1c
PG_TARBALL_ZLIB=1.2.7

# Build nums
PG_BUILDNUM_APACHEPHP=2
PG_BUILDNUM_PHPPGADMIN=2
PG_BUILDNUM_PGJDBC=1
PG_BUILDNUM_PSQLODBC=1
PG_BUILDNUM_POSTGIS=1
PG_BUILDNUM_SLONY=1
PG_BUILDNUM_NPGSQL=1
PG_BUILDNUM_PGAGENT=2
PG_BUILDNUM_PGMEMCACHE=1
PG_BUILDNUM_PGBOUNCER=1
PG_BUILDNUM_MIGRATIONTOOLKIT=5
PG_BUILDNUM_REPLICATIONSERVER=2
PG_BUILDNUM_PLPGSQLO=1
PG_BUILDNUM_SQLPROTECT=1
PG_BUILDNUM_UPDATE_MONITOR=2

# Tags for source checkout
PG_TAG_REPLICATIONSERVER=''
PG_TAG_MIGRATIONTOOLKIT='V46_0_STABLE'

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=9.3
PG_MINOR_VERSION=0.rc1

# Other package versions
PG_VERSION_APACHE=2.2.22
PG_VERSION_PHP=5.4.5
PG_VERSION_PHPPGADMIN=5.0.4
PG_VERSION_PGJDBC=9.2-1002
PG_VERSION_PSQLODBC=09.02.0100
PG_VERSION_POSTGIS=2.1.0
PG_VERSION_SLONY=2.2.0.rc1
PG_VERSION_NPGSQL=2.0.12
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
