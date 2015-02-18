# Vagrant Bootstrap

here would be some notes about getting the basebox ready to the point where you can run these scripts.


    sudo reboot

here would be the curl command to download the bootstrap script

When you are ready to run this script, you can just run these commands:

    wget https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vagrant-bootstrap.sh
    chmod 755 vagrant-boostrap.sh
    sudo ./vagrant-bootsrap.sh

If you are going to export some variables like `$MOTD` or `$VBOX_VERSION` then you can run the script like this:

    export MOTD="I want this to be my message instead"
    sudo -E ./vagrant-bootstrap.sh

