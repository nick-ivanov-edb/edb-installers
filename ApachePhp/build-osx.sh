#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ApachePhp_osx() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP ApachePhp OSX"

    echo "*******************************************************"
    echo " Pre Process : ApachePHP (OSX)"
    echo "*******************************************************"
      
    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source

    if [ -e apache.osx ];
    then
      echo "Removing existing apache.osx source directory"
      rm -rf apache.osx  || _die "Couldn't remove the existing apache.osx source directory (source/apache.osx)"
    fi

    echo "Creating apache source directory ($WD/ApachePhp/source/apache.osx)"
    mkdir -p apache.osx || _die "Couldn't create the apache.osx directory"
    chmod 755 apache.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -pR httpd-$PG_VERSION_APACHE/* apache.osx || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    tar -jcvf apache.tar.bz2 apache.osx

    if [ -e php.osx ];
    then
      echo "Removing existing php.osx source directory"
      rm -rf php.osx  || _die "Couldn't remove the existing php.osx source directory (source/php.osx)"
    fi
    
    echo "Creating php source directory ($WD/ApachePhp/source/php.osx)"
    mkdir -p php.osx || _die "Couldn't create the php.osx directory"
    chmod ugo+w php.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the php source tree
    cp -pR php-$PG_VERSION_PHP/* php.osx || _die "Failed to copy the source code (source/php-$PG_VERSION_PHP)"
    cd php.osx
    if [ -f $WD/tarballs/php-${PG_VERSION_PHP}_osx.patch ]; then
      echo "Applying php patch on osx..."
      patch -p1 < $WD/tarballs/php-${PG_VERSION_PHP}_osx.patch
    fi

    cd $WD/ApachePhp/source
    tar -jcvf php.tar.bz2 php.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApachePhp/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApachePhp/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApachePhp/staging/osx)"
    mkdir -p $WD/ApachePhp/staging/osx || _die "Couldn't create the staging directory"
    chmod 755 $WD/ApachePhp/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/ApachePhp ]; then rm -rf $PG_PATH_OSX/ApachePhp/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/ApachePhp/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/ApachePhp/source/apache.tar.bz2 php.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/ApachePhp/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/ApachePhp
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/ApachePhp/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/ApachePhp || _die "Failed to copy the scripts to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApachePhp/source; tar -jxvf apache.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApachePhp/source; tar -jxvf php.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApachePhp; tar -jxvf scripts.tar.bz2"

    ssh $PG_SSH_OSX "ln -s $PG_PGHOME_OSX/lib/libpq.5.dylib $PG_PATH_OSX/ApachePhp/source/php.osx/sapi/cli/libpq.5.dylib"
   
    echo "END PREP ApachePhp OSX"
}


################################################################################
# ApachePHP Build
################################################################################

_build_ApachePhp_osx() {
    echo "BEGIN BUILD ApachePhp OSX"

    echo "*******************************************************"
    echo " Build : ApachePHP (OSX)"
    echo "*******************************************************"

	OLDPATH=$PATH
    PATH=/bin:/sbin:/usr/bin:/usr/sbin
    export PATH

    # build apache
    PG_STAGING=$PG_PATH_OSX/ApachePhp/staging/osx

    cat <<EOT-APACHEPHP > build-apachephp.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh
    cd $PG_PATH_OSX/ApachePhp/source/apache.osx

    # Configure the source tree
    CONFIG_FILES="include/ap_config_auto include/ap_config_layout \
srclib/apr/include/apr srclib/apr/include/arch/unix/apr_private \
srclib/apr-util/include/apr_ldap srclib/apr-util/include/apu \
srclib/apr-util/include/apu_want srclib/apr-util/include/private/apu_config \
srclib/apr-util/include/private/apu_select_dbm srclib/apr-util/xml/expat/config \
srclib/apr-util/xml/expat/lib/expat"
    ARCHS="i386 x86_64"
    ARCH_FLAGS=""
    for ARCH in \${ARCHS}
    do
      echo "Configuring the apache source tree for \${ARCH}"
      CFLAGS="${PG_ARCH_OSX_CFLAGS} -arch \${ARCH} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} -L/opt/local/Current/lib -arch \${ARCH}" ./configure --prefix=$PG_STAGING/apache --with-ssl=/opt/local/Current --with-pcre=/opt/local/Current --with-included-apr --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache || _die "Failed to configure apache for \${ARCH}"
      ARCH_FLAGS="\${ARCH_FLAGS} -arch \${ARCH}"
      for configFile in \${CONFIG_FILES}
      do
           if [ -f "\${configFile}.h" ]; then
              cp "\${configFile}.h" "\${configFile}_\${ARCH}.h"
           fi
      done
    done

    echo "Configuring the apache source tree for Universal"
    CFLAGS="${PG_ARCH_OSX_CFLAGS} \${ARCH_FLAGS} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} \${ARCH_FLAGS} -L/opt/local/Current/lib" ./configure --prefix=$PG_STAGING/apache --with-ssl=/opt/local/Current --with-pcre=/opt/local/Current --with-included-apr --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache || _die "Failed to configure apache for 32 bit Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    for configFile in \${CONFIG_FILES}
    do
      HEADER_FILE=\${configFile}.h
      if [ -f "\${HEADER_FILE}" ]; then
        CONFIG_BASENAME=\`basename \${configFile}\`
        rm -f "\${HEADER_FILE}"
        cat <<EOT > "\${HEADER_FILE}"
#ifdef __BIG_ENDIAN__
  #error "\${CONFIG_BASENAME}: Does not have support for ppc64 architecture"
#else
 #ifdef __LP64__
  #include "\${CONFIG_BASENAME}_x86_64.h"
 #else
  #include "\${CONFIG_BASENAME}_i386.h"
 #endif
#endif
EOT
      fi
    done

    # Hackup the httpd config to get suitable paths in the binary
    _replace "#define HTTPD_ROOT \"$PG_STAGING/apache\"" "#define HTTPD_ROOT \"/Library/EnterpriseDB-ApachePhp/apache\"" include/ap_config_auto.h

    echo "Building apache"
    CFLAGS="${PG_ARCH_OSX_CFLAGS} \${ARCH_FLAGS} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} \${ARCH_FLAGS} -L/opt/local/Current/lib" make || _die "Failed to build apache"
    make install || _die "Failed to install apache"

    PATH=$OLDPATH
    export PATH

    #Configure the httpd.conf file
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "htdocs" "www" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "#ServerName www.example.com:80" "ServerName localhost:@@PORT@@" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "#LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" "LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "$PG_STAGING/apache/conf/httpd.conf"

    # disable SSL v3 because of POODLE vulnerability
    echo "SSLProtocol All -SSLv2 -SSLv3" >> extra/httpd-ssl.conf

    #Apply patch to apachectl before continuing
#    echo "Applying apachectl patch to comment ulimit check"
#    cd $PG_STAGING/apache/bin
#    patch ./apachectl $WD/tarballs/apache_fb13276.diff
#    cd $PG_PATH_OSX/ApachePhp/source/apache.osx
    
    #Configure the apachectl script file
    _replace "\\\$HTTPD -k \\\$ARGV" "\\"\\\$HTTPD\\" -k \\\$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$PG_STAGING/apache/bin/apachectl"
    _replace "\\\$HTTPD -t" "\\"\\\$HTTPD\\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$PG_STAGING/apache/bin/apachectl"
    _replace "\\\$HTTPD \\\$ARGV" "\\"\\\$HTTPD\\" \\\$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$PG_STAGING/apache/bin/apachectl"   chmod ugo+x "$PG_STAGING/apache/bin/apachectl"

    CONFIG_FILES="acconfig main/build-defs main/php_config"
    cd $PG_PATH_OSX/ApachePhp/source/php.osx

    for ARCH in \${ARCHS}
    do
      echo "Configuring the php source tree for \${ARCH}"
      CFLAGS="${PG_ARCH_OSX_CFLAGS} -arch \${ARCH} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} -L/opt/local/Current/lib -arch \${ARCH}" ./configure --with-libxml-dir=/opt/local/Current --with-openssl-dir=/opt/local/Current --with-zlib-dir=/opt/local/Current --with-iconv=/opt/local/Current --with-libexpat-dir=/opt/local/Current --prefix=$PG_STAGING/php --with-libmbfl=/opt/local/Current --with-pgsql=$PG_PGHOME_OSX --with-pdo-pgsql=$PG_PGHOME_OSX --with-apxs2=$PG_STAGING/apache/bin/apxs --with-config-file-path=/opt/local/Current/etc --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite --with-gd --with-jpeg-dir=/opt/local/Current --with-png-dir=/opt/local/Current --with-freetype-dir=/opt/local/Current --enable-gd-native-ttf --enable-mbstring=all || _die "Failed to configure PHP for \${ARCH}"
      for configFile in \${CONFIG_FILES}
      do
           if [ -f "\${configFile}.h" ]; then
              mv \${configFile}.h \${configFile}_\${ARCH}.h
           fi
      done
    done
 
    echo "Configuring the php source tree for Universal"
    CFLAGS="${PG_ARCH_OSX_CFLAGS} \${ARCH_FLAGS} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} \${ARCH_FLAGS} -L/opt/local/Current/lib" ./configure --with-libxml-dir=/opt/local/Current --with-openssl-dir=/opt/local/Current --with-zlib-dir=/opt/local/Current --with-iconv=/opt/local/Current --with-libexpat-dir=/opt/local/Current --prefix=$PG_STAGING/php --with-libmbfl=/opt/local/Current --with-pgsql=$PG_PGHOME_OSX --with-pdo-pgsql=$PG_PGHOME_OSX --with-apxs2=$PG_STAGING/apache/bin/apxs --with-config-file-path=/opt/local/Current/etc --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite --with-gd --with-jpeg-dir=/opt/local/Current --with-png-dir=/opt/local/Current --with-freetype-dir=/opt/local/Current --enable-gd-native-ttf --enable-mbstring=all || _die "Failed to configure PHP for Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    for configFile in \${CONFIG_FILES}
    do
      HEADER_FILE=\${configFile}.h
      if [ -f "\${HEADER_FILE}" ]; then
        CONFIG_BASENAME=\`basename \${configFile}\`
        rm -f "\${HEADER_FILE}"
        cat <<EOT > "\${HEADER_FILE}"
#ifdef __BIG_ENDIAN__
  #error "\${CONFIG_BASENAME}: Does not have support for ppc64 architecture"
#else
 #ifdef __LP64__
  #include "\${CONFIG_BASENAME}_x86_64.h"
 #else
  #include "\${CONFIG_BASENAME}_i386.h"
 #endif
#endif
EOT
      fi
    done

    PATH=$OLDPATH
    export PATH

    echo "Building php"
    cd $PG_PATH_OSX/ApachePhp/source/php.osx
    CFLAGS="${PG_ARCH_OSX_CFLAGS} \${ARCH_FLAGS} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} \${ARCH_FLAGS} -L/opt/local/Current/lib -lresolv" make -j4 || _die "Failed to build php"
    
    install_name_tool -change "libpq.5.dylib" "$PG_PGHOME_OSX/lib/libpq.5.dylib" "$PG_PATH_OSX/ApachePhp/source/php.osx/sapi/cli/php"

    make install || _die "Failed to install php"
    cd $PG_PATH_OSX/ApachePhp/source/php.osx
    if [ -f php.ini-production ]; then
      cp php.ini-production $PG_STAGING/php/php.ini || _die "Failed to copy php.ini file"
    else
      cp php.ini-recommended $PG_STAGING/php/php.ini || _die "Failed to copy php.ini file"
    fi
    
    install_name_tool -change "$PG_PGHOME_OSX/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_STAGING/php/bin/php"

    cp $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/php/lib || _die "Failed to copy libpq to php lib "

    # Copy in the dependency libraries
    cp -pR /opt/local/Current/lib/libpng*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libjpeg*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libfreetype*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libxml*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libexpat*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libz*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libmbfl*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libcrypto*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libexpat*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libssl*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libiconv*.dylib $PG_STAGING/php/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libpcre.*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"

    chmod u+w $PG_STAGING/apache/lib/*

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $PG_STAGING apache/lib @loader_path/../..
    _rewrite_so_refs $PG_STAGING apache/modules @loader_path/../..
    _rewrite_so_refs $PG_STAGING apache/bin @loader_path/../..
    _rewrite_so_refs $PG_STAGING php/bin @loader_path/../..
    _rewrite_so_refs $PG_STAGING php/lib @loader_path/../..

    files=\`ls $PG_STAGING/apache/modules/libphp*.so\`
    for file in \$files
    do 
        install_name_tool -change "libpq.5.dylib" "@loader_path/../../php/lib/libpq.5.dylib" \$file
        install_name_tool -change "libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libfreetype.6.dylib" "@loader_path/../../php/lib/libfreetype.6.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libpng16.16.dylib" "@loader_path/../../php/lib/libpng16.16.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libjpeg.9.dylib" "@loader_path/../../php/lib/libjpeg.9.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libxml2.2.dylib" "@loader_path/../../php/lib/libxml2.2.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libz.1.dylib" "@loader_path/../../php/lib/libz.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libiconv.2.dylib" "@loader_path/../../php/lib/libiconv.2.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libmbfl.1.dylib" "@loader_path/../../php/lib/libmbfl.1.dylib" \$file
    done
   
    install_name_tool -change "@loader_path/../../lib/libz.1.dylib" "@loader_path/../../php/lib/libz.1.dylib" $PG_STAGING/apache/modules/mod_deflate.so
    install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.dylib" $PG_STAGING/apache/modules/mod_ssl.so
    install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.dylib" $PG_STAGING/apache/modules/mod_ssl.so

    files=\`ls $PG_STAGING/apache/bin/*\`
    for file in \$files
    do
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libpcre.1.dylib" "@loader_path/../../apache/lib/libpcre.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libiconv.2.dylib" "@loader_path/../../php/lib/libiconv.2.dylib" \$file
    done
    files=\`ls $PG_STAGING/php/bin/*\`
    for file in \$files
    do
        install_name_tool -change "libpq.5.dylib" "@loader_path/../../php/lib/libpq.5.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libfreetype.6.dylib" "@loader_path/../../php/lib/libfreetype.6.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libpng16.16.dylib" "@loader_path/../../php/lib/libpng16.16.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libjpeg.9.dylib" "@loader_path/../../php/lib/libjpeg.9.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libxml2.2.dylib" "@loader_path/../../php/lib/libxml2.2.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libz.1.dylib" "@loader_path/../../php/lib/libz.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libiconv.2.dylib" "@loader_path/../../php/lib/libiconv.2.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
	install_name_tool -change "@loader_path/../../lib/libmbfl.1.dylib" "@loader_path/../../php/lib/libmbfl.1.dylib" \$file
    done
    files=\`ls $PG_STAGING/apache/lib/lib*.dylib\`
    for file in \$files
    do
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libiconv.2.dylib" "@loader_path/../../php/lib/libiconv.2.dylib" \$file
    done
    files=\`ls $PG_STAGING/php/lib/lib*.dylib\`
    for file in \$files
    do
        install_name_tool -change "@loader_path/../../lib/libz.1.dylib" "@loader_path/../../php/lib/libz.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libiconv.2.dylib" "@loader_path/../../php/lib/libiconv.2.dylib" \$file
    done
EOT-APACHEPHP

    scp build-apachephp.sh $PG_SSH_OSX:$PG_PATH_OSX/ApachePhp
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApachePhp; sh ./build-apachephp.sh" || _die "Failed to build ApachePhp on OSX"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_STAGING; tar -jcvf apachephp-staging.tar.bz2 *" || _die "Failed to create archive of the apachephp staging"
    scp $PG_SSH_OSX:$PG_STAGING/apachephp-staging.tar.bz2 $WD/ApachePhp/staging/osx || _die "Failed to scp apachephp staging"

    # Extract the staging archive
    cd $WD/ApachePhp/staging/osx
    tar -jxvf apachephp-staging.tar.bz2 || _die "Failed to extract the apachephp staging archive"
    rm -f apachephp-staging.tar.bz2

    echo "END BUILD ApachePhp OSX"
}


################################################################################
# PostProcess ApachePHP
################################################################################

_postprocess_ApachePhp_osx() {
    echo "BEGIN POST ApachePhp OSX"

    echo "*******************************************************"
    echo " Post Process : ApachePHP (OSX)"
    echo "*******************************************************"

    #PG_PATH_OSX=$WD

    PG_STAGING=$PG_PATH_OSX/ApachePhp/staging/osx
    
    #Configure the files in apache and php
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApachePhp/staging/osx" | grep -v Binary`

    cd $WD/ApachePhp/staging/osx

    pushd $WD/ApachePhp/staging/osx
    generate_3rd_party_license "apache_php"
    popd

    for file in $filelist
    do
        _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
        chmod ugo+x "$file"
    done  

    cd $WD/ApachePhp

    # Setup the installer scripts. 

    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/osx/apache/htdocs staging/osx/apache/www || _die "Failed to change Server Root"
    chmod 755 staging/osx/apache/www

    mkdir -p staging/osx/installer/ApachePhp || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/osx/apache/www/images || _die "Failed to create a directory for the images"
    chmod 755 staging/osx/apache/www/images

    cp scripts/osx/createshortcuts.sh staging/osx/installer/ApachePhp/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/ApachePhp/createshortcuts.sh

    cp scripts/osx/configureApachePhp.sh staging/osx/installer/ApachePhp/configureApachePhp.sh || _die "Failed to copy the configureApachePhp script (scripts/osx/configureApachePhp.sh)"
    chmod ugo+x staging/osx/installer/ApachePhp/configureApachePhp.sh

    cp scripts/osx/startupcfg.sh staging/osx/installer/ApachePhp/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/installer/ApachePhp/startupcfg.sh
   
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"

    # Copy in the menu pick images 
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    cp scripts/osx/pg-launchApachePhp.applescript.in staging/osx/scripts/pg-launchApachePhp.applescript || _die "Failed to copy a menu pick desktop"
    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    cp resources/index.php staging/osx/apache/www || _die "Failed to copy index.php"

    # Set permissions to all files and folders in staging
    _set_permissions osx

    chmod ugo+x staging/osx/php/php.ini
    chmod ugo+x staging/osx/apache/www/index.php

    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/osx/apache/www/index.php" 
    _replace PG_VERSION_PHP $PG_VERSION_PHP "staging/osx/apache/www/index.php" 

    #Remove the httpd.conf.bak from the staging if exists.
    if [ -f staging/osx/apache/conf/httpd.conf.bak ]; then
      rm -f staging/osx/apache/conf/httpd.conf.bak
    fi

    # Build the installer"
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output

    # Scp the app bundle to the signing machine for signing
    tar -jcvf apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app.tar.bz2 apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; rm -rf apache*" || _die "Failed to clean the $PG_PATH_OSX/output directory on sign server."
    scp apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX/output/
    rm -fr apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app*

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; tar -jxvf apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; rm -rf apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app; mv apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx-signed.app apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app;" || _die "could not move the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; zip -r apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.zip apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX/output/apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."
    
    cd $WD
    echo "END POST ApachePhp OSX"
}
