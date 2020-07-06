#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_solaris_sparc() {

    echo "********************************************"
    echo "* Preparing - UpdateMonitor (solaris-sparc) *"
    echo "********************************************"

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    if [ -e updatemonitor.solaris-sparc ];
    then
      echo "Removing existing updatemonitor.solaris-sparc source directory"
      rm -rf updatemonitor.solaris-sparc  || _die "Couldn't remove the existing updatemonitor.solaris-sparc source directory (source/updatemonitor.solaris-sparc)"
    fi
   
    if [ -e updatemonitor.solaris-sparc.zip ];
    then
      echo "Removing existing updatemonitor.solaris-sparc zip file"
      rm -rf updatemonitor.solaris-sparc.zip  || _die "Couldn't remove the existing updatemonitor.solaris-sparc zip file (source/updatemonitor.solaris-sparc.zip)"
    fi
  
    if [ -e GetLatestPGInstalled.solaris-sparc ];
    then
      echo "Removing existing GetLatestPGInstalled.solaris-sparc source directory"
      rm -rf GetLatestPGInstalled.solaris-sparc  || _die "Couldn't remove the existing GetLatestPGInstalled.solaris-sparc source directory (source/GetLatestPGInstalled.solaris-sparc)"
    fi

    if [ -e GetLatestPGInstalled.solaris-sparc.zip ];
    then
      echo "Removing existing GetLatestPGInstalled.solaris-sparc zip file"
      rm -rf GetLatestPGInstalled.solaris-sparc.zip  || _die "Couldn't remove the existing GetLatestPGInstalled.solaris-sparc zip file (source/GetLatestPGInstalled.solaris-sparc.zip)"
    fi
 
    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.solaris-sparc)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.solaris-sparc || _die "Couldn't create the updatemonitor.solaris-sparc directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.solaris-sparc || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemonitor.solaris-sparc || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"
    zip -r updatemonitor.solaris-sparc.zip updatemonitor.solaris-sparc || _die "Failed to zip the updatemonitor source directory"

    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.solaris-sparc
    zip -r GetLatestPGInstalled.solaris-sparc.zip GetLatestPGInstalled.solaris-sparc || _die "Failed to zip the updatemonitor source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc" || _die "Failed to remove the UpdateMonitor staging directory from Soalris VM"
    fi
    
    ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source" || _die "Failed to remove the UpdateMonitor source directory from Soalris VM"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source" || _die "Failed to create the UpdateMonitor source directory on Soalris VM"
    scp updatemonitor.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/ 
    scp GetLatestPGInstalled.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source; unzip updatemonitor.solaris-sparc.zip" || _die "Failed to unzip the updatemonitor source directory on Soalris VM"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source; unzip GetLatestPGInstalled.solaris-sparc.zip" || _die "Failed to unzip the updatemonitor source directory on Soalris VM"

    echo "Creating staging directory ($WD/UpdateMonitor/staging/solaris-sparc)"
    mkdir -p $WD/UpdateMonitor/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/UpdateMonitor/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_solaris_sparc() {

    echo "*******************************************"
    echo "* Building - UpdateMonitor (solaris-sparc) *"
    echo "*******************************************"

    cd $WD/UpdateMonitor/source

    cat <<EOT > "setenv.sh"
export CC=gcc
export CXX=g++
export CFLAGS="-m64" 
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/ucb:\$PATH

EOT
    scp setenv.sh $PG_SSH_SOLARIS_SPARC: || _die "Failed to scp the setenv.sh file"

    cd $WD/UpdateMonitor/source/GetLatestPGInstalled.solaris-sparc
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/GetLatestPGInstalled.solaris-sparc;  g++ -m64 -DwxSIZE_T_IS_UINT -I/usr/local/include/wx-2.8/ -I/usr/local/lib/wx/include/gtk2-unicode-release-2.8/ -L/usr/local/lib -lwx_baseud-2.8 -o GetLatestPGInstalled  GetLatestPGInstalled.cpp" || _die "Failed to build GetLatestPGInstalled"

    cd $WD/UpdateMonitor/source/UpdateMonitor.solaris-sparc

    echo "Building & installing UpdateMonitor"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/updatemonitor.solaris-sparc; $PG_QMAKE_SOLARIS_SPARC UpdateManager.pro" || _die "Failed to configure UpdateMonitor on solaris-sparc"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/updatemonitor.solaris-sparc; gmake" || _die "Failed to build UpdateManger on solaris-sparc"
      
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/bin" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/lib" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/instscripts/bin" || _die "Failed to create the bin directory"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/instscripts/lib" || _die "Failed to create the bin directory"

    echo "Copying UpdateMonitor binary to staging directory"
    ssh $PG_SSH_SOLARIS_SPARC "cp $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/updatemonitor.solaris-sparc/UpdateManager $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/bin" || _die "Failed to copy the UpdateMonitor binary"
    ssh $PG_SSH_SOLARIS_SPARC "cp $PG_PATH_SOLARIS_SPARC/UpdateMonitor/source/GetLatestPGInstalled.solaris-sparc/GetLatestPGInstalled $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/instscripts/bin" || _die "Failed to copy the GetLatestPGInstallerd binary"

    echo "Copying dependent libraries to staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libwx_baseud-2.8.so.* $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libwx_baseud-2.8.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtXml.so.* $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtNetwork.so.* $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtCore.so.* $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtGui.so.* $PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (solaris-sparc)"

    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/UpdateMonitor/staging/solaris-sparc/* $WD/UpdateMonitor/staging/solaris-sparc/ || _die "Failed to copy back the staging directory from Solaris VM"

    cd $WD
}


################################################################################
# Post Processing UpdateMonitor
################################################################################

_postprocess_updatemonitor_solaris_sparc() {

    echo "**************************************************"
    echo "* Post-processing - UpdateMonitor (solaris-sparc) *"
    echo "**************************************************"
 
    cd $WD/UpdateMonitor

    mkdir -p staging/solaris-sparc/installer/UpdateMonitor || _die "Failed to create a directory for the installer scripts"
    
    mkdir -p staging/solaris-sparc/UpdateMonitor/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/solaris/launchUpdateMonitor.sh staging/solaris-sparc/UpdateMonitor/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/solaris/launchUpdateMonitor.sh)"
    chmod ugo+x staging/solaris-sparc/UpdateMonitor/scripts/launchUpdateMonitor.sh

    mkdir -p staging/solaris-sparc/UpdateMonitor/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/edb-um-update-monitor.desktop staging/solaris-sparc/UpdateMonitor/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    _replace @@COMPONENT_FILE@@ "component.xml" installer.xml || _die "Failed to replace the registration_plus component file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer for solaris-sparc"
   
    cd $WD
}
