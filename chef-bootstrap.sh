#!/usr/bin/env bash
###############################################################################
# Install chef solo if it hasn't already been installed
#
# this is handy to take vanilla boxes to a box capable of being provisioned with Chef-solo
###############################################################################
#version=11.12.4
#version=12.0.3
version=12.7.2
if [[ -n $1 ]]; then
  version=$1
fi

#which chef-solo || wget -qO- https://www.opscode.com/chef/install.sh | sudo bash
chef-solo --version 2>/dev/null | grep "$version" || wget -qO- https://www.opscode.com/chef/install.sh | sudo bash /dev/stdin -v "$version"

