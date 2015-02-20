# Vagrant Bootstrap

This is just a handy script that removes the tedium of building a new Vagrant Ubuntu base box. It is based off a `postinstall.sh` script I found in one of the baseboxes back in the day.

## Create the box

Get the first part of the instructions from this [tutorial](http://www.sitepoint.com/create-share-vagrant-base-box/).

    When prompted to enter the hostname, type vagrant
    For both the username and password also type vagrant
    Encrypt your home directory? Select No
    On the timezone panel, select UTC or your own preferred timezone
    Partitioning method: Guided – use entire disk and set up LVM
    When prompted which software to install, select OpenSSH server, the rest such as LAMP or MySQL will be installed later
    Select to install GRUB boot loader on the master boot record

When you are ready to run this script, you can just run these commands:

    wget https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vagrant-bootstrap.sh
    chmod 755 vagrant-boostrap.sh
    sudo ./vagrant-bootsrap.sh

You can also customize the script a bit with some environment variables:

`$MOTD` - The message of the day, this will show up every time you ssh into the box.

`$VBOX_VERSION` - Set this to your version of Virtualbox if you want the box to install the Virtualbox guest additions.

If you are going to export some variables like `$MOTD` or `$VBOX_VERSION` then you can run the script like this:

    export MOTD="I want this to be my login message instead"
    export VBOX_VERSION="4.3.20"
    sudo -E ./vagrant-bootstrap.sh

and reboot after the script is done running:

    sudo reboot

## Package the box for Vagrant

package up the box for Vagrant:

    VboxManage list vms
    vagrant package --base "<NAME OF BOX>"

And then import it into Vagrant:

    vagrant box add --name <BOX NAME> /PATH/TO/package.box

## Chef

You can use the included `chef-bootstrap.sh` script to make sure Chef is installed on the box by putting this line in your `Vagrantfile` before your chef provisioning code:

    config.vm.provision :shell, :path => ::File.join("PATH", "TO", "chef-bootstrap.sh")

The chef script is smart enough to only install chef on the very first provision, or when you want to upgrade the chef version.

## Other

see also:
https://docs.vagrantup.com/v2/boxes/base.html
https://docs.vagrantup.com/v2/virtualbox/boxes.html

Virtualbox shared folders:
https://help.ubuntu.com/community/VirtualBox/SharedFolders

