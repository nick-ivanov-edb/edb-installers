#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_windows() {
    
    echo "BEGIN PREP ReplicationServer Windows"    

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.windows ];
    then
      echo "Removing existing ReplicationServer.windows source directory"
      rm -rf ReplicationServer.windows  || _die "Couldn't remove the existing ReplicationServer.windows source directory (source/ReplicationServer.windows)"
    fi
    if [ -e DataValidator.windows ];
    then
      echo "Removing existing DataValidator.windows source directory"
      rm -rf DataValidator.windows  || _die "Couldn't remove the existing DataValidator.windows source directory (source/DataValidator.windows)"
    fi
   
    if [ -e ReplicationServer.zip ];
    then
      echo "Removing existing ReplicationServer.zip"
      rm -f ReplicationServer.zip  || _die "Couldn't remove the existing ReplicationServer.zip (source/ReplicationServer.zip)"
    fi
    if [ -e DataValidator.zip ];
    then
      echo "Removing existing DataValidator.zip"
      rm -f DataValidator.zip  || _die "Couldn't remove the existing DataValidator.zip (source/DataValidator.zip)"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.windows)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.windows || _die "Couldn't create the ReplicationServer.windows directory"
    echo "Creating staging directory ($WD/ReplicationServer/source/DataValidator.windows)"
    mkdir -p $WD/ReplicationServer/source/DataValidator.windows || _die "Couldn't create the DataValidator.windows directory"


    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.windows || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.windows || _die "Couldn't set the permissions on the source directory"
    cp -R DataValidator/* DataValidator.windows || _die "Failed to copy the source code (source/DataValidator-$PG_VERSION_DataValidator)"
    chmod -R ugo+w DataValidator.windows || _die "Couldn't set the permissions on the source directory"

    # Copy validateuser to ReplicationServer directory
    cp -R $WD/ReplicationServer/scripts/windows/validateuser $WD/ReplicationServer/source/ReplicationServer.windows/validateuser || _die "Failed to copy scripts(validateuser)"

    # Copy createuser to ReplicationServer directory
    cp -R $WD/ReplicationServer/scripts/windows/createuser $WD/ReplicationServer/source/ReplicationServer.windows/createuser || _die "Failed to copy scripts(createuser)"

    # Copy ServiceWrapper to ReplicationServer directory
    cp -R $WD/resources/ServiceWrapper $WD/ReplicationServer/source/ReplicationServer.windows/ServiceWrapper || _die "Failed to copy scripts(ServiceWrapper)"

    # Copy validateUserClient scripts
    cp -R $WD/resources/validateUser.windows $WD/ReplicationServer/source/ReplicationServer.windows/validateUserClient || _die "Failed to copy scripts(validateUserClient)"
    cp -R $WD/resources/dbserver_guid/dbserver_guid/dbserver_guid $WD/ReplicationServer/source/ReplicationServer.windows/dbserver_guid || _die "Failed to copy dbserver_guid scripts"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.windows/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/DataValidator.windows/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.windows/lib || _die "Failed to copy pg jdbc drivers" 
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/DataValidator.windows/lib || _die "Failed to copy pg jdbc drivers" 

    echo "Archieving ReplicationServer sources"
    zip -r ReplicationServer.zip ReplicationServer.windows/ || _die "Couldn't create archieve of the ReplicationServer sources (ReplicationServer.zip)"
    zip -r DataValidator.zip DataValidator.windows/ || _die "Couldn't create archieve of the DataValidator sources (DataValidator.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/windows)"
    mkdir -p $WD/ReplicationServer/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/windows || _die "Couldn't set the permissions on the staging directory"

    # Clean sources on Windows VM

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST ReplicationServer.zip del /S /Q ReplicationServer.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\ReplicationServer.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST ReplicationServer.windows rd /S /Q ReplicationServer.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\ReplicationServer.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST DataValidator.zip del /S /Q DataValidator.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\DataValidator.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST DataValidator.windows rd /S /Q DataValidator.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\DataValidator.windows directory on Windows VM"

    # Copy sources on windows VM
    echo "Copying ReplicationServer sources to Windows VM"
    scp ReplicationServer.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the ReplicationServer archieve to windows VM (ReplicationServer.zip)"
    scp DataValidator.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the DataValidator archieve to windows VM (DataValidator.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip ReplicationServer.zip" || _die "Couldn't extract ReplicationServer archieve on windows VM (ReplicationServer.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip DataValidator.zip" || _die "Couldn't extract DataValidator archieve on windows VM (DataValidator.zip)"
    
    echo "END PREP ReplicationServer Windows"
}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_windows() {

    echo "BEGIN BUILD ReplicationServer Windows"     

     # build ReplicationServer   
    PG_STAGING=$PG_PATH_WINDOWS
    cd $WD/ReplicationServer
    SOURCE_DIR=$PG_PATH_WINDOWS/ReplicationServer.windows
    OUTPUT_DIR=$PG_PATH_WINDOWS\\\\ReplicationServer.windows\\\\dist
    STAGING_DIR=$WD/ReplicationServer/staging/windows

    cd $WD/ReplicationServer/source

cat <<EOT > "rs-build.bat"

@SET JAVA_HOME=$PG_JAVA_HOME_WINDOWS

cd "$PG_PATH_WINDOWS\ReplicationServer.windows"
SET SOURCE_PATH=%CD%

@CALL $PG_ANT_WINDOWS\\bin\\ant -f custom_build.xml dist
IF NOT EXIST "dist\repconsole\bin\edb-repcli.jar" goto build-failed

cd "$PG_PATH_WINDOWS\DataValidator.windows"
@CALL $PG_ANT_WINDOWS\\bin\\ant -f custom_build.xml dist
xcopy /y /s dist\* $PG_PATH_WINDOWS\ReplicationServer.windows\dist\repconsole\ 

REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

cd "%SOURCE_PATH%\\validateuser"
devenv /upgrade validateuser.vcproj
msbuild validateuser.vcxproj /p:Configuration=Release
IF NOT EXIST "release\\validateuser.exe" goto build-validateuser-failed

cd "%SOURCE_PATH%\\createuser"
devenv /upgrade createuser.vcproj
msbuild createuser.vcxproj /p:Configuration=Release
IF NOT EXIST "release\\createuser.exe" goto build-createuser-failed

cd "%SOURCE_PATH%\\ServiceWrapper"
devenv /upgrade ServiceWrapper.vcproj
msbuild ServiceWrapper.vcxproj /p:Configuration=Release
IF NOT EXIST "release\\ServiceWrapper.exe" goto build-servicewrapper-failed


cd "%SOURCE_PATH%\\validateUserClient"
devenv /upgrade validateuser.vcproj
msbuild validateuser.vcxproj /p:Configuration=Release
IF NOT EXIST "release\\validateUserClient.exe" goto build-wsvalidateuser-failed

cd "%SOURCE_PATH%\\dbserver_guid"
devenv /upgrade dbserver_guid.vcproj
msbuild dbserver_guid.vcxproj /p:Configuration=Release
IF NOT EXIST "release\\dbserver_guid.exe" goto build-dbserver-guid-failed

echo "copying application files into the output directory"
cd "%SOURCE_PATH%"
copy /y validateuser\\release\\validateuser.exe $OUTPUT_DIR
copy /y createuser\\\\release\\\\createuser.exe $OUTPUT_DIR
copy /y ServiceWrapper\\\\release\\\\ServiceWrapper.exe $OUTPUT_DIR
copy /y validateUserClient\\\\release\\\\validateUserClient.exe $OUTPUT_DIR
copy /y dbserver_guid\\\\release\\\\dbserver_guid.exe $OUTPUT_DIR
copy /Y $PG_PGBUILD_WINDOWS\\\\vcredist\\\\vcredist_x86.exe  $OUTPUT_DIR

echo "Removing existing dist.zip (if any)"
If EXIST dist.zip del /q dist.zip
echo "Archieving distribution files"
zip -r dist.zip dist\\*

echo Build encrypt-util
@CALL $PG_ANT_WINDOWS\\bin\\ant -f custom_build.xml encrypt-util

echo "Appending new files in the archieve"
zip -r dist.zip dist\\*

goto eof

:build-failed
echo "Replication Server failed to build on windows VM
exit 1

:build-validateuser-failed
echo "Failed to build validate-user utility"
exit 1

:build-createuser-failed
echo "Failed to build create-user utility"
exit 1

:build-servicewrapper-failed
echo "Failed to build service-wrapper utility"
exit 1

:build-wsvalidateuser-failed
echo "Failed to build web-service-validate-user utility"
exit 1

:build-dbserver-guid-failed
echo "Failed to build guid utility"
exit 1

:eof

EOT
 
    scp $WD/ReplicationServer/source/rs-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/ReplicationServer.windows/ || _die "Failed to copy the build script"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/ReplicationServer.windows; cmd /c rs-build.bat" || _die "Failed to build Replication Server on windows host"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/ReplicationServer.windows/dist.zip $WD/ReplicationServer/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/ReplicationServer.windows/dist.zip)"
    unzip $WD/ReplicationServer/staging/windows/dist.zip -d $WD/ReplicationServer/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/dist.zip)"
    rm $WD/ReplicationServer/staging/windows/dist.zip
    cp -R $WD/ReplicationServer/staging/windows/dist/* $WD/ReplicationServer/staging/windows/ || _die "Failed to rename the dist folder"
    rm -rf $WD/ReplicationServer/staging/windows/dist

    mkdir -p $WD/ReplicationServer/staging/windows/instscripts/bin || _die "Failed to make the instscripts bin directory"
    mkdir -p $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to make the installer scripts directory"
    mkdir -p $WD/ReplicationServer/staging/windows/scripts || _die "Failed to make the scripts bin directory"
    
    mv $WD/ReplicationServer/staging/windows/validateuser.exe $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/vcredist_x86.exe $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/createuser.exe $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/ServiceWrapper.exe $WD/ReplicationServer/staging/windows/scripts || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/edb-repencrypter.jar $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/lib $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    
    cd $WD
    mv $WD/ReplicationServer/staging/windows/validateUserClient.exe $WD/ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy the utilities (validateUserClient.exe)"
    mv $WD/ReplicationServer/staging/windows/dbserver_guid.exe $WD/ReplicationServer/staging/windows/instscripts/bin/uuid.exe || _die "Failed to copy the utilities (dbserver_guid.exe)"

    cp -R server/staging/windows/lib/libpq* ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/ssleay32.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv2.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll ReplicationServer/staging/windows/instscripts/bin/ || _die "Failed to copy dependent libs"

    cp -R MigrationToolKit/staging/windows/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/windows/repserver/lib/repl-mtk || _die "Failed to copy edb-migrationtoolkit.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/staging/windows/repconsole/lib/jdbc/ || _die "Failed to copy pg jdbc drivers"

    _replace "java -jar edb-repconsole.jar" "\"@@JAVA@@\" -jar \"@@INSTALL_DIR@@\\\\bin\\\\edb-repconsole.jar\"" "$WD/ReplicationServer/staging/windows/repconsole/bin/runRepConsole.bat" || _die "Failed to put the placehoder in runRepConsole.bat file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "\"@@JAVA@@\" -jar \"@@INSTALL_DIR@@\\\\bin\\\\edb-repserver.jar\" pubserver @@PUBPORT@@ \"@@CONFPATH@@\"" "$WD/ReplicationServer/staging/windows/repserver/bin/runPubServer.bat" || _die "Failed to put the placehoder in runPubServer.bat file"
    _replace "java -jar edb-repserver.jar subserver 9012" "\"@@JAVA@@\" -jar \"@@INSTALL_DIR@@\\\\bin\\\\edb-repserver.jar\" subserver @@SUBPORT@@ \"@@CONFPATH@@\"" "$WD/ReplicationServer/staging/windows/repserver/bin/runSubServer.bat" || _die "Failed to put the placehoder in runSubServer.bat file"

    unix2dos $WD/ReplicationServer/staging/windows/repconsole/doc/README-datavalidator.txt || _die "Failed to convert datavalidator readme in dos readable format."
    unix2dos $WD/ReplicationServer/staging/windows/repserver/etc/xdb_pubserver.conf || _die "Failed to convert xdb_pubserver conf in dos readable format."
    unix2dos $WD/ReplicationServer/staging/windows/repserver/etc/xdb_subserver.conf || _die "Failed to convert xdb_subserver conf in dos readable format."
    unix2dos $WD/ReplicationServer/staging/windows/repconsole/etc/datavalidator.properties || _die "Failed to convert datavalidator properties in dos readable format."
    
    echo "END BUILD ReplicatioinServer Windows"
}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_windows() {
 
    echo "BEGIN POST ReplicationServer Windows"    

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"

    # Setup Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/windows/serviceWrapper.vbs staging/windows/scripts/ || _die "Failed to copy the serviceWrapper.vbs file"
    cp scripts/windows/runRepConsole.vbs staging/windows/scripts/ || _die "Failed to copy the serviceWrapper.vbs file"
    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    if [ -f installer-win.xml ];    
    then
        rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml
    _replace "registration_plus_component" "registration_plus_component_windows" installer-win.xml || _die "Failed to replace the registration_plus component file name"
    _replace "registration_plus_preinstallation" "registration_plus_preinstallation_windows" installer-win.xml || _die "Failed to replace the registration_plus preinstallation file name"
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-windows.exe"

    cd $WD
    
    echo "END POST ReplicationServer Windows"
}
