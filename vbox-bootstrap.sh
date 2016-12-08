#!/bin/bash

# you can find out what version your virtualbox is by running VBoxManage --version
# and then taking everything from the left of the r (eg 4.3.20r96996 should be 4.3.20)
# http://xmodulo.com/how-to-install-virtualbox-guest-additions-for-linux.html
# http://andrewelkins.com/linux/install-virtualbox-guest-additions-command-line/

# first check for passed in value
if [[ -n $1 ]]; then
  vbox_version=$1
fi

# if passed in value was empty, try for environment variable
if [[ -z "$vbox_version" ]]; then
  vbox_version="$VBOX_VERSION"
fi

# only if we found a vbox version do we run this
if [[ -n "$vbox_version" ]]; then

  # http://www.linuxquestions.org/questions/linux-virtualization-and-cloud-90/how-to-check-version-of-virtualbox-guest-additions-currently-installed-in-guest-syste-946053/
  #installed_vbox_version=$(modinfo vboxguest 2> /dev/null | grep -iw version | cut -d: -f2 | tr -d '[[:space:]]' | cut -dr -f1)
  installed_vbox_version=$(modinfo vboxguest 2> /dev/null | grep -iw version |  tr -s ' ' | cut -d' ' -f2)

  if [[ $vbox_version == $installed_vbox_version ]]; then

    echo "Guest additons $vbox_version already installed"

  else

    echo "Setting up guest additions for virtualbox ${vbox_version}"

    export DEBIAN_FRONTEND=noninteractive

    remove_v_headers=$(dpkg -s linux-headers-$(uname -r) > /dev/null 2>&1;echo $?)
    remove_generic_headers=$(dpkg -s linux-headers-generic > /dev/null 2>&1;echo $?)
    remove_build_essential=$(dpkg -s build-essential > /dev/null 2>&1;echo $?)
    remove_dkms=$(dpkg -s dkms > /dev/null 2>&1;echo $?)
    remove_gcc=$(dpkg -s gcc > /dev/null 2>&1;echo $?)

    set -e
    set -o pipefail

    apt-get update
    apt-get -y install --no-install-recommends linux-headers-$(uname -r) linux-headers-generic build-essential dkms gcc
    cd /tmp
    wget "http://download.virtualbox.org/virtualbox/${vbox_version}/VBoxGuestAdditions_${vbox_version}.iso"
    mount -o loop,ro VBoxGuestAdditions_${vbox_version}.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run
    rm VBoxGuestAdditions_${vbox_version}.iso
    umount /mnt

    set +e
    set +o pipefail

    if lsmod | grep -q vbox; then

      # Remove the linux headers to keep things pristine
      if [[ $remove_v_headers -eq 1 ]]; then
        apt-get -y remove --purge --auto-remove linux-headers-$(uname -r)
      fi

      if [[ $remove_generic_headers -eq 1 ]]; then
        apt-get -y remove --purge --auto-remove linux-headers-generic
      fi

      if [[ $remove_build_essential -eq 1 ]]; then
        apt-get -y remove --purge --auto-remove build-essential
      fi

      if [[ $remove_gcc -eq 1 ]]; then
        apt-get -y remove --purge --auto-remove gcc
      fi

      if [[ $remove_dkms -eq 1 ]]; then
        rm -rf /var/lib/dkms/*
        apt-get -y remove --purge --auto-remove dkms
      fi

    else

      echo "WARNING: GUEST ADDITIONS ARE NOT INSTALLED CORRECTLY"

    fi

  fi

else

  echo "if you want to setup guest additions, set VBOX_VERSION env variable"

fi


