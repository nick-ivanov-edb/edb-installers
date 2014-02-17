#!/bin/sh
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

INSTALLDIR="@@INSTALL_DIR@@"
PG_VERSION=@@PG_VERSION@@
BRANDING="@@BRANDING@@"
TEMPFILE=`mktemp -q /tmp/$$.tmp-XXXXXXXXXX`

# Version string, for the xdg filenames
PG_VERSION_STR=`echo $PG_VERSION | sed 's/\./_/g'`

# Branding string, for the xdg filenames. If the branding is 'PostgreSQL X.Y',
# Don't do anything to ensure we remain backwards compatible.
if [ x"$BRANDING" = x"PostgreSQL $PG_VERSION" ];
then
    BRANDING_STR="postgresql-$PG_VERSION_STR"
    BRANDED=0
else
    BRANDING_STR=`echo $BRANDING | sed 's/\./_/g' | sed 's/ /_/g'`
	BRANDED=1
fi


# Exit code
WARN=0

# Working directory
WD=`pwd`

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" "$3" > "$TEMPFILE" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv $TEMPFILE "$3" || _die "Failed to move $TEMPFILE to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
    _replace PG_MAJOR_VERSION "$PG_VERSION" "$1"
    _replace MONITOR_SERVER "$PG_VERSION" "$1"
    _replace PG_BRANDING "$BRANDING" "$1"
    _replace PG_VERSION_STR "$PG_VERSION_STR" "$1"
    chmod ugo+x "$1"
}

# Create the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-postgresql-$PG_VERSION_STR.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/edb-stackbuilderplus-$PG_VERSION_STR.png"

# Fixup the scripts
cd "$INSTALLDIR/installer/StackBuilderPlus"
SCRIPTS=`find . -iname "*.sh"`
for SCRIPT in $SCRIPTS
do
  chmod ugo+x $SCRIPT
done
_fixup_file "$INSTALLDIR/installer/StackBuilderPlus/configlibs.sh"
_fixup_file "$INSTALLDIR/scripts/launchStackBuilderPlus.sh"
_fixup_file "$INSTALLDIR/scripts/runStackBuilderPlus.sh"

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/edb-stackbuilderplus-$PG_VERSION_STR.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory"

# Copy the primary desktop file to the branded version. We don't do this if
# the installation is not branded, to retain backwards compatibility.
if [ $BRANDED -ne 0 ];
then
    cp "$INSTALLDIR/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory" "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory"
fi

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system  \
    "$INSTALLDIR/scripts/xdg/pg-$BRANDING_STR.directory" \
    "$INSTALLDIR/scripts/xdg/edb-stackbuilderplus-$PG_VERSION_STR.desktop"  || _warn "Failed to create the StackBuilderPlus menu"

#Ubuntu 10.04 and greater require menu cache update

if [ -f /usr/share/gnome-menus/update-gnome-menus-cache ];
then
   echo "Rebuilding /usr/share/applications/desktop.${LANG}.cache"
   /usr/share/gnome-menus/update-gnome-menus-cache /usr/share/applications/ > /usr/share/applications/desktop.${LANG}.cache
fi
echo "$0 ran to completion"
exit 0

