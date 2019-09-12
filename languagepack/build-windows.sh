#!/bin/bash

    
################################################################################
# Build Preparation
################################################################################

_prep_languagepack_windows() {

    ARCH=$1
    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       PG_SSH_WIN=$PG_SSH_WINDOWS
       PG_PATH_WIN=$PG_PATH_WINDOWS
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\i386"
    else
       ARCH="windows-x64"
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\x64"
    fi

    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source
    echo "Removing existing languagepack.$ARCH source directory and languagepack.zip"
    rm -rf languagepack.$ARCH*  || _die "Couldn't remove the existing languagepack.$ARCH source directory (source/languagepack.$ARCH)"
   
    echo "Creating source directory ($WD/languagepack/source/languagepack.$ARCH)"
    mkdir -p $WD/languagepack/source/languagepack.$ARCH || _die "Couldn't create the languagepack.$ARCH directory"

    # Copy languagepack build scripts
    cp $WD/languagepack/scripts/$ARCH/Tcl_Tk_Build.bat languagepack.$ARCH || _die "Failed to copy the languagepack build script (Tcl_Tk_Build.bat)"
    cp $WD/languagepack/scripts/$ARCH/Perl_Build.bat languagepack.$ARCH || _die "Failed to copy the languagepack build script (Perl_Build.bat)"
    cp $WD/languagepack/scripts/$ARCH/Python_Build.bat languagepack.$ARCH || _die "Failed to copy the languagepack build script (Python_Build.bat)"

    cd $WD/languagepack/source/languagepack.$ARCH
    extract_file $WD/../tarballs/tcl8.6.8-src || _die "Failed to extract tcl/tk source (tcl-8.6.8-src.tar.gz)"
    extract_file $WD/../tarballs/tk8.6.8-src || _die "Failed to extract tcl/tk source (tk-8.6.8-src.tar.gz)"
    extract_file $WD/../tarballs/perl-5.26.2 || _die "Failed to extract perl source (perl-5.26.2.tar.gz)"
    extract_file $WD/../tarballs/Python-3.7.4 || _die "Failed to extract python source (Python-3.7.4.tgz)"
    extract_file $WD/../tarballs/setuptools-39.2.0 || _die "Failed to extract python source (setuptools-39.2.0)"

    ####cp ../../scripts/$ARCH/tix-8.4.3.4-VC12.patch Python-3.7.4 || _die "Failed to copy the tix build patch tix-8.4.3.4-VC12.patch"

    if [ "$ARCH" = "windows-x32" ];
    then
        # Perl related changes - x32
        cd perl-5.26.2/win32
        sed -i "s/^INST_DRV\t= c:/INST_DRV\t= $PG_LANGUAGEPACK_INSTALL_DIR_WIN/g" Makefile
        sed -i 's/^INST_TOP\t= $(INST_DRV)\\perl/INST_TOP\t= $(INST_DRV)\\Perl-5.26/g' Makefile
        sed -i 's/^CCTYPE\t\t= MSVC60/CCTYPE\t\t= MSVC120/g' Makefile
        sed -i 's/^#WIN64\t\t= undef/WIN64\t\t= undef/g' Makefile
        sed -i 's/^BUILDOPT\t= $(BUILDOPT) -DUSE_SITECUSTOMIZE/BUILDOPT\t= $(BUILDOPT) -D_USE_32BIT_TIME_T/g' Makefile
        sed -i '/^DEFINES\t\t= $(DEFINES) -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE/s/^/#/g' Makefile

        # Python related changes - x32
        cd $WD/languagepack/source/languagepack.$ARCH/Python-3.7.4/PCbuild
        sed -i '/{E5B04CC0-EB4C-42AB-B4DC-18EF95F864B0}.Release|Win32.Build.0/d' pcbuild.sln || _die "Failed to disable OpenSSL build which comes with Python"
        sed -i 's/liblzma.a/liblzma.lib/g' _lzma.vcxproj || _die "Failed to change liblzma.a to liblzma.lib in _lzma.vcxproj"
        sed -i 's/inc32/include/g;s/out32/lib/g' _hashlib.vcxproj || _die "Failed to change inc32 to include and out32 to lib for OpenSSL libs in _hashlib.vcxproj"
        sed -i 's/inc32/include/g;s/out32/lib/g' _ssl.vcxproj || _die "Failed to change inc32 to include and out32 to lib for OpenSSL libs in _ssl.vcxproj"
        ##sed -i 's/<SubSystem>NotSet<\/SubSystem>/<SubSystem>Windows<\/SubSystem>/g' _ctypes.vcxproj || _die "Failed to update _ctypes.vcxproj"
        ##sed -i 's/<SubSystem>NotSet<\/SubSystem>/<SubSystem>Windows<\/SubSystem>/g' _decimal.vcxproj || _die "Failed to update _decimal.vcxproj"
        ##sed -i '26,37d' ../Tools/buildbot/external-common.bat || _die "Failed to remove OpenSSL and Tck/Tk checkout in external-common.bat"

        ##echo "extraction Pillow binaries into languagepack.$ARCH source folder."
        ##cd $WD/languagepack/source/languagepack.$ARCH
        ##extract_file $WD/../tarballs/Pillow-3.4.2.win32 || _die "Failed to extract Pillow binaries."

    else
        # Perl related changes - x64
        cd perl-5.26.2/win32
        sed -i "s/^INST_DRV\t= c:/INST_DRV\t= $PG_LANGUAGEPACK_INSTALL_DIR_WIN/g" Makefile
        sed -i 's/^INST_TOP\t= $(INST_DRV)\\perl/INST_TOP\t= $(INST_DRV)\\Perl-5.26/g' Makefile
        sed -i 's/^CCTYPE\t\t= MSVC60/CCTYPE\t\t= MSVC141/g' Makefile
        ####sed -i '/^BUILDOPT\t= $(BUILDOPTEXTRA)/a BUILDOPT\t= $(BUILDOPT) -DUSE_SITECUSTOMIZE' Makefile
        ####sed -i '/^DEFINES\t\t= $(DEFINES) -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE/s/^/#/g' Makefile

        # Python related changes - x64
        ####cd $WD/languagepack/source/languagepack.$ARCH/Python-3.7.4/PCbuild
        ####sed -i '/{E5B04CC0-EB4C-42AB-B4DC-18EF95F864B0}.Release|x64.Build.0/d' pcbuild.sln || _die "Failed to disable OpenSSL build which comes with Python"
        ####sed -i 's/inc64/include/g;s/out64/lib/g' _hashlib.vcxproj || _die "Failed to change inc32 to include and out32 to lib for OpenSSL libs in _hashlib.vcxproj"
        ####sed -i 's/inc64/include/g;s/out64/lib/g' _ssl.vcxproj || _die "Failed to change inc32 to include and out32 to lib for OpenSSL libs in _ssl.vcxproj"
        ##sed -i 's/<SubSystem>NotSet<\/SubSystem>/<SubSystem>Console<\/SubSystem>/g' _ctypes.vcxproj || _die "Failed to update _ctypes.vcxproj"
        ##sed -i 's/<SubSystem>NotSet<\/SubSystem>/<SubSystem>Console<\/SubSystem>/g' _decimal.vcxproj || _die "Failed to update _decimal.vcxproj"
        ##sed -i '26,37d' ../Tools/buildbot/external-common.bat || _die "Failed to remove OpenSSL and Tck/Tk checkout in external-common.bat"

        ##echo "extraction Pillow binaries into languagepack.$ARCH source folder."
        ##cd $WD/languagepack/source/languagepack.$ARCH
        ##extract_file $WD/../tarballs/Pillow-3.4.2.win-amd64 || _die "Failed to extract Pillow binaries."
    fi

    #Python related changes - x32/x64
    ####cd $WD/languagepack/source/languagepack.$ARCH/Python-3.7.4
    ####sed -i "s|<opensslDir>\$(externalsDir).*|<opensslDir>${PG_PGBUILD_WIN}</opensslDir>|g" PCbuild/pyproject.props || _die "Failed to update pyproject.props"
    ####sed -i 's/#if _MSC_VER >= 1800/#if _MSC_VER > 1800/g' PC/pyconfig.h || _die "Failed to update pyconfig.h"
    ####sed -i "s/VS100COMNTOOLS/VS120COMNTOOLS/g" PCbuild/env.bat || _die "Failed to update env.bat"

    cd $WD/languagepack/source
    echo "Archiving languagepack sources"
    zip -r languagepack.$ARCH.zip languagepack.$ARCH || _die "Failed to zip the languagepack source"
    chmod -R ugo+w languagepack.$ARCH || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c rd /S /Q $PG_LANGUAGEPACK_INSTALL_DIR_WIN"

    if [ -e $WD/languagepack/staging/$ARCH ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/$ARCH || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/$ARCH)"
    mkdir -p $WD/languagepack/staging/$ARCH || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/$ARCH || _die "Couldn't set the permissions on the staging directory"

    ##ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c rd /S /Q languagepack.$ARCH"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c del /S /Q languagepack.$ARCH.zip"
    
    echo "Copying languagepack sources to Windows VM"
    rsync -av languagepack.$ARCH.zip $PG_SSH_WIN:$PG_CYGWIN_PATH_WINDOWS || _die "Couldn't copy the languagepack archive to windows VM (languagepack.$ARCH.zip)"
    scp $WD/../PEM/requirements.txt $PG_SSH_WIN:$PG_CYGWIN_PATH_WINDOWS\\\\requirements.txt || _die "Couldn't copy PEM requirements.txt to windows VM (languagepack.$ARCH.zip)"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c rd /S /Q languagepack.$ARCH; unzip languagepack.$ARCH.zip" || _die "Couldn't extract languagepack archive on windows VM (languagepack.$ARCH.zip)"

    echo "END PREP languagepack Windows"
}

