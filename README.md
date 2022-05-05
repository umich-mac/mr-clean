# Home Directory Reaper for Classrooms

This login-logout hook pair and launch agent help manage the disk space in various computing classrooms on campus, by deleting older home directories when the system starts running out of space.

## Theory of Operation

* Out of the box, this uses a login/logout hook pair that we run under a hook "master" script. You can use some other strategy depending on your environment.

* Configure max time-to-keep and a disk size threshold in `/etc/homedir.defaults` (and a per-machine override file, `/etc/homedir.defaults.local`)

* The main script, `HomeDirReaper.sh`, calls two helpers, `list-local-users` and `home-directory-for-user`. We have these on all our systems with our other tools; I've provide x86 binaries in the `bin` folder. Source for both will be on GitHub ASAP.


### Building for Munki

This should be sufficient:

1. Install ruby - rbenv and ruby-build are handy.
1. `bundle install`
1. `bundle exec ./build-munki-dmg.rb`
1. You will have a `UserHomeDirManagement-numbers.plist` and `.dmg` ready to deploy.

### Building a Package

1. `make`
1. You will end up with a `UserHomeDirManagement.pkg` to deploy.


### Other stuff

* `preinstall.sh`: Older versions of this tool would move directories in to and out from a folder named `/Users/.old`, but this has caused a number of issues, including a dock that is missing all its icons.  The current version instead hides and unhides the user's directory, rather than moving it around.
* `Gemfile` and `Gemfile.lock` are used by Ruby `bundler`.
