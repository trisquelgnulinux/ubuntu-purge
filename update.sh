#!/bin/sh
#
#    Copyright (C) 2008-2021  Ruben Rodriguez <ruben@gnu.org>
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

cd /home/ubuntu
set -e

echo Started on $(date)

echo Self updating from git...
git --git-dir=/home/ubuntu/.git pull

repexit(){
    echo WARNING: reprepro ended unexpectedly
    echo Do NOT update any leaf repositories from here until it is fixed
    echo "Error during update at $(date)" > ERROR
    exit 1
}

echo "Locking during repo update at $(date)" > ERROR

echo Updating ubuntu mirrors...
reprepro --noskipold -v -b . predelete || repexit
reprepro --noskipold -v -b . update || repexit

echo Removing non free packages...
sh purge.sh xenial flidas
sh purge.sh bionic etiona
sh purge.sh focal nabia

rm ERROR -f
echo DONE at $(date)

