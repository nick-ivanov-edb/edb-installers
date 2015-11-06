#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_Slony_osx() {
    
    echo "BEGIN PREP Slony OSX"

    echo "*******************************************************"
    echo " Pre Process : Slony(OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e slony.osx ];
    then
      echo "Removing existing slony.osx source directory"
      rm -rf slony.osx  || _die "Couldn't remove the existing slony.osx source directory (source/slony.osx)"
    fi

    echo "Creating slony source directory ($WD/Slony/source/slony.osx)"
    mkdir -p slony.osx || _die "Couldn't create the slony.osx directory"
    chmod ugo+w slony.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* slony.osx || _die "Failed to copy the source code (source/slony1-$PG_VERSION_SLONY)"
    tar -jcvf slony.osx.tar.bz2 slony.osx || _die "Failed to create the archive (source/postgres.tar.bz2)" ############

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/osx)"
    mkdir -p $WD/Slony/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/staging/osx"
    ssh $PG_SSH_OSX "rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.$PG_VERSION_SLONY.so" || _die "Failed to remove slony binary files"
    ssh $PG_SSH_OSX "rm -f share/postgresql/slony*.sql" || _die "remove slony share files"

     # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/Slony ]; then rm -rf $PG_PATH_OSX/Slony/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/Slony/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/Slony/source/slony.osx.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/Slony/source || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/Slony
    tar -jcvf scripts.tar.bz2 scripts/osx 
    scp $WD/Slony/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/Slony || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"
    rm -f $WD/Slony/scripts.tar.bz2 || _die "Couldn't remove the scipts archive (source/scripts.tar.bz2)"    

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony/source; tar -jxvf slony.osx.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony; tar -jxvf scripts.tar.bz2"
    
    cd $WD
    echo "END PREP Slony OSX"
}

################################################################################
# Slony Build
################################################################################

