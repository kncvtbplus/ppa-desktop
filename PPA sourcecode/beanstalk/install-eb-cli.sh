#!/bin/sh
set -e
sudo yum -y install python3
rm -rf ebcli
mkdir -p ebcli
cd ebcli
git clone https://github.com/aws/aws-elastic-beanstalk-cli-setup.git .
pip3 install virtualenv
python3 ./scripts/ebcli_installer.py

