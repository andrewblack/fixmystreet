#!/bin/sh

# Set this to the version we want to check out
VERSION=v1.2.2

PARENT_SCRIPT_URL=https://github.com/mysociety/commonlib/blob/master/bin/install-site.sh

misuse() {
  echo The variable $1 was not defined, and it should be.
  echo This script should not be run directly - instead, please run:
  echo   $PARENT_SCRIPT_URL
  exit 1
}

# Strictly speaking we don't need to check all of these, but it might
# catch some errors made when changing install-site.sh

[ -z "$DIRECTORY" ] && misuse DIRECTORY
[ -z "$UNIX_USER" ] && misuse UNIX_USER
[ -z "$REPOSITORY" ] && misuse REPOSITORY
[ -z "$REPOSITORY_URL" ] && misuse REPOSITORY_URL
[ -z "$BRANCH" ] && misuse BRANCH
[ -z "$SITE" ] && misuse SITE
[ -z "$DEFAULT_SERVER" ] && misuse DEFAULT_SERVER
[ -z "$HOST" ] && misuse HOST
[ -z "$DISTRIBUTION" ] && misuse DISTRIBUTION
[ -z "$VERSION" ] && misuse VERSION

install_nginx

install_postfix

# Check out the current released version
su -l -c "cd '$REPOSITORY' && git checkout '$VERSION'" "$UNIX_USER"

install_website_packages

su -l -c "touch '$DIRECTORY/admin-htpasswd'" "$UNIX_USER"

add_website_to_nginx

add_postgresql_user

su -l -c "$REPOSITORY/bin/install-as-user '$UNIX_USER' '$HOST' '$DIRECTORY'" "$UNIX_USER"

install_sysvinit_script

if [ $DEFAULT_SERVER = true ] && [ x != x$EC2_HOSTNAME ]
then
    # If we're setting up as the default on an EC2 instance,
    # make sure the ec2-rewrite-conf script is called from
    # /etc/rc.local
    overwrite_rc_local
fi

# Tell the user what to do next:

echo Installation complete - you should now be able to view the site at:
echo   http://$HOST/
echo Or you can run the tests by switching to the "'$UNIX_USER'" user and
echo running: $REPOSITORY/bin/cron-wrapper prove -r t
