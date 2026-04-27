#!/bin/bash

# Release Sandstorm wekan.

# 1) Check that there is only one parameter
#    of Sandstorm wekan version number:

if [ $# -ne 1 ]
  then
    echo "Syntax with new Sandstorm wekan version number:"
    echo "  ./release-sandstorm.sh 5.10.0"
    exit 1
fi

# Ensure sudo access
sudo echo .

# Delete old temporary build directory
rm -rf ~/repos/wekan/.meteor-spk

# Start and update local Sandstorm dev version
sudo systemctl enable sandstorm
sudo sandstorm start
sudo sandstorm update

# Build Sandstorm wekan
cd ~/repos/wekan
meteor-spk pack wekan-$1.spk

# Publish Sandstorm wekan to exprimental App Market
spk publish wekan-$1.spk

# Upload spk to https://releases.wekan.team/sandstorm/
scp wekan-$1.spk x2:/data/websites/releases.wekan.team/dev/sandstorm/

# Delete old temporary build directory
rm -rf ~/repos/wekan/.meteor-spk