_build_Slony_osx() {

    echo "BEGIN BUILD Slony OSX"

    echo "*******************************************************"
    echo " Build : Slony(OSX)"
    echo "*******************************************************"

    # build slony
    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx

cat <<EOT-SLONY > $WD/Slony/build-slony.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh

    echo "Configuring the slony source tree"
    cd $PG_PATH_OSX/Slony/source/slony.osx/
    cp $PG_PGHOME_OSX/lib/libpq*dylib .

    CONFIG_FILES="config"
    ARCHS="i386 x86_64"
    ARCH_FLAGS=""
    for ARCH in ${ARCHS}
    do
      echo "Configuring slony sources for ${ARCH}"
      CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ${ARCH}" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin --with-pgport=yes || _die "Failed to configure slony for intel"
      ARCH_FLAGS="${ARCH_FLAGS} -arch ${ARCH}"
      for configFile in ${CONFIG_FILES}
      do
           if [ -f "${configFile}.h" ]; then
              cp "${configFile}.h" "${configFile}_${ARCH}.h"
           fi
      done
    done

    echo "Configuring the slony source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS ${ARCH_FLAGS}" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin --with-pgport=yes || _die "Failed to configure slony for Universal"

	set -x
    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    for configFile in ${CONFIG_FILES}
    do
	echo "************************************** $configFile"
      HEADER_FILE=${configFile}.h
      if [ -f "${HEADER_FILE}" ]; then
        CONFIG_BASENAME=`basename ${configFile}`
        rm -f "${HEADER_FILE}"
        cat <<EOT > "${HEADER_FILE}"
#ifdef __BIG_ENDIAN__
  #error "${CONFIG_BASENAME}: Does not have support for ppc architecture"
#else
 #ifdef __LP64__
  #include "${CONFIG_BASENAME}_x86_64.h"
 #else
  #include "${CONFIG_BASENAME}_i386.h"
 #endif
#endif
EOT
      fi
    done

    echo "Building slony"
    cd $PG_PATH_OSX/Slony/source/slony.osx
    CFLAGS="$PG_ARCH_OSX_CFLAGS ${ARCH_FLAGS}" make

#    echo "Hacking scan.c generated by flex"
#    if [ x"`grep "typedef size_t yy_size_t" src/slony_logshipper/scan.c`" != x"" ]; then
#        _replace "typedef size_t yy_size_t" "typedef int yy_size_t" src/slony_logshipper/scan.c
#        CFLAGS="$PG_ARCH_OSX_CFLAGS ${ARCH_FLAGS}" make || _die "Failed to build slony"
#    else
#      _die "Failed to build slony"
#    fi
#
#    echo "Hacking slony1_funcs.so as it bundles only i386 version on Intel machine"
#    if [ -e $PG_PATH_OSX/Slony/source/slony.osx/src/backend ]; then
#        cd $PG_PATH_OSX/Slony/source/slony.osx/src/backend
#        if [ -e slony1_funcs.so ]; then
#            echo "Removing existing slony1_funcs.so"
#            rm -f slony1_funcs.so || _die "Couldn't remove slony_funcs.so"
#        fi
#        echo "Recreate slony1_funcs.so for universal architecture"
#        gcc $PG_ARCH_OSX_CFLAGS ${ARCH_FLAGS} -bundle -o slony1_funcs.so slony1_funcs.o -bundle_loader $PG_PGHOME_OSX/bin/postgres || _die "Couldn't create the hacked slony1_funcs.so"
#    fi

    cd $PG_PATH_OSX/Slony/source/slony.osx
    make install || _die "Failed to install slony"

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory

    mkdir -p $PG_PATH_OSX/Slony/staging/osx/bin
    cp $PG_PGHOME_OSX/bin/slon $PG_STAGING/bin || _die "Failed to copy slon binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slonik $PG_STAGING/bin || _die "Failed to copy slonik binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slony_logshipper $PG_STAGING/bin || _die "Failed to copy slony_logshipper binary to staging directory"
    chmod +rx $PG_PATH_OSX/Slony/staging/osx/bin/*

    mkdir -p $PG_PATH_OSX/Slony/staging/osx/lib
    cp $PG_PGHOME_OSX/lib/postgresql/slony1_funcs.so $PG_STAGING/lib || _die "Failed to copy slony_funcs.so to staging directory"
    chmod +r $PG_PATH_OSX/Slony/staging/osx/lib/*

    mkdir -p $PG_PATH_OSX/Slony/staging/osx/Slony
    cp $PG_PGHOME_OSX/share/postgresql/slony*.sql $PG_STAGING/Slony || _die "Failed to share files to staging directory"


    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $PG_PATH_OSX/Slony/staging/osx lib @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/Slony/staging/osx bin @loader_path/..

    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/Slony/staging/osx/bin/slon"
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/Slony/staging/osx/bin/slonik"
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/Slony/staging/osx/bin/slony_logshipper"

EOT-SLONY

    cd $WD
    scp Slony/build-slony.sh $PG_SSH_OSX:$PG_PATH_OSX/Slony
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony; sh ./build-slony.sh" || _die "Failed to build slony on OSX VM"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony/staging/osx; tar -jcvf Slony-staging.tar.bz2 *" || _die "Failed to create archive of the Slony staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/Slony/staging/osx/slony-staging.tar.bz2 $WD/Slony/staging/osx || _die "Failed to scp Slony staging"

    # Extract the staging archive
    cd $WD/Slony/staging/osx
    tar -jxvf slony-staging.tar.bz2 || _die "Failed to extract the server staging archive"
    rm -f slony-staging.tar.bz2
    echo "END BUILD Slony OSX"
}

################################################################################
# Slony Postprocess
################################################################################

_postprocess_Slony_osx() {
    
    echo "BEGIN POST Slony OSX"

    echo "*******************************************************"
    echo " Post Process : Slony(OSX)"
    echo "*******************************************************"

    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx

    cd $WD/Slony

    mkdir -p staging/osx/installer/Slony || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/Slony/createshortcuts.sh

    cp scripts/osx/configureslony.sh staging/osx/installer/Slony/configureslony.sh || _die "Failed to copy the configureSlony script (scripts/osx/configureslony.sh)"
    chmod ugo+x staging/osx/installer/Slony/configureslony.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/osx/pg-launchSlonyDocs.applescript.in staging/osx/scripts/pg-launchSlonyDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchSlonyDocs.applescript.in)"

    # Copy in the menu pick images and XDG items
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchSlonyDocs.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchSlonyDocs.icns)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION
    chmod a+x $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ Slony_I_PG$PG_CURRENT_VERSION $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`

     # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app.tar.bz2 slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf slony*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app; mv slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx-signed.app  slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD
    
    echo "END POST Slony OSX"
}

