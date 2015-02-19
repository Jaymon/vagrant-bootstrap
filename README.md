# Vagrant Bootstrap

here would be some notes about getting the basebox ready to the point where you can run these scripts.

get the first part of the instructions from this site

http://www.sitepoint.com/create-share-vagrant-base-box/

    When prompted to enter the hostname, type vagrant
    For both the username and password also type vagrant
    Encrypt your home directory? Select No
    On the timezone panel, select UTC or your own preferred timezone
    Partitioning method: Guided – use entire disk and set up LVM
    When prompted which software to install, select OpenSSH server, the rest such as LAMP or MySQL will be installed later
    Select to install GRUB boot loader on the master boot record

and reboot

    sudo reboot

here would be the curl command to download the bootstrap script

When you are ready to run this script, you can just run these commands:

    wget https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vagrant-bootstrap.sh
    chmod 755 vagrant-boostrap.sh
    sudo ./vagrant-bootsrap.sh

If you are going to export some variables like `$MOTD` or `$VBOX_VERSION` then you can run the script like this:

    export MOTD="I want this to be my message instead"
    sudo -E ./vagrant-bootstrap.sh

After you have ran the script, you can package it up:

    VboxManage list vms
    vagrant package --base "<NAME OF BOX>"

And then import it into Vagrant:

    vagrant box add --name <BOX NAME> /PATH/TO/package.box


see also:
https://docs.vagrantup.com/v2/boxes/base.html
https://docs.vagrantup.com/v2/virtualbox/boxes.html

Virtualbox shared folders:
https://help.ubuntu.com/community/VirtualBox/SharedFolders
