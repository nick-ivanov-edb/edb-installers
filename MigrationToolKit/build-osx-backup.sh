#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_osx() {

    echo "BEGIN PREP MigrationToolKit OSX"
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationtoolkit.osx ];
    then
      echo "Removing existing migrationtoolkit.osx source directory"
      rm -rf migrationtoolkit.osx  || _die "Couldn't remove the existing migrationtoolkit.osx source directory (source/migrationtoolkit.osx)"
      rm -f migrationtoolkit.osx.tar.bz2
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.osx)"
    mkdir -p migrationtoolkit.osx || _die "Couldn't create the migrationtoolkit.osx directory"
    chmod ugo+w migrationtoolkit.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.osx || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.osx/lib/ || _die "Failed to copy the pg-jdbc driver"
    cp $WD/tarballs/edb-jdbc17.jar migrationtoolkit.osx/lib/ || _die "Failed to copy the edb-jdbc driver"

    tar -jcvf migrationtoolkit.osx.tar.bz2 migrationtoolkit.osx || _die "Failed to create the archive (source/migrationtoolkit.osx.tar.bz2)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/osx)"
    mkdir -p $WD/MigrationToolKit/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Cleaning the files in remote MigrationToolKit directory"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/MigrationToolKit/*" || _die "Falied to clean the MigrationToolKit directory on Mac OS X VM"

    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/MigrationToolKit/source" || _die "Failed to create the source dircetory on the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/MigrationToolKit/staging/osx" || _die "Failed to create the staging dircetory on the build VM"

    scp migrationtoolkit.osx.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/MigrationToolKit/source/ || _die "Failed to copy the source archives to build VM"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/MigrationToolKit/source; tar -jxvf migrationtoolkit.osx.tar.bz2"
 
    echo "END PREP MigrationToolKit OSX"
}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_osx() {

    echo "BEGIN BUILD MigrationToolKit OSX"

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_OSX/MigrationToolKit/staging/osx
    PG_MW_SOURCE=$PG_PATH_OSX/MigrationToolKit/source/migrationtoolkit.osx

    echo "Building migrationtoolkit"
    ssh $PG_SSH_OSX "cd $PG_MW_SOURCE; $PG_ANT_HOME_OSX/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_OSX "cd $PG_MW_SOURCE; $PG_ANT_HOME_OSX/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"

     # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_OSX "cd $PG_MW_SOURCE; mkdir $PG_STAGING/MigrationToolkit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/osx/MigrationToolkit)"
    ssh $PG_SSH_OSX "cd $PG_MW_SOURCE; cp -R install/* $PG_STAGING/MigrationToolkit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/osx/MigrationToolkit)"

    ssh $PG_SSH_OSX "cd $PG_STAGING; tar -jcvf mtk-staging.tar.bz2 *"
    scp $PG_SSH_OSX:$PG_PATH_OSX/MigrationToolKit/staging/osx/mtk-staging.tar.bz2 $WD/MigrationToolKit/staging/osx || _die "Failed to scp mtk staging"

    cd $WD/MigrationToolKit/staging/osx
    tar -jxvf mtk-staging.tar.bz2 || _die "Failed to extract the mtk staging archive"
    rm -f mtk-staging.tar.bz2

    echo "END BUILD MigrationToolKit OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_osx() {

    echo "BEGIN POST MigrationToolKit OSX"

    cd $WD/MigrationToolKit
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.zip migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    
    cd $WD
    
    echo "END POST MigrationToolKit OSX"
}
