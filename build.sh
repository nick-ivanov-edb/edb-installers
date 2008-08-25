#!/bin/bash

# PostgreSQL Installer build system
# Dave Page, EnterpriseDB

# Common utilties
source ./common.sh

# Get the build settings
if [ ! -f ./settings.sh ];
then
  _die "The is no settings.sh file present. Please copy settings.sh.in and edit as required before rebuilding."
fi
source ./settings.sh

################################################################################
# Initialise the build system
################################################################################
_init() {

    # Grab the working directory
    WD=`pwd`
	
	# Set the package versions string
	PG_PACKAGE_VERSION=$PG_MAJOR_VERSION.`echo $PG_MINOR_VERSION | sed -e 's/\./-/'`
}

################################################################################
# Check a Unix VM is accessible and can reach the buildfarm directory
################################################################################
_check_unix_vm() {
    RETVAL=`ssh $1 ls $2/settings.sh 2>&1`
	if [ "$RETVAL" != "$2/settings.sh" ];
	then
	    _die "The build VM $1 is inaccessible or does not have access to the buildfarm repository at $2"
	fi
}

################################################################################
# Check a Windows VM is accessible and can reach the buildfarm directory
################################################################################
_check_windows_vm() {
    RETVAL=`ssh $1 ls $2 2>&1`
        RESULT=`echo "$RETVAL" | grep 'No such file or directory' | wc -l`
        if [ "$RESULT" -ne "0" ];
        then
            _die "The build VM $1 is inaccessible or does not have access to the buildfarm repository at $2"
        fi
}

################################################################################
# Rock 'n' roll
################################################################################
if [ $# -ge 1 ];
then
  if [ $1 = "-skipbuild" ];
  then 
    SKIPBUILD=1
  else
    SKIPBUILD=0
  fi
else
  SKIPBUILD=0
fi

# Check the VMs
if [ $PG_ARCH_LINUX = 1 ];
then
    _check_unix_vm $PG_SSH_LINUX $PG_PATH_LINUX
fi

if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    _check_unix_vm $PG_SSH_LINUX_X64 $PG_PATH_LINUX_X64
fi

if [ $PG_ARCH_WINDOWS = 1 ];
then
    _check_windows_vm $PG_SSH_WINDOWS $PG_PATH_WINDOWS
fi


# Initialise the build system
_init

################################################################################
# Build each package. This may have interdepencies so must be built in order
################################################################################

# Package: Server
if [ $PG_PACKAGE_SERVER == 1 ];
then
    source ./server/build.sh

    if [ $SKIPBUILD == 0 ]; 
    then
        _prep_server || exit 1
        _build_server || exit 1
    fi

    _postprocess_server || exit 1
fi

# Package: ApachePhp
if [ $PG_PACKAGE_APACHEPHP == 1 ];
then
    source ./ApachePhp/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_ApachePhp || exit 1
        _build_ApachePhp || exit 1
    fi

    _postprocess_ApachePhp || exit 1
fi

# Package: mediaWiki
if [ $PG_PACKAGE_MEDIAWIKI == 1 ];
then
    source ./mediaWiki/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_mediaWiki || exit 1
        _build_mediaWiki || exit 1
    fi

    _postprocess_mediaWiki || exit 1
fi

