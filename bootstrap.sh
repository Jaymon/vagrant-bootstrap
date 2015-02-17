#!/bin/bash
##
# This script is designed to bootstrap a chef box from a plain vanilla 12.04 Ubuntu
# install, You can pass in the user you want to use when calling the script:
#
#    $ ./bootstrap.sh USERNAME
#
# It is ripped off from Vagrant's postinstall.sh script that was leftover in the
# default Vagrant 12.04 box the Hashicorp put out
##

# **bootstrap.sh** is a script executed after Debian/Ubuntu has been
# installed and restarted. There is no user interaction so all commands must
# be able to run in a non-interactive mode.
#
# If any package install time questions need to be set, you can use
# `preeseed.cfg` to populate the settings.

### Setup Variables

# The non-root user that will be created.
if [ -z "$1" ]; then
  print "must pass in USERNAME you want to create"
  exit
fi
account="$1"

# Enable truly non interactive apt-get installs
export DEBIAN_FRONTEND=noninteractive

# Determine the platform (i.e. Debian or Ubuntu) and platform version
platform="$(lsb_release -i -s)"
platform_version="$(lsb_release -s -r)"

# Run the script in debug mode
set -x

### Customize Sudoers

# The main user (`$account` in our case) needs to have **password-less** sudo
# This user belongs to the `admin`/`sudo` group, so we'll change that line.
# TODO: only run this if the line Defaults exempt_group=admin doesn't already exist
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
case "$platform" in
  Debian)
      sed -i -e 's/%sudo ALL=(ALL) ALL/%sudo ALL=(ALL) NOPASSWD:ALL/g' /etc/sudoers
    ;;
  Ubuntu)
    groupadd -r admin || true
    usermod -a -G admin $account
    sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=(ALL) NOPASSWD:ALL/g' /etc/sudoers
    ;;
esac

### Other setup

# Set the LC_CTYPE so that auto-completion works and such.
echo "LC_ALL=\"en_US\"" > /etc/default/locale

### Vagrant SSH Keys

# Since Vagrant only supports key-based authentication for SSH, we must
# set up the vagrant user to use key-based authentication. We can get the
# public key used by the Vagrant gem directly from its Github repository.
#vssh="/home/${account}/.ssh"
#mkdir -p $vssh
#chmod 700 $vssh
#(cd $vssh &&
#  wget --no-check-certificate \
#    'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' \
#    -O $vssh/authorized_keys)
#chmod 0600 $vssh/authorized_keys
#chown -R ${account}:vagrant $vssh
#unset vssh

# Remove the linux headers to keep things pristine
apt-get -y remove linux-headers-$(uname -r)

### Misc. Tweaks

# Tweak sshd to prevent DNS resolution (speed up logins)
echo 'UseDNS no' >> /etc/ssh/sshd_config

# Customize the message of the day
case "$platform" in
  Debian)
    echo 'Welcome to your First Opinion virtual machine.' > /var/run/motd
    ;;
  Ubuntu)
    echo 'Welcome to your First Opinion virtual machine.' > /etc/motd.tail
    ;;
esac

# Record when the basebox was built
date > /etc/bootstrap_date

### Clean up

# Remove the build tools to keep things pristine
apt-get -y remove build-essential make curl git-core

apt-get -y autoremove
apt-get -y clean

# Removing leftover leases and persistent rules
rm -f /var/lib/dhcp3/*

# Make sure Udev doesn't block our network, see: http://6.ptmc.org/?p=164
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Remove any temporary work files, including the postinstall.sh script
rm -f /home/${account}/{*.iso,bootstrap*.sh}

### Compress Image Size

# get rid of gemdocs
rm -rf "$(${ruby_home}/bin/gem env gemdir)"/doc/*

# clear temp
rm -rf /tmp/*

# clear logs
IFS=$'\n'
log_files=( $(find /var/log -type f) )
unset IFS
for i in "${!log_files[@]}"; do
  cat /dev/null > ${log_files[i]}
done

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

exit

# And we're done.
