#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.linux-x64 ];
    then
      echo "Removing existing ReplicationServer.linux-x64 source directory"
      rm -rf ReplicationServer.linux-x64  || _die "Couldn't remove the existing ReplicationServer.linux-x64 source directory (source/ReplicationServer.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.linux-x64)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.linux-x64 || _die "Couldn't create the ReplicationServer.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.linux-x64 || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.linux-x64 || _die "Couldn't set the permissions on the source directory"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.linux-x64/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/*.jar $WD/ReplicationServer/source/ReplicationServer.linux-x64/lib || _die "Failed to copy pg jdbc drivers" 

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/linux-x64)"
    mkdir -p $WD/ReplicationServer/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_linux_x64() {

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ReplicationServer/source/ReplicationServer.linux-x64; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ReplicationServer/source/ReplicationServer.linux-x64; cp -R dist/* $PG_PATH_LINUX_X64/ReplicationServer/staging/linux-x64/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ReplicationServer/source/ReplicationServer.linux-x64; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant -f custom_build.xml encrypt-util" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ReplicationServer/source/ReplicationServer.linux-x64; cp -R dist/* $PG_PATH_LINUX_X64/ReplicationServer/staging/linux-x64/" || _die "Failed to copy the dist content to staging directory"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p ReplicationServer/staging/linux-x64/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p ReplicationServer/staging/linux-x64/instscripts/bin" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/bin/psql ReplicationServer/staging/linux-x64/instscripts/bin" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libpq.so* ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libcrypto.so* ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libssl.so* ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libreadline.so* ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to copy libreadline.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libtermcap.so* ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libxml2.so* ReplicationServer/staging/linux-x64/instscripts/lib" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp MigrationToolKit/staging/linux-x64/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/linux-x64/repserver/lib/repl-mtk" || _die "Failed to copy edb-migrationtoolkit.jar"
    cd $WD
    _replace "edb-repconsole.jar" "@@INSTALL_DIR@@/bin/edb-repconsole.jar" "$WD/ReplicationServer/staging/linux-x64/repconsole/bin/runRepConsole.sh" || _die "Failed to put the placehoder in runRepConsole.sh file"

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_linux_x64() {
 

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/ReplicationServer || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/ReplicationServer/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/ReplicationServer/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/ReplicationServer/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux-x64/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/ReplicationServer/createshortcuts.sh

    cp scripts/linux/createuser.sh staging/linux-x64/installer/ReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/linux-x64/createuser.sh)"
    chmod ugo+x staging/linux-x64/installer/ReplicationServer/createuser.sh

    cp staging/linux-x64/edb-repencrypter.jar staging/linux-x64/installer/ReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/linux-x64/edb-repencrypter.jar)"

    # Setup Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/startupcfg_publication.sh staging/linux-x64/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/linux-x64/startupcfg_publication.sh)"
    chmod ugo+x staging/linux-x64/scripts/startupcfg_publication.sh
    cp scripts/linux/startupcfg_subscription.sh staging/linux-x64/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/linux-x64/startupcfg_subscription.sh)"
    chmod ugo+x staging/linux-x64/scripts/startupcfg_subscription.sh

    # Setup the ReplicationServer xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchReplicationServer.desktop staging/linux-x64/scripts/xdg/pg-launchReplicationServer.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}

