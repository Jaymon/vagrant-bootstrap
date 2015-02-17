#!/bin/bash
###############################################################################
# This script is designed to bootstrap a vagrant box from a plain vanilla Ubuntu
# install, You can pass in the user you want to use when calling the script:
#
#    $ ./vagrant-bootstrap.sh VIRTUALBOX_VERSION
#
# It is ripped off from Vagrant's postinstall.sh script that was leftover in the
# default Vagrant 12.04 box that Hashicorp put out
###############################################################################

###############################################################################
# Setup script variables
###############################################################################
account="vagrant"
# you can find out what version your virtualbox is by running VBoxManage --version
# and then taking everything from the left of the r (eg 4.3.20r96996 should be 4.3.20)
vbox_version="$1"

# Enable truly non interactive apt-get installs
export DEBIAN_FRONTEND=noninteractive

# Determine the platform (i.e. Debian or Ubuntu) and platform version
platform="$(lsb_release -i -s)"
platform_version="$(lsb_release -s -r)"

# Run the script in debug mode
set -x


###############################################################################
# Passwordless sudo
###############################################################################
# The main user (`$account` in our case) needs to have **password-less** sudo
# This user belongs to the `admin`/`sudo` group, so we'll change that line.
if [[ -z "grep -e '^Defaults\s\+exempt_group=admin$' /etc/sudoers" ]]; then
  sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
fi

groupadd -r admin || true
usermod -a -G admin $account
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=(ALL) NOPASSWD:ALL/g' /etc/sudoers


###############################################################################
# Get rid of annoyances and extraneous error messages
###############################################################################

# remove "stdin is not a tty" error message
sed -i 's/^mesg n$//g' /root/.profile

# http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
# Set the LC_CTYPE so that auto-completion works and such.
#echo "LC_ALL=\"en_US\"" > /etc/default/locale

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales


###############################################################################
# setup vagrant ssh keys
###############################################################################

# Since Vagrant only supports key-based authentication for SSH, we must
# set up the vagrant user to use key-based authentication. We can get the
# public key used by the Vagrant gem directly from its Github repository.
vssh="/home/${account}/.ssh"
mkdir -p $vssh
chmod 700 $vssh
(cd $vssh &&
  wget --no-check-certificate \
    'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' \
    -O $vssh/authorized_keys)
chmod 0600 $vssh/authorized_keys
chown -R ${account}:vagrant $vssh
unset vssh


###############################################################################
# Misc tweaks
###############################################################################

# Tweak sshd to prevent DNS resolution (speed up logins)
if [[ -z "grep '^UseDNS' /etc/ssh/sshd_config" ]]; then
  echo 'UseDNS no' >> /etc/ssh/sshd_config
fi

# customize the message of the day
if [[ -n "$MOTD" ]]; then
  echo $MOTD > /etc/motd.tail
else
  echo 'Welcome to your Vagrant box.' > /etc/motd.tail
fi

# Record when the basebox was built
date > /etc/bootstrap_date


###############################################################################
# Install guest additions
###############################################################################
if [[ -n "$vbox_version" ]]; then
  apt-get install linux-headers-generic build-essential dkms
  cd /tmp
  wget 'http://download.virtualbox.org/virtualbox/${vbox_version}/VBoxGuestAdditions_${vbox_version}.iso'
  mkdir -p /media/VBoxGuestAdditions
  mount -o loop,ro VBoxGuestAdditions_${vbox_version}.iso /media/VBoxGuestAdditions
  sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
  rm VBoxGuestAdditions_${vbox_version}.iso
  umount /media/VBoxGuestAdditions
  rmdir /media/VBoxGuestAdditions
fi


###############################################################################
# Clean up
###############################################################################

# Remove the linux headers to keep things pristine
apt-get -y remove linux-headers-$(uname -r)
apt-get -y remove linux-headers-generic build-essential dkms

# Remove the build tools to keep things pristine
apt-get -y remove make curl git-core

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


###############################################################################
# Compress Image Size
###############################################################################

# clear temp
rm -rf /tmp/*

# clear all logs
IFS=$'\n'
log_files=( $(find /var/log -type f) )
unset IFS
for i in "${!log_files[@]}"; do
  cat /dev/null > ${log_files[i]}
done

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# leave no trace
rm /home/${account}/.bash_history
rm "${BASH_SOURCE[0]}"

exit

# And we're done.

