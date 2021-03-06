#!/bin/bash
#-------------------------------------------------------------------------------
# (C) British Crown Copyright 2006-16 Met Office.
#
# This file is part of FCM, tools for managing and building source code.
#
# FCM is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# FCM is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FCM. If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------
# Basic tests for "fcm-add-trac-env".
#-------------------------------------------------------------------------------
. $(dirname $0)/test_header
#-------------------------------------------------------------------------------
if ! which trac-admin 1>/dev/null 2>/dev/null; then
    skip_all 'trac-admin not available'
fi
tests 20
#-------------------------------------------------------------------------------
set -e
mkdir -p etc srv/{svn,trac}
# Configuration
export FCM_CONF_PATH="$PWD/etc"
ADMIN_USERS='holly ivy'
cat >etc/admin.cfg <<__CONF__
svn_live_dir=$PWD/srv/svn
trac_admin_users=$ADMIN_USERS
trac_live_dir=$PWD/srv/trac
__CONF__
# Create some Subversion repositories
for NAME in bus lorry taxi; do
    svnadmin create "srv/svn/$NAME"
done
set +e
#-------------------------------------------------------------------------------
for NAME in bus car lorry taxi; do
    TEST_KEY="$TEST_KEY_BASE-$NAME"
    # Command OK
    run_pass "$TEST_KEY" "$FCM_HOME/sbin/fcm-add-trac-env" "$NAME"
    # Trac environment directory exists
    run_pass "$TEST_KEY-d" test -d "$PWD/srv/trac/$NAME"
    # Admin users are set
    for ADMIN_USER in $ADMIN_USERS; do
        trac-admin "$PWD/srv/trac/$NAME" permission list "$ADMIN_USER" \
            >"$TEST_KEY.perm.out"
        file_grep "$TEST_KEY.perm.out" \
            "$ADMIN_USER  *TRAC_ADMIN" "$TEST_KEY.perm.out"
    done
    # Subversion repository paths in place
    if [[ -d "srv/svn/$NAME" ]]; then
        file_grep "$TEST_KEY-repository_dir" \
            "repository_dir=$PWD/srv/svn/$NAME" \
            "$PWD/srv/trac/$NAME/conf/trac.ini"
    fi
done

TEST_KEY="$TEST_KEY_BASE-intertrac"
file_cmp "$TEST_KEY" "$PWD/srv/trac/intertrac.ini" <<'__CONF__'
[intertrac]
bus.title=bus
bus.url=https://localhost/trac/bus
bus.compat=false
car.title=car
car.url=https://localhost/trac/car
car.compat=false
lorry.title=lorry
lorry.url=https://localhost/trac/lorry
lorry.compat=false
taxi.title=taxi
taxi.url=https://localhost/trac/taxi
taxi.compat=false
__CONF__
#-------------------------------------------------------------------------------
exit
