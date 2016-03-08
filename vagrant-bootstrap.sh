#!/bin/bash
###############################################################################
# This script is designed to bootstrap a vagrant box from a plain vanilla Ubuntu
# install, You can pass in the user you want to use when calling the script:
#
#    $ ./vagrant-bootstrap.sh 
#
# It is ripped off from Vagrant's postinstall.sh script that was leftover in the
# default Vagrant 12.04 box that Hashicorp put out
###############################################################################

###############################################################################
# Setup script variables
###############################################################################
account="vagrant"

# Enable truly non interactive apt-get installs
# https://www.debian.org/releases/sarge/alpha/ch05s02.html.en
export DEBIAN_FRONTEND=noninteractive

# Determine the platform (i.e. Debian or Ubuntu) and platform version
platform="$(lsb_release -i -s)"
platform_version="$(lsb_release -s -r)"

# Run the script in debug mode
#set -x


###############################################################################
# Passwordless sudo and root access
###############################################################################
# The main user (`$account` in our case) needs to have **password-less** sudo
# This user belongs to the `admin`/`sudo` group, so we'll change that line.
is_exempt=$(grep -qe '^Defaults\s\+exempt_group=admin$' /etc/sudoers; echo $?)
if [[ $is_exempt -eq 1 ]]; then
  echo "exempting admin group from defaults"
  sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
fi

echo "adding $account to admin group and making admin have passwordless sudo"
groupadd -r admin || true
usermod -a -G admin $account
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=(ALL:ALL) NOPASSWD:ALL/g' /etc/sudoers


# you could also approach this using expect http://unix.stackexchange.com/a/21717
apt-get -y install whois
set_root_passwd=0
root_plaintext_passwd=$account
root_shadow=$(grep -e "^root:" /etc/shadow)
root_orig_passwd_hash=$(echo $root_shadow | cut -d: -f2)
if [[ $root_orig_passwd_hash != "*" ]]; then
  root_method=$(echo $root_shadow | cut -d$ -f2)
  root_salt=$(echo $root_shadow | cut -d$ -f3)
  root_orig_passwd=$(echo $root_shadow | cut -d$ -f4)

  # these are from man crypt 3, there is a mkpasswd -m help but it doesn't include the
  # numbers and isn't guarranteed to be there :(
  declare -A methods=( ["1"]="md5" ["2"]="Blowfish" ["2a"]="Blowfish" ["5"]="SHA-256" ["6"]="SHA-512" )

  root_passwd_hash=$(mkpasswd --method="${methods["$root_method"]}" --salt="$root_salt" "$root_plaintext_passwd")

  if [[ $root_orig_passwd_hash == $root_passwd_hash ]]; then
    echo "root password has already been changed to $account"
  else
    set_root_passwd=1
  fi
else
  set_root_passwd=1
fi

if [[ $set_root_passwd -eq 1 ]]; then

  echo "Set the root password to \"${account}\" at the prompt"

  export DEBIAN_FRONTEND=newt
  passwd root
  export DEBIAN_FRONTEND=noninteractive

fi


###############################################################################
# Get rid of annoyances and extraneous error messages
###############################################################################

echo "remove \"stdin is not a tty\" error message"
sed -i 's/^mesg n$//g' /root/.profile

echo "set locale to en_US"
# http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
# Set the LC_CTYPE so that auto-completion works and such.

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF_8 en_US.UTF-8
dpkg-reconfigure locales
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
#echo -e "LC_ALL=\"en_US.UTF-8\"\nLANG=\"en_US.UTF-8\"" > /etc/default/locale


###############################################################################
# setup vagrant ssh keys
###############################################################################

# Since Vagrant only supports key-based authentication for SSH, we must
# set up the vagrant user to use key-based authentication. We can get the
# public key used by the Vagrant gem directly from its Github repository.
echo "fetching unsecured vagrant public key for key based ssh"
vssh="/home/${account}/.ssh"
mkdir -p $vssh
chmod 700 $vssh
(cd $vssh &&
  wget --no-check-certificate \
    'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub' \
    -O $vssh/authorized_keys)
chmod 0600 $vssh/authorized_keys
chown -R ${account}:vagrant $vssh
unset vssh


###############################################################################
# Misc tweaks
###############################################################################

is_dns_ignored=$(grep -q '^UseDNS' /etc/ssh/sshd_config; echo $?)
if [[ $is_dns_ignored -eq 1 ]]; then
  echo "Tweak sshd to prevent DNS resolution (speed up logins)"
  echo 'UseDNS no' >> /etc/ssh/sshd_config
fi

echo "customize the message of the day"
if [[ -z "$MOTD" ]]; then
  echo "If you would like to customize the message of the day, set MOTD env variable"
  MOTD='Welcome to your Vagrant box.'
fi
echo -e "###############################################################################\n# ${MOTD}\n###############################################################################" > /etc/motd.tail

motd_file="/etc/update-motd.d/99-footer"
if [[ ! -f $motd_file ]]; then
  echo "Adding file for motd: $motd_file"
  echo -e "#!/bin/sh\n[ -f /etc/motd.tail ] && cat /etc/motd.tail || true" > $motd_file
  chmod 755 $motd_file
fi

# Record when the basebox was built
date > /etc/bootstrap_date


###############################################################################
# Install guest additions
###############################################################################
if [[ -f vbox-bootstrap.sh ]]; then
  ./vbox-bootstrap.sh 
fi


###############################################################################
# Clean up
###############################################################################
echo "Cleaning up packages, files, temp, and log files"

# Remove the build tools to keep things pristine
apt-get -y remove --purge --auto-remove make
apt-get -y remove --purge --auto-remove curl
apt-get -y remove --purge --auto-remove git-core
apt-get -y remove --purge --auto-remove whois

apt-get -y autoclean
apt-get -y clean
apt-get -y autoremove

# Removing leftover leases and persistent rules
rm -f /var/lib/dhcp3/*

# Make sure Udev doesn't block our network, see: http://6.ptmc.org/?p=164
rm -rf /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Remove any temporary work files
#rm -f /home/${account}/{*.iso,*bootstrap.sh}
rm -f /home/${account}/*.iso

# clear temp
rm -rf /tmp/*

# clear all logs
IFS=$'\n'
log_files=( $(find /var/log -type f) )
unset IFS
for i in "${!log_files[@]}"; do
  cat /dev/null > ${log_files[i]}
done

# remove extraneous man pages in other languages
# https://wiki.debian.org/ReduceDebian
rm -rf /usr/share/man/??
rm -rf /usr/share/man/??_*


###############################################################################
# Compress Image Size
###############################################################################

echo "Zero out the free space to save space in the final image"
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# leave no trace
rm /home/${account}/.bash_history
rm "$(echo ${BASH_SOURCE[0]} | sed 's|^./||')"

echo "You might want to run \"sudo reboot\" one last time before packaging this box"
exit

# And we're done.

