#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=8.4.0
PG_TARBALL_PGADMIN=1.10.0
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=0.9.8i
PG_TARBALL_ZLIB=1.2.3
PG_TARBALL_GEOS=3.1.1
PG_TARBALL_PROJ=4.6.1
PG_TARBALL_LIBMEMCACHED=0.26
PG_TARBALL_LIBEVENT=1.4.9-stable

# Build nums
PG_BUILDNUM_APACHEPHP=2
PG_BUILDNUM_MEDIAWIKI=1
PG_BUILDNUM_PHPWIKI=1
PG_BUILDNUM_PHPBB=1
PG_BUILDNUM_DRUPAL=1
PG_BUILDNUM_PHPPGADMIN=1
PG_BUILDNUM_PGJDBC=1
PG_BUILDNUM_PSQLODBC=1
PG_BUILDNUM_POSTGIS=2
PG_BUILDNUM_SLONY=1
PG_BUILDNUM_TUNINGWIZARD=1
PG_BUILDNUM_MIGRATIONWIZARD=2
PG_BUILDNUM_PGPHONEHOME=1
PG_BUILDNUM_NPGSQL=1
PG_BUILDNUM_PGAGENT=1
PG_BUILDNUM_PGMEMCACHE=1
PG_BUILDNUM_PGBOUNCER=1


# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build. 

PG_MAJOR_VERSION=8.4
PG_MINOR_VERSION=0.1

# Other package versions
PG_VERSION_APACHE=2.2.11
PG_VERSION_PHP=5.2.9
PG_VERSION_MEDIAWIKI=1.15.0
PG_VERSION_PHPWIKI=1.2.11
PG_VERSION_PHPBB=3.0.5
PG_VERSION_DRUPAL=6.12
PG_VERSION_PHPPGADMIN=4.2.2
PG_VERSION_PGJDBC=8.4-701
PG_VERSION_PSQLODBC=08.04.0100
PG_VERSION_POSTGIS=1.3.6
PG_VERSION_SLONY=2.0.2
PG_VERSION_TUNINGWIZARD=1.3
PG_VERSION_MIGRATIONWIZARD=1.1
PG_VERSION_PGPHONEHOME=1.1
PG_VERSION_DEVSERVER=`date +%Y-%m-%d%n`
PG_VERSION_NPGSQL=2.0.5
PG_VERSION_PGAGENT=3.0.0
PG_VERSION_METAINSTALLER=$PG_MAJOR_VERSION
PG_VERSION_PGMEMCACHE=2.0RC1
PG_VERSION_PGBOUNCER=1.3.1
PG_VERSION_LIBPQ=$PG_MAJOR_VERSION

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=8.3-604.jdbc2

