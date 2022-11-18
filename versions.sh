#!/bin/sh

# Source tarball versions

PG_TARBALL_POSTGRESQL=10.23
PG_TARBALL_PGADMIN=6.15
PG_TARBALL_DEBUGGER=0.93
PG_TARBALL_PLJAVA=1.4.0
PG_TARBALL_OPENSSL=1.1.1s
PG_TARBALL_ZLIB=1.2.13
PG_TARBALL_GEOS=3.5.0
PG_LP_VERSION=1.1

# Build nums
PG_BUILDNUM_APACHEPHP=1
PG_BUILDNUM_PHPPGADMIN=1
PG_BUILDNUM_PGJDBC=1
PG_BUILDNUM_PSQLODBC=2
PG_BUILDNUM_POSTGIS=1
PG_BUILDNUM_SLONY=2
PG_BUILDNUM_NPGSQL=3
PG_BUILDNUM_PGAGENT=1
PG_BUILDNUM_PGMEMCACHE=3
PG_BUILDNUM_PGBOUNCER=2
PG_BUILDNUM_SQLPROTECT=1
PG_BUILDNUM_UPDATE_MONITOR=6
PG_BUILDNUM_LANGUAGEPACK=1
PG_BUILDNUM_APACHEHTTPD=1
PG_BUILDNUM_HDFS_FDW=1
PG_BUILDNUM_LANGUAGEPACK_PEM=$PG_BUILDNUM_LANGUAGEPACK #LP10
PG_BUILDNUM_PEMHTTPD=1

# Tags for source checkout
PG_TAG_MIGRATIONTOOLKIT=''

# PostgreSQL version. This is split into major version (8.4) and minor version (0.1).
#                     Minor version is revision.build.

PG_MAJOR_VERSION=10
PG_MINOR_VERSION=23.1

# Other package versions
PG_VERSION_APACHE=2.4.53
PG_VERSION_APACHE_APR=1.7.0
PG_VERSION_APACHE_APR_ICONV=1.2.2
PG_VERSION_APACHE_APR_UTIL=1.6.1
PG_VERSION_APACHE_EXPAT=2.4.8
PG_VERSION_WSGI=4.7.0
PG_VERSION_PHP=5.5.30
PG_VERSION_PHPPGADMIN=5.1
PG_VERSION_PGJDBC=42.2.23
PG_VERSION_PSQLODBC=13.00.0000
PG_VERSION_POSTGIS=2.4.10
PG_VERSION_POSTGIS_JAVA=2.1.7.2
PG_VERSION_SLONY=2.2.8
PG_VERSION_NPGSQL=3.2.6
PG_VERSION_PGAGENT=4.2.1
PG_VERSION_PGMEMCACHE=2.3.0
PG_VERSION_PGBOUNCER=1.17.0
PG_VERSION_MIGRATIONTOOLKIT=48.0.0
PG_VERSION_SQLPROTECT=$PG_TARBALL_POSTGRESQL
PG_VERSION_UPDATE_MONITOR=1.0
PG_VERSION_HDFS_FDW=1.0
PG_VERSION_LANGUAGEPACK_PEM=v$(echo ${PG_LP_VERSION} | cut -d'.' -f1)
PG_VERSION_PYTHON_PEM=3.7 #LP10
PG_VERSION_PGADMIN=$PG_TARBALL_PGADMIN
PG_VERSION_SB=4.1.0

PG_VERSION_PERL=5.26
PG_MINOR_VERSION_PERL=3
PG_VERSION_PYTHON=3.7
PG_MINOR_VERSION_PYTHON=15
#PG_VERSION_DIST_PYTHON=0.7.3
#PG_VERSION_DIST_PYTHON=0.6.49
PG_VERSION_TCL=8.6
PG_MINOR_VERSION_TCL=12
PG_VERSION_NCURSES=6.0
PG_VERSION_LANGUAGEPACK=$PG_LP_VERSION
PG_VERSION_PYTHON_SETUPTOOLS=39.2.0

# Miscellaneous options

# PostgreSQL jdbc jar version used by PostGIS
PG_JAR_POSTGRESQL=$PG_VERSION_PGJDBC.jdbc41
BASE_URL=http://sbp.enterprisedb.com
JRE_VERSIONS_LIST="$PG_MAJOR_VERSION;9.1;9.0"
