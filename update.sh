#!/bin/sh
#
#    Copyright (C) 2008,2009,2010,2011  Ruben Rodriguez <ruben@gnu.org>
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

doall(){

date
echo Updating...
reprepro  -v -b . update
if reprepro  -v -b . update
then
    [ -f ERROR ] && rm ERROR
else
    echo WARNING: reprepro ended unexpectedly
    echo Do NOT update any leaf repositories from here until it is fixed
    date > ERROR
fi

echo Removing non free packages...
rm list
sh purge.sh lucid taranis
sh purge.sh precise toutatis
sh purge.sh trusty belenos
echo DONE
}

savelog logs/update.log
doall 2>&1 | tee logs/update.log
