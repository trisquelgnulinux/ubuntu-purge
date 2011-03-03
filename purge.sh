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

[ $2"1" = "test1" ] && TEST=echo

DIST=$1
REPLACE=$(ls -1 /home/systems/devel/helpers/$DIST/make-* | sed 's:^.*/::; s:make-::')
NETINST="apt-setup base-installer choose-mirror debian-installer main-menu netcfg net-retriever pkgsel"

if [ -x purge-$DIST ] 
then
    . ./purge-$DIST
else
    exit 1
fi

PACKAGES="$REPLACE $NETINST $REMOVE $UNBRAND"

for SOURCE in $PACKAGES
do
    ls pool/*/*/${SOURCE}/ > /dev/null 2>&1 || continue
    echo Found $SOURCE directory
    for package in $(ls -1 pool/*/*/${SOURCE}/* 2>/dev/null | awk -F '/' '{print $5}'|awk -F '_' '{print $1}'|sort -u  )
    do
        echo Found $package package
        for repo in $DIST $DIST-updates $DIST-security $DIST-backports
        do
            if $TEST reprepro -v remove $repo $package 2>&1 | grep -q "Not removed"
            then
                echo E: Not in $repo
            else
                echo Blacklisting $package
                echo "$package purge" >> conf/purge-$DIST
            fi
        done
     done
done

echo Sorting blacklist
sort -u < conf/purge-$DIST > /tmp/purge-$DIST
mv /tmp/purge-$DIST conf/purge-$DIST
