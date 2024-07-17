#!/bin/sh
#
#    Copyright (C) 2008-2021  Ruben Rodriguez <ruben@trisquel.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

DIST=$1
CODENAME=$2

echo Updating git package-helpers...
git --git-dir=/home/ubuntu/package-helpers/.git fetch --all
REPLACE=$(git --git-dir=/home/ubuntu/package-helpers/.git ls-tree -r --name-only origin/$CODENAME|grep helpers/make-|sed 's|helpers/make-||')

if [ -x purge-$DIST ] 
then
    . ./purge-$DIST
else
    exit 1
fi

echo Listing packages currently in local $DIST repository
for VARIANT in '' '-updates' '-security' '-backports'
do
  reprepro -A source list ${DIST}${VARIANT} | cut -d' ' -f2 > list-${DIST}${VARIANT}
  reprepro --list-format '${source}\n' list ${DIST}${VARIANT} | sed 's/ .*//' >> list-${DIST}${VARIANT}
  sort -u list-${DIST}${VARIANT} -o list-${DIST}${VARIANT}
done

# blocklist packages
echo Blocklisting packages defined in purge-$DIST

for PACKAGE in $REMOVE $UNBRAND $FAILSAFE; do

    if echo $PACKAGE |grep -q '\*'; then

        PACKAGE=$(echo $PACKAGE |sed 's/-*//; s/*//')
        EXTRAPACKAGES=$(grep "^$PACKAGE" list-$DIST* | sed 's/.*://' ||true)

        for EXTRA in $EXTRAPACKAGES; do
            echo "$EXTRA purge" >> conf/purge-$DIST
        done
    else
        echo "$PACKAGE purge" >> conf/purge-$DIST
    fi
done

# helper packages
echo Blacklisting packages defined by $CODENAME helpers
rm conf/replace-$DIST* -f

for PACKAGE in $REPLACE; do
    BACKPORT=false
    git --git-dir=/home/ubuntu/package-helpers/.git \
	show origin/$CODENAME:helpers/make-$PACKAGE |grep -q '^BACKPORTS*=true' \
	&& BACKPORT=true

    if $BACKPORT; then
        echo "$PACKAGE purge" >> conf/replace-$DIST-backports
    else
        echo "$PACKAGE purge" >> conf/replace-$DIST
    fi
done

for file in conf/purge-$DIST* conf/replace-$DIST*; do
    cat $file | sort -u > $file.tmp
    mv $file.tmp $file
done

echo Removing blocklisted packages found in local repository
for REPO in $DIST $DIST-updates $DIST-security; do
    for PACKAGE in $(cat conf/purge-$DIST conf/replace-$DIST | sed 's/ .*//'); do
        if grep "^$PACKAGE$" -q list-$REPO; then
            echo reprepro -v removesrc $REPO $PACKAGE
            reprepro -v removesrc $REPO $PACKAGE | echo $? | grep -qv 249
	    reprepro -v removefilter $REPO "Package (==$PACKAGE)"
        fi
    done
done

for PACKAGE in $(cat conf/replace-$DIST-backports | sed 's/ .*//'); do
    if grep "^$PACKAGE$" -q list-$DIST-backports; then
        echo reprepro -v removesrc $DIST-backports $PACKAGE
        reprepro -v removesrc $DIST-backports $PACKAGE | echo $? | grep -qv 249
	reprepro -v removefilter $REPO-backports "Package (==$PACKAGE)"
    fi
done

echo Finished