################################################################################
# Build LanguagePack
################################################################################

_build_languagepack_windows() {

    ARCH=$1
    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       PG_SSH_WIN=$PG_SSH_WINDOWS
       PG_PATH_WIN=$PG_PATH_WINDOWS
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\i386"
       CYGWIN_HOME="C:\\\\cygwin32"
       PG_PATH_PSYCOPG=$PG_BINARY_PATH
    else
       ARCH="windows-x64"
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\x64"
       CYGWIN_HOME="C:\\\\cygwin64"
       PG_PATH_PSYCOPG=$PG_BINARY_PATH_X64
    fi

    cd $WD/languagepack/scripts/$ARCH
    cat <<EOT > "Python_Build_Dependencies.bat"
@ECHO OFF

CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86

SET vPythonBuildDir=%1
SET vXZDir=%2

ECHO vPythonBuildDir ----  %vPythonBuildDir%
ECHO vXZDir ----  %vXZDir%

ECHO Executing batch file %vPythonBuildDir%\PCbuild\get_externals.bat
CD %vPythonBuildDir%\PCbuild
CALL %vPythonBuildDir%\PCbuild\get_externals.bat

ECHO Applying patch %vPythonBuildDir%\tix-8.4.3.4-VC12.patch
CD %vPythonBuildDir%
$CYGWIN_HOME\bin\patch -p1 < tix-8.4.3.4-VC12.patch

ECHO Changing Directory to %vXZDir%\bin_i486
CD %vXZDir%\bin_i486
dumpbin /exports liblzma.dll > liblzma.def
EOT

    # Tcl/Tk Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Tcl-8.6; cmd /c Tcl_Tk_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\tcl8.6.8 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Tcl-8.6 $PG_PATH_WIN\\\\languagepack.$ARCH\\\\tk8.6.8"

    # Perl Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output PERL"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output DBI"
    # Install cpanm to exclude running test cases when installing IPC and DBD as one of test cases stucks
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output CPANMINUS"
    ####ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output DBD"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output IPC"
   ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output WIN32PROCESS"
    # install.pm gets installed as part of IPC installation. Uninstall it as postgres installation fails because of it.
  ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.26.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.26 $PG_PATH_WIN\\\\output INSTALL"

    # Python Build
    cd $WD/languagepack/scripts/$ARCH
    ####scp Python_Build_Dependencies.bat $PG_SSH_WIN:$PG_PATH_WIN\\\\languagepack.$ARCH || _die "Failed to copy the Python_Build_Dependencies.bat to the windows build host"
    ####ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4; cmd /c ..\\\\Python_Build_Dependencies.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4 $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4\\\\externals\\\\xz-5.0.5"

    # Generating/Updating liblzma.def file for Python Build
    ####if [ "$ARCH" = "windows-x32" ];
    ####then
    ####    scp $PG_SSH_WIN:$PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4\\\\externals\\\\xz-5.0.5\\\\bin_i486\\\\liblzma.def $WD/languagepack/scripts/$ARCH/liblzma.def || _die "Failed to get liblzma.def from windows build host"
    ####    LinesBefore=$(grep -n "ordinal .*hint .*RVA .*name" liblzma.def | cut -d":" -f1)
    ####    sed -i "1,$(expr $LinesBefore)d" liblzma.def
    ####    TotalLines=$(grep -n "^[[:space:]]*Summary[[:space:]]*$" liblzma.def | cut -d":" -f1)
    ####    head -$(expr $TotalLines - 2) liblzma.def | awk -F" " '{print $4}' | sed '1 s/.*/EXPORTS/' > temp.def && mv temp.def liblzma.def
    ####    dos2unix liblzma.def
    ####    scp liblzma.def $PG_SSH_WIN:$PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4\\\\externals\\\\xz-5.0.5\\\\bin_i486 || _die "Failed to copy liblzma.def to the windows build host"
    ####fi

    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.7; cmd /c Python_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.7 $PG_PATH_WIN\\\\languagepack.$ARCH $PG_PGBUILD_WIN BUILD"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.7; cmd /c Python_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.7.4 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.7 $PG_PATH_WIN\\\\languagepack.$ARCH $PG_PGBUILD_WIN INSTALL"
    ####ssh $PG_SSH_WIN "sed -i 's/import winrandom/from Crypto.Random.OSRNG import winrandom/' $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.7\\\\Lib\\\\site-packages\\\\Crypto\\\\Random\\\\OSRNG\\\\nt.py"

    echo "Removing last successful staging directory ($PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging)"
    ssh $PG_SSH_WIN "cmd /c if EXIST $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging rd /S /Q $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WIN "cmd /c mkdir $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WIN "cmd /c xcopy /E /Q /Y $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\* $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WIN "cmd /c echo PG_VERSION_LANGUAGEPACK=$PG_VERSION_LANGUAGEPACK >  $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/versions-${ARCH}.sh" || _die "Failed to write languagepack version number into versions-windows.sh"
    ssh $PG_SSH_WIN "cmd /c echo PG_BUILDNUM_LANGUAGEPACK=$PG_BUILDNUM_LANGUAGEPACK >> $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/versions-${ARCH}.sh" || _die "Failed to write languagepack build number into versions-windows.sh"

}


