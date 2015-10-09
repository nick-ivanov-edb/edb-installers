#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/Npgsql/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/Npgsql/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/Npgsql/build-linux-x64.sh
fi

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
    source $WD/Npgsql/build-linux-ppc64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/Npgsql/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql() {

    # Create the source directory if required
    if [ ! -e $WD/Npgsql/source ];
    then
        mkdir $WD/Npgsql/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	if [ -e Npgsql"$PG_VERSION_NPGSQL"-bin-ms.net2.0 ];
        then
	  echo "Removing existing Npgsql"${PG_VERSION_NPGSQL}".0-bin-ms.net2.0 source directory"
          rm -rf Npgsql"${PG_VERSION_NPGSQL}".0-bin-ms.net2.0  || _die "Couldn't remove the existing Npgsql"${PG_VERSION_NPGSQL}".0-bin-ms.net2 source directory (source/Npgsql"${PG_VERSION_Npgsql}.0-bin-ms.net")"
	fi
    
	echo "Unpacking Npgsql source..."
        extract_file ../../tarballs/Npgsql"${PG_VERSION_NPGSQL}"-bin-ms.net2.0 || exit 1
        extract_file ../../tarballs/Npgsql"${PG_VERSION_NPGSQL}"-bin-ms.net3.5sp1 || exit 1
        extract_file ../../tarballs/Npgsql"${PG_VERSION_NPGSQL}"-bin-ms.net4.0 || exit 1
        extract_file ../../tarballs/Npgsql"${PG_VERSION_NPGSQL}"-bin-ms.net4.5 || exit 1
    fi
    
    # non-Windows
    if [ -e Npgsql"$PG_VERSION_NPGSQL" ];
    then
        echo "Removing existing NpgSQL"$PG_VERSION_NPGSQL" (Mono2.0) source directory"
        rm -rf Npgsql"$PG_VERSION_NPGSQL"  || _die "Couldn't remove the existing Mono"$PG_VERSION_NPGSQL" source directory (source/Npgsql"$PG_VERSION_NPGSQL"/Mono"$PG_VERSION_NPGSQL")"
    fi

    echo "Unpacking Npgsql (Mono2.0) source..."
    extract_file ../../tarballs/Npgsql"$PG_VERSION_NPGSQL"-bin-mono2.0 || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_Npgsql_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Npgsql_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_Npgsql_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _prep_Npgsql_linux_ppc64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_Npgsql_windows || exit 1
    fi
    
}

################################################################################
# Build Npgsql
################################################################################

_build_Npgsql() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_Npgsql_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Npgsql_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_Npgsql_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
       _build_Npgsql_linux_ppc64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_Npgsql_windows || exit 1
    fi
}

################################################################################
# Postprocess Npgsql
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_Npgsql() {

    cd $WD/Npgsql

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (Npgsql/installer.xml.in)"
    
    _replace PG_VERSION_NPGSQL $PG_VERSION_NPGSQL installer.xml || _die "Failed to set the version in the installer project file (Npgsql/installer.xml)"
    _replace PG_BUILDNUM_NPGSQL $PG_BUILDNUM_NPGSQL installer.xml || _die "Failed to set the Build Number in the installer project file (Npgsql/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_Npgsql_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Npgsql_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_Npgsql_linux_x64 || exit 1
    fi
    
    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _postprocess_Npgsql_linux_ppc64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_Npgsql_windows || exit 1
    fi
}