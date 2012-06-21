#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Drupal_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal/source
    
    if [ -e Drupal.linux ];
    then
      echo "Removing existing Drupal.linux source directory"
      rm -rf Drupal.linux  || _die "Couldn't remove the existing Drupal.linux source directory (source/Drupal.linux)"
    fi

    echo "Creating staging directory ($WD/Drupal/source/Drupal.linux)"
    mkdir -p $WD/Drupal/source/Drupal.linux || _die "Couldn't create the Drupal.linux directory"
    
    # Grab a copy of the source tree
    cp -pR drupal-$PG_VERSION_DRUPAL/* Drupal.linux || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL)"
    chmod -R ugo+w Drupal.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal/staging/linux)"
    mkdir -p $WD/Drupal/staging/linux/Drupal7 || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Drupal_linux() {

    cd $WD
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p Drupal/staging/linux/instscripts" || _die "Failed to create instscripts directory"

    cd $WD/Drupal/staging/linux/instscripts

    cp -pR $WD/server/staging/linux/bin/psql* . || _die "Failed to copy psql binary"
    cp -pR $WD/server/staging/linux/lib/libpq.so* . || _die "Failed to copy libpq.so"
    cp -pR $WD/server/staging/linux/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $WD/server/staging/linux/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp -pR $WD/server/staging/linux/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp -pR $WD/server/staging/linux/lib/libldap*.so* . || _die "Failed to copy libldap.so"
    cp -pR $WD/server/staging/linux/lib/liblber*.so* . || _die "Failed to copy liblber.so"
    cp -pR $WD/server/staging/linux/lib/libgssapi_krb5*.so* . || _die "Failed to copy libgssapi_krb5.so"
    cp -pR $WD/server/staging/linux/lib/libkrb5.so* . || _die "Failed to copy libkrb5.so"
    cp -pR $WD/server/staging/linux/lib/libkrb5support*.so* . || _die "Failed to copy libkrb5support.so"
    cp -pR $WD/server/staging/linux/lib/libk5crypto*.so* . || _die "Failed to copy libk5crypto.so"
    cp -pR $WD/server/staging/linux/lib/libcom_err*.so* . || _die "Failed to copy libcom_err.so"
    cp -pR $WD/server/staging/linux/lib/libncurses*.so* . || _die "Failed to copy libncurses.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal_linux() {


    cp -pR $WD/Drupal/source/Drupal.linux/* $WD/Drupal/staging/linux/Drupal7 || _die "Failed to copy the Drupal Source into the staging directory"

    cd $WD/Drupal

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/Drupal || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/createshortcuts.sh staging/linux/installer/Drupal/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/Drupal/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/Drupal/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/Drupal/removeshortcuts.sh

    # Setup the Drupal launch Files
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the Drupal Launch Files"
    cp scripts/linux/launchDrupal.sh staging/linux/scripts/launchDrupal.sh || _die "Failed to copy the launchDrupal.sh  script (scripts/linux/launchDrupal.sh)"
    chmod ugo+x staging/linux/scripts/launchDrupal.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

     # Setup the Drupal xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the Drupal xdg Files"
    cp resources/xdg/pg-launchDrupal.desktop staging/linux/scripts/xdg/pg-launchDrupal.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchDrupal.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchDrupal.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/pg-postgresql.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
    
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -pR $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"

    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal/staging/linux/Drupal7/install.php"

    chmod ugo+w staging/linux/Drupal7/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/linux/Drupal7/sites/default/default.settings.php staging/linux/Drupal7/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/linux/Drupal7/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/linux/Drupal7/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/linux/Drupal7/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}

