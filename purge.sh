#!/bin/sh
#
#    Copyright (C) 2008,2009,2010  Rubén Rodríguez <ruben@gnu.org>
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
REPLACE=$(git --git-dir=/home/ubuntu/package-helpers/.git ls-tree -r --name-only $CODENAME|grep helpers/make-|sed 's/.*make-//')

if [ -x purge-$DIST ] 
then
    . ./purge-$DIST
else
    exit 1
fi

echo listing $DIST
reprepro -A source list $DIST | cut -d' ' -f2 > list1
reprepro -A source list $DIST-updates | cut -d' ' -f2 >> list1
reprepro -A source list $DIST-security | cut -d' ' -f2 >> list1
reprepro -A source list $DIST-backports | cut -d' ' -f2 >> list1
sort -u < list1 > list

PACKAGES="$REPLACE $REMOVE $UNBRAND $FAILSAFE"

echo Searching for packages to remove in $DIST
for PACKAGE in $PACKAGES; do

    if echo $PACKAGE |grep -q '\*'; then
        PACKAGE=$(echo $PACKAGE |sed 's/-*//; s/*//')
        for REPO in $DIST $DIST-updates $DIST-security $DIST-backports; do
            EXTRAPACKAGES=$(egrep "^$REPO\|" list |grep " $PACKAGE"|cut -d" " -f2)
            for EXTRA in $EXTRAPACKAGES; do
                echo "$EXTRA purge" >> conf/purge-$DIST
                echo 1 reprepro -v removesrc $REPO $EXTRA
                reprepro -v removesrc $REPO $EXTRA
            done
        done
    else
        echo "$PACKAGE purge" >> conf/purge-$DIST
        for REPO in $DIST $DIST-updates $DIST-security $DIST-backports; do
            if grep "^$PACKAGE$" -q list; then
                echo 2 reprepro -v removesrc $REPO $PACKAGE
                reprepro -v removesrc $REPO $PACKAGE
            fi
        done
    fi
done

for file in conf/purge*; do
    cat $file | sort -u > $file.tmp
    mv $file.tmp $file
done

exit

#--------------------------------------------------------------

echo Searching for missing packages in $DIST
rm -f /tmp/sourcemissing
for REPO in $DIST $DIST-updates $DIST-security $DIST-backports; do
  reprepro sourcemissing $REPO >> /tmp/sourcemissing
done

while read line; do

dist=$(echo $line | cut -d" " -f1 )
sourcepkg=$(echo $line | cut -d" " -f2 )
package=$(echo $line | cut -d" " -f4|sed 's_.*/__; s/_.*//' )

dir=$(echo $line | cut -d" " -f4 | sed 's/\(.*\)\/.*/\1/' )

if ! ls $dir|grep dsc -q; then

echo "$sourcepkg purge" conf/purge-$dist
echo "$sourcepkg purge" >> conf/purge-$dist

fi

#echo reprepro -v remove $dist $package
#reprepro -v remove $dist $package

done < /tmp/sourcemissing
#--------------------------------------------------------------



