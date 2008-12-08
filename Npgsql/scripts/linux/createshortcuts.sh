#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir>"
    exit 127
fi

INSTALLDIR="$1"

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
    sed -e "s^$1^$2^g" "$3" > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp "$3" || _die "Failed to move /tmp/$$.tmp to $3"
}

# Substitute values into a file ($in)
_fixup_file() {
    _replace INSTALL_DIR "$INSTALLDIR" "$1"
}

# Create the icon resources
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-postgresql.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-npgsql.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-launchDocsAPI.png"
"$INSTALLDIR/installer/xdg/xdg-icon-resource" install --size 32 "$INSTALLDIR/scripts/images/pg-launchUserManual.png"

# Fixup the scripts
chmod ugo+x "$INSTALLDIR/installer/npgsql/"*.sh

# Fixup the XDG files (don't just loop in case we have old entries we no longer want)
_fixup_file "$INSTALLDIR/scripts/xdg/pg-launchDocsAPI.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-launchUserManual.desktop"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-postgresql.directory"
_fixup_file "$INSTALLDIR/scripts/xdg/pg-npgsql.directory"

chmod ugo+x "$INSTALLDIR/scripts/xdg/pg-launchDocsAPI.desktop"
chmod ugo+x "$INSTALLDIR/scripts/xdg/pg-launchUserManual.desktop"
chmod ugo+x "$INSTALLDIR/scripts/xdg/pg-npgsql.directory"
chmod ugo+x "$INSTALLDIR/scripts/xdg/pg-postgresql.directory"

# Create the menu shortcuts - first the top level, then the documentation menu.
"$INSTALLDIR/installer/xdg/xdg-desktop-menu" install --mode system \
         "$INSTALLDIR/scripts/xdg/pg-postgresql.directory" \
         "$INSTALLDIR/scripts/xdg/pg-npgsql.directory" \
         "$INSTALLDIR/scripts/xdg/pg-launchDocsAPI.desktop" \
	 "$INSTALLDIR/scripts/xdg/pg-launchUserManual.desktop"  || _warn "Failed to create the Npgsql menu"

echo "$0 ran to completion"
exit 0