################################################################################
# Build Postprocess
################################################################################

_postprocess_languagepack_windows() {

    ARCH=$1

    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       OS="windows"
       PG_SSH_WIN=$PG_SSH_WINDOWS
       PG_PATH_WIN=$PG_PATH_WINDOWS
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_CYG_PATH}/i386"
    else
       ARCH="windows-x64"
       OS=$ARCH
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_CYG_PATH}/x64"
    fi

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    if [ -e $WD/languagepack/staging/$ARCH ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/$ARCH || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/languagepack/staging/$ARCH)"
    mkdir -p $WD/languagepack/staging/$ARCH || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/$ARCH || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WIN "cd $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging; zip -r Tcl-8.6.zip Tcl-8.6; zip -r Perl-5.26.zip Perl-5.26; zip -r Python-3.7.zip Python-3.7" || _die "Failed to create Tcl-8.6.zip;Perl-5.26.zip;Python-3.7.zip on  windows buildhost"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/Tcl-8.6.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Tcl-8.6.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/Perl-5.26.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Perl-5.26.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/Python-3.7.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Python-3.7.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/versions-${ARCH}.sh  $WD/languagepack/staging/$ARCH || _die "Failed to copy versions-${ARCH}.sh"

    ssh $PG_SSH_WIN "cd $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging; rm -f Tcl-8.6.zip Perl-5.26.zip Python-3.7.zip " || _die "Failed to remove  Tcl-8.6.zip;Perl-5.26.zip; Python-3.7.zip on  windows buildhost"

    cd $WD/languagepack/staging/$ARCH/
    unzip Tcl-8.6.zip ||_die "Failed to unzip Tcl-8.6.zip"
    unzip Perl-5.26.zip || _die "Failed to unzip Perl-5.26.zip"
    unzip Python-3.7.zip || _die "Failed to unzip Python-3.7.zip"
    rm -f Tcl-8.6.zip Perl-5.26.zip Python-3.7.zip || _die "Failed to remove the Tcl-8.6.zip;Perl-5.26.zip;Python-3.7.zip"

    dos2unix $WD/languagepack/staging/$ARCH/versions-${ARCH}.sh || _die "Failed to convert format of versions-${ARCH}.sh from dos to unix"
    source $WD/languagepack/staging/$ARCH/versions-${ARCH}.sh
    PG_BUILD_LANGUAGEPACK=$(expr $PG_BUILD_LANGUAGEPACK + $SKIPBUILD)

    ####mv $WD/languagepack/staging/$ARCH/Python-3.7/pip_packages_list.txt $WD/languagepack/staging/$ARCH || _die "Failed to move pip_packages_list.txt to $WD/languagepack/staging/$ARCH"

    cd $WD/languagepack
    pushd staging/$ARCH
    generate_3rd_party_license "languagepack"
    popd

    mkdir -p $WD/languagepack/staging/$ARCH/installer/languagepack || _die "Failed to create a directory for the install scripts"

    if [ "$ARCH" = "windows-x64" ];
    then
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vcredist_x64.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x64.exe || _die "Failed to get vcredist_x64.exe from windows build host"
    else
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vcredist_x86.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x86.exe || _die "Failed to get vcredist_x86.exe from windows build host"
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vc2010\\\\vcredist_x86.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x86_2010.exe || _die "Failed to get vcredist_x86.exe of version 2010 from windows build host"
    fi   
 
    cd $WD/languagepack
    rm -rf $WD/languagepack/staging/windows
    mv $WD/languagepack/staging/$ARCH $WD/languagepack/staging/windows || _die "Failed to rename $ARCH staging directory to windows"

    if [ "$ARCH" = "windows-x64" ];
    then
        # Build the installer
        "$PG_INSTALLBUILDER_BIN" build installer.xml windows --setvars windowsArchitecture=x64 || _die "Failed to build the installer"
    else
        # Build the installer
        "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    fi

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_LANGUAGEPACK -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-$OS.exe $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}${OS}.exe

    if [ $SIGNING -eq 1 ]; then
        win32_sign "*-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}${OS}.exe"
    fi

    mv $WD/languagepack/staging/windows $WD/languagepack/staging/$ARCH || _die "Failed to rename windows staging directory to $ARCH"
    cd $WD
}
