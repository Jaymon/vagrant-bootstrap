# Vagrant Bootstrap

These are just some handy scripts that remove the tedium of building new Vagrant Ubuntu base boxes. They are inspired and based off a `postinstall.sh` script I found in one of the baseboxes back in the day. We've used this to build Ubuntu 12.04 and 14.04 boxes.


## Create the box

### Creating the box in Virtualbox

Choose the `vmdk` hard drive type, make it grow dynamically to about 80gb. Once in the Manager, right click on your box and choose settings.

Under System, on the Motherboard tab, change the Pointing Device to `PS/2 Mouse`. On the Processor tab, select 2 CPUs, and make Execution Cap to 100%, and enable PAE/NX. Make sure VT-x/AMD-V and Nested Paging is enabled in Acceleration.

Under Audio, uncheck Enable Audio.

Under Ports, basically uncheck every Enable..., because you won't need Serial Ports or USB.

That's pretty much everything, now you should be able to click start.

You should be able to load your Ubuntu download iso image and use that to install the OS.


### During the installation

Get the first part of the instructions from this [tutorial](http://www.sitepoint.com/create-share-vagrant-base-box/).

    When prompted to enter the hostname, type vagrant
    For both the username and password also type vagrant
    Encrypt your home directory? Select No
    On the timezone panel, select UTC or your own preferred timezone
    Partitioning method: Guided – use entire disk and set up LVM
    When prompted which software to install, select OpenSSH server, the rest such as LAMP or MySQL will be installed later
    Select to install GRUB boot loader on the master boot record


### After the OS installation

Power down the box completely, then click settings again.

Under System, unclick CD/DVD.

Under Storage, get rid of the CD-ROM drive, you won't need it anymore.

Now you can start the box.


### After logging into box

You can just run these commands:

    wget https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vagrant-bootstrap.sh
    wget https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vbox-bootstrap.sh
    chmod 755 *-bootstrap.sh
    sudo ./vagrant-bootstrap.sh

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

```ruby
config.vm.provision :shell, :path => ::File.join("PATH", "TO", "chef-bootstrap.sh")
```

You can also be even more automatic in your `Vagrantfile` if you want by replacing the above shell provisioner with this:

```ruby
require 'tmpdir'
require 'open-uri'
chef_version = "12.7.2"
chef_bootstrap = ::File.join(::Dir.tmpdir, "chef-bootstrap-#{chef_version}.sh")
if !::File.exists?(chef_bootstrap)
  download = open('https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/chef-bootstrap.sh')
  ::IO.copy_stream(download, chef_bootstrap)
end
#config.vm.provision :shell, :path => chef_bootstrap
config.vm.provision "shell" do |s|
  s.path = chef_bootstrap
  s.args = [chef_version]
end
```

The chef script is smart enough to only install chef on the very first provision, or when you change the chef version.

**NOTE** -- Vagrant has this built-in now by setting the [chef.version value](https://www.vagrantup.com/docs/provisioning/chef_common.html#version):

```ruby
config.vm.provision :chef_solo do |chef|

  chef.version = "CHEF_VERSION"

end
```

The `chef-bootstrap` script is still really handy though, we use it to install chef on new production boxes.


### Finding latest 

Also, if you are curious what is the latest version of Chef, you can use curl:

    $ curl -v "https://omnitruck-direct.chef.io/stable/chef/metadata?v=12&p=ubuntu&pv=14.04&m=x86_64"

Here is what Chef says:

> In order to test the version parameter, adventurous users may take the Metadata URL below and modify the '&v=<number>' parameter until you successfully get a URL that does not 404 (e.g. via curl or wget). You should be able to use '&v=11' or '&v=12' successfully.

That will redirect you to the latest version, the bottom lines in the curl output should be something like:

> url	https://packages.chef.io/stable/ubuntu/14.04/chef_12.13.37-1_amd64.deb
> version	12.13.37

So you know `12.13.37` on the 12 branch is the latest version, and you can update your version accordingly.


## Virtualbox Guest Additions

You can find out what version your virtualbox is by running `VBoxManage --version` and then taking everything from the left of the r (eg 4.3.20r96996 should be 4.3.20).

Then ssh into your Vagrant box and run:

    $ wget https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vbox-bootstrap.sh
    $ chmod 755 vbox-bootstrap.sh
    $ sudo ./vbox-bootstrap.sh VERSION

So if your version was `.4.3.20` you would run:

    $ sudo ./vbox-bootstrap.sh "4.3.20"

If you would like you vagrant box to automatically update the guest additions when you upgrade Virtualbox, put this in your Vagrantfile:

```ruby
# update virtualbox guest additions if needed
require 'tmpdir'
require 'open-uri'
vbox_version = `VboxManage --version`.chomp.split("r", 2)[0]
vbox_bootstrap = ::File.join(::Dir.tmpdir, "vbox-bootstrap-#{vbox_version}.sh")
if !::File.exists?(vbox_bootstrap)
  download = open('https://raw.githubusercontent.com/Jaymon/vagrant-bootstrap/master/vbox-bootstrap.sh')
  ::IO.copy_stream(download, vbox_bootstrap)
end
config.vm.provision "shell", run: "always" do |s|
  s.path = vbox_bootstrap
  s.args = [vbox_version]
end
```


## Other

see also:
https://docs.vagrantup.com/v2/boxes/base.html
https://docs.vagrantup.com/v2/virtualbox/boxes.html

Virtualbox shared folders:
https://help.ubuntu.com/community/VirtualBox/SharedFolders

Hashicorp now has their own boxes:
https://atlas.hashicorp.com/ubuntu/boxes/trusty64

