#!/bin/sh

# This script is to be called by the HomeDirReaper launchagent.

# Default declarations, overwritten by /etc/homedir.defaults; this is just here
# to provide some sane values in case the defaults file doesn't exist.
MAXHOMELIFE="8 hours ago"
MAXDISKUSAGE="85"

. /etc/homedir.defaults

remove_user() {
  # Remove a user's home directory and caches.
  OLD_USER="${1}"
  USER_FOLDER=$(/usr/local/izzy/tools/home-directory-for-user ${OLD_USER})

  # Ensure they haven't locked anything in their home folder, then delete it.
  logger -is "Removing home folder ${USER_FOLDER}..."
  chflags -R noschg,nouchg "${USER_FOLDER}"
  rm -rf "${USER_FOLDER}"

  # Cycle through folders looking for what they might own, deleting it.
  logger -is Removing caches for user ${OLD_USER}...
  for cachedir in /private/var/folders \
                  /private/var/tmp \
                  /private/tmp \
                  /Library/Caches
  do
    find "${cachedir}" -user "${OLD_USER}" -delete
  done

  # finally, delete the account info
  dscl . delete "/Users/${OLD_USER}"
}

update_disk_usage() {
  # Sets the variable 'diskusage' to the percent of the disk currently used.
  diskusage=$(df / | sed '/Filesystem/d' | awk '{ print $5 }' | sed 's/%//')
}

# PHASE ONE
# Delete each folder in /Users that's older than the maximum time.
for possibleUser in $(/usr/local/izzy/tools/list-local-users --skip-admins); do

    userDir=$(/usr/local/izzy/tools/home-directory-for-user ${possibleUser})
    if [[ $(find "$userDir" -maxdepth 0 -not -newermt "${MAXHOMELIFE}" -print) ]]; then
        remove_user $possibleUser
    fi
done

# PHASE TWO
# If disk usage is above pre-set limit, delete a random user directory.  Rinse and
# repeat.
update_disk_usage

if [[ ${diskusage} -gt ${MAXDISKUSAGE} ]]; then
  logger -is "Disk usage (${diskusage}\%) exceeds limit of ${MAXDISKUSAGE}\%."
  logger -is "Deleting user directories to make space..."

  while [[ ${diskusage} -gt ${MAXDISKUSAGE} ]]; do
    rando=$(/usr/local/izzy/tools/list-local-users --skip-admins | head -n 1)

    if [[ "x${rando}" == "x" ]]; then
      logger -is "Giving up!"
      exit 0
    fi

    remove_user ${rando}
    update_disk_usage
  done
else
  logger -is "Disk usage does not exceed maximum."
fi

