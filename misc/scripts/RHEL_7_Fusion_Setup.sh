#!/bin/bash

#
# Take a fresh RHEL/CentOS 7 image and get it running Lucidworks Fusion!
# This script will update linux, install Java, create a service account, and get Fusion ready to bootstrap. It also requires full sudo privileges.
# 
# Using AWS? We sugget EBS. Change use_ebs_drive to 1 to use additional volumes for drive storage in AWS, which should increase performance dramatically
# Support for other CSP's can be added later.
use_ebs_drive=0

#
# Update local RHEL image
#
sudo yum -y update
sudo yum -y install wget nc unzip
sudo yum -y install vim

#
# Install Java 8
# Use the RPM method....
#
JDK_URL="http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "$JDK_URL" -O "jdk.rpm"
if [ ! -s $filename ]; then
  echo "Could not download java, you may need to setup http_proxy and https_proxy environment variables."
  exit -1
fi
sudo rpm -Uvh jdk.rpm
sudo alternatives --install /usr/bin/java java /usr/java/latest/bin/java 2

# Setup JAVA_HOME
export JAVA_HOME=/usr/java/latest
echo export JAVA_HOME=/usr/java/latest >>~/.bash_profile

# Setup JRE_HOME
export JRE_HOME=$JAVA_HOME/jre
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
echo export PATH=\$JAVA_HOME/bin:\$JRE_HOME/bin:\$PATH >>~/.bash_profile

# delete downloaded JDK
which java && java -version && rm -f jdk.rpm

#
# Setup local user, "lucidworks"
#
sudo adduser lucidworks
sudo su lucidworks -c "mkdir -p ~/.ssh/"
# Add a public key for the lucidworks user...
sudo su lucidworks -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFdl6bk6Gq3fM2cdR7yeYGcJGLCKFUtVVA6ms2gVVutzdQ95VKf/nwhglvxBstF/YZBbzSqA/h9ebEdmvk5xkHqrEl20HDt3MbatO+yW57yyTANnQEghA3Wm8BYgjTpRWY6cemk8jXFSDG4GO1eNMSaQCL8TeHkNleEH8rhODRvRLXslSAC6n6hXbrb6OrIU/MpcOdhtgZBTE+LcLf6nXEczlnS38LsDdSuCxd+N1swsbpsRYg5jodmLZ1bgBqyHdKsCjHQoo7lUrFC3jG5B9G7AZ2Wc3xBeKxS+rk1zVtLMF98SOI7Kjv2imfKrnXuxAkT7u0p7eBHosWq4W5ftb9qsEEqeL39n9Zm3DicPUXov5VQTAuRe9+pxneUQBwU55FSyqZM94P0T+FhzXBgZtiErtnFnAdHq7CslHLMM7Z16pzsykD8BS40PEvowIH3IaMTpuuIQIIwS67Qz6Dxthl6XUxKbzIBOPEzJVxH3nFC8Ue7hrJCuKfghcAt/Jav1aNX+/tTuoHwcL8cXAUoJKslRyMjxdct+GmMoRORdnViSc4rjI6ZxhQifN3PT4schugBnd4SGhooTcyvEs5UqxD4NzQFrjB7ImQoR89SmbEBqwTYnKKaLiK8cSfn1ydQbP0MJG7iKT6bv/ibfdTiZMuuB7fOdkZPxIfZ0nK6dGo1w==' >>~/.ssh/authorized_keys"
sudo su lucidworks -c "chmod 600 ~/.ssh/authorized_keys "
sudo su lucidworks -c "echo 'cd /opt/lucidworks/fusion' >>~/.bash_profile"
# optionally, set a password for user
# e.g. something like
# echo YourSecretPasswordHere | passwd lucidworks --stdin

#
# Tweak kernel parameters. I.e., set ulimits for the service account named 'lucidworks'
#
# set OS ulimit for max file handles
sudo bash -c 'echo "lucidworks           soft    nofile          63536" >>/etc/security/limits.conf'
sudo bash -c 'echo "lucidworks           hard    nofile          63536" >>/etc/security/limits.conf'
#  set OS ulimit for max processes(threads)
sudo bash -c 'echo "lucidworks           soft    nproc          16384" >>/etc/security/limits.conf'
sudo bash -c 'echo "lucidworks           hard    nproc          16384" >>/etc/security/limits.conf'

dest=/opt/lucidworks
sudo mkdir $dest

# if use drive is > 0
if [ $use_ebs_drive -gt 0 ]; then
  echo "Setting up additional EBS storage volume and mounting"

  #
  # Setup EBS volume
  #
  lsblk
  # for now, hard code the device name
  device=/dev/xvdb
  sudo file -s $device

  # if the partition is already formatted, just quit
  sudo file -s $device | grep -l ": data"
  test $? -gt 0 && echo "Device is already formatted! Exiting." && exit
  if [ $? -gt 0]; then
    echo "Device $device is already formatted! Skipping filesystem creation."
  else
    sudo mkfs -t ext4 $device && sudo mount $device $dest 
    #TODO: make mount changes permanent in fstab
  fi

fi # end use_app_drive statement
sudo chown -R lucidworks:lucidworks $dest
# we have /opt/lucidworks ready to go
echo "Downloading Fusion, which is free to use for up to 30 days. Preety cool, right?"

#
# TODO: Create reg. API call?
#

fusion_file=fusion-3.1.2.tar.gz
sudo -u lucidworks wget -v https://download.lucidworks.com/fusion-3.1.2/$fusion_file -O $dest/$fusion_file
# TODO: check for errors, and a filesize >0, and md5 of file matches...

#TODO
# Optionally, redirect requests to port 80 to localhost:8080 where we would have Fusion App Studio (TwigKit) running
#
#sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
#sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8764

# TODO
# register Fusion as a service for systemctl start/stop/etc.
#

cd $dest 
sudo -u lucidworks tar xvzf $fusion_file
sudo -u lucidworks fusion/latest/bin/fusion start
echo

my_external_ip=`curl -s ident.me`
echo "Enjoy using Lucidworks Fusion! You can bootstrap its admin UI @ http://${my_external_ip}:8764/ and evaluations of Fusion App Studio can be coordinated w/ your Lucidworks technical rep."
