#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ApachePhp_linux() {
      
    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source

    if [ -e apache.linux ];
    then
      echo "Removing existing apache.linux source directory"
      rm -rf apache.linux  || _die "Couldn't remove the existing apache.linux source directory (source/apache.linux)"
    fi

    echo "Creating apache source directory ($WD/ApachePhp/source/apache.linux)"
    mkdir -p apache.linux || _die "Couldn't create the apache.linux directory"
    chmod ugo+w apache.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -R httpd-$PG_VERSION_APACHE/* apache.linux || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    chmod -R ugo+w apache.linux || _die "Couldn't set the permissions on the source directory"

    if [ -e php.linux ];
    then
      echo "Removing existing php.linux source directory"
      rm -rf php.linux  || _die "Couldn't remove the existing php.linux source directory (source/php.linux)"
    fi
    
    echo "Creating php source directory ($WD/ApachePhp/source/php.linux)"
    mkdir -p php.linux || _die "Couldn't create the php.linux directory"
    chmod ugo+w php.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the php source tree
    cp -R php-$PG_VERSION_PHP/* php.linux || _die "Failed to copy the source code (source/php-$PG_VERSION_PHP)"
    chmod -R ugo+w php.linux || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApachePhp/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApachePhp/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApachePhp/staging/linux)"
    mkdir -p $WD/ApachePhp/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ApachePhp/staging/linux || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_ApachePhp_linux() {

    # build apache

    PG_STAGING=$PG_PATH_LINUX/ApachePhp/staging/linux

    # Configure the source tree
    echo "Configuring the apache source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux/; sh ./configure --prefix=$PG_STAGING/apache --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache"  || _die "Failed to configure apache"

    echo "Building apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux; make" || _die "Failed to build apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux; make install" || _die "Failed to install apache"

    #Configure the httpd.conf file
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "$WD/ApachePhp/staging/linux/apache/conf/httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "$WD/ApachePhp/staging/linux/apache/conf/httpd.conf"
    _replace "htdocs" "www" "$WD/ApachePhp/staging/linux/apache/conf/httpd.conf"
    _replace "#ServerName www.example.com:80" "ServerName localhost:@@PORT@@" "$WD/ApachePhp/staging/linux/apache/conf/httpd.conf"

    #Configure the apachectl script file
    _replace "\$HTTPD -k \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -k \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$WD/ApachePhp/staging/linux/apache/bin/apachectl"
    _replace "\$HTTPD -t" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$WD/ApachePhp/staging/linux/apache/bin/apachectl"
    _replace "\$HTTPD \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$WD/ApachePhp/staging/linux/apache/bin/apachectl"
    ssh $PG_SSH_LINUX "chmod ugo+x \"$PG_STAGING/apache/bin/apachectl\"" 
    
    echo "Configuring the php source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux/; sh ./configure --prefix=$PG_STAGING/php --with-apxs2=$PG_STAGING/apache/bin/apxs --with-config-file-path=$PG_STAGING/php --with-pgsql=$PG_PGHOME_LINUX" || _die "Failed to configure php"

    echo "Building php"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux; make" || _die "Failed to build php"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux; make install" || _die "Failed to install php"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux; cp php.ini-recommended $PG_STAGING/php/php.ini" || _die "Failed to copy php.ini file"

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypt.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcom_err.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libexpat.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libgssapi_krb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libkrb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libk5crypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxml2.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libpq.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library"


    cd $WD
    
}



################################################################################
# PG Build
################################################################################

_postprocess_ApachePhp_linux() {

    PG_STAGING=$PG_PATH_LINUX/ApachePhp/staging/linux
    
    #Configure the files in apache and php
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApachePhp/staging/linux" | grep -v Binary`

    cd $WD/ApachePhp/staging/linux

    for file in $filelist
    do
    _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
    chmod ugo+x "$file"
    done  

    cd $WD/ApachePhp

    # Setup the installer scripts. 

    #Changing the ServerRoot from htdocs to www in apache
    cp -R staging/linux/apache/htdocs staging/linux/apache/www || _die "Failed to change Server Root"
    chmod ugo+wx staging/linux/apache/www

    mkdir -p staging/linux/installer/ApachePhp || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/linux/apache/www/images || _die "Failed to create a directory for the images"
    chmod ugo+wx staging/linux/apache/www/images

    cp scripts/linux/createshortcuts.sh staging/linux/installer/ApachePhp/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/ApachePhp/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/removeshortcuts.sh

    cp scripts/linux/configureApachePhp.sh staging/linux/installer/ApachePhp/configureApachePhp.sh || _die "Failed to copy the configureApachePhp script (scripts/linux/configureApachePhp.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/configureApachePhp.sh

    cp scripts/linux/startupcfg.sh staging/linux/installer/ApachePhp/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/startupcfg.sh
   
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/linux/launchApachePhp.sh staging/linux/scripts/launchApachePhp.sh || _die "Failed to copy the launchApachePhp script (scripts/linux/launchApachePhp.sh)"
    chmod ugo+x staging/linux/scripts/launchApachePhp.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    cp scripts/linux/ctlApache.sh staging/linux/scripts/ctlApache.sh || _die "Failed to copy the ctlApache script (scripts/linux/ctlApache.sh)"
    chmod ugo+x staging/linux/scripts/ctlApache.sh

    cp scripts/linux/runApache.sh staging/linux/scripts/runApache.sh || _die "Failed to copy the runApache script (scripts/linux/runApache.sh)"
    chmod ugo+x staging/linux/scripts/runApache.sh

    chmod ugo+x staging/linux/php/php.ini

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-apachephp.directory staging/linux/scripts/xdg/enterprisedb-apachephp.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-launchApachePhp.desktop staging/linux/scripts/xdg/enterprisedb-launchApachePhp.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/enterprisedb-startApache.desktop staging/linux/scripts/xdg/enterprisedb-startApache.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/enterprisedb-stopApache.desktop staging/linux/scripts/xdg/enterprisedb-stopApache.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/enterprisedb-restartApache.desktop staging/linux/scripts/xdg/enterprisedb-restartApache.desktop || _die "Failed to copy a menu pick desktop"

    cp resources/index.php staging/linux/apache/www || _die "Failed to copy index.php"
    chmod ugo+x staging/linux/apache/www/index.php

    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/linux/apache/www/index.php" 
    _replace PG_VERSION_PHP $PG_VERSION_PHP "staging/linux/apache/www/index.php" 

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
}

