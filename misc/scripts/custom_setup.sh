#!/bin/bash

#
# Take a fresh RHEL/CentOS 7 image and get it running Lucidworks Fusion!
# This script will update linux, install Java, create a service account, and get Fusion ready to bootstrap. It also requires full sudo privileges.
# 

#
# Update local RHEL image
#
sudo yum -y update
sudo yum -y install wget nc unzip
sudo yum -y install vim

# Setup JAVA_HOME
export JAVA_HOME=/usr/java/latest
echo export JAVA_HOME=/usr/java/latest >>~/.bash_profile

# Setup JRE_HOME
export JRE_HOME=$JAVA_HOME/jre
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
echo export PATH=\$JAVA_HOME/bin:\$JRE_HOME/bin:\$PATH >>~/.bash_profile

#
# Setup local user, "lucidworks"
#
sudo adduser lucidworks
sudo su lucidworks -c "mkdir -p ~/.ssh/"
# Add a public key for the lucidworks user...
sudo su lucidworks -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFdl6bk6Gq3fM2cdR7yeYGcJGLCKFUtVVA6ms2gVVutzdQ95VKf/nwhglvxBstF/YZBbzSqA/h9ebEdmvk5xkHqrEl20HDt3MbatO+yW57yyTANnQEghA3Wm8BYgjTpRWY6cemk8jXFSDG4GO1eNMSaQCL8TeHkNleEH8rhODRvRLXslSAC6n6hXbrb6OrIU/MpcOdhtgZBTE+LcLf6nXEczlnS38LsDdSuCxd+N1swsbpsRYg5jodmLZ1bgBqyHdKsCjHQoo7lUrFC3jG5B9G7AZ2Wc3xBeKxS+rk1zVtLMF98SOI7Kjv2imfKrnXuxAkT7u0p7eBHosWq4W5ftb9qsEEqeL39n9Zm3DicPUXov5VQTAuRe9+pxneUQBwU55FSyqZM94P0T+FhzXBgZtiErtnFnAdHq7CslHLMM7Z16pzsykD8BS40PEvowIH3IaMTpuuIQIIwS67Qz6Dxthl6XUxKbzIBOPEzJVxH3nFC8Ue7hrJCuKfghcAt/Jav1aNX+/tTuoHwcL8cXAUoJKslRyMjxdct+GmMoRORdnViSc4rjI6ZxhQifN3PT4schugBnd4SGhooTcyvEs5UqxD4NzQFrjB7ImQoR89SmbEBqwTYnKKaLiK8cSfn1ydQbP0MJG7iKT6bv/ibfdTiZMuuB7fOdkZPxIfZ0nK6dGo1w==' >>~/.ssh/authorized_keys"
sudo su lucidworks -c "chmod 600 ~/.ssh/authorized_keys "
sudo su lucidworks -c "echo 'cd /opt/lucidworks/fusion' >>~/.bash_profile"

#
# Tweak kernel parameters. i.e., set ulimits for the service account named 'lucidworks'
#
# set OS ulimit for max file handles
sudo bash -c 'echo "lucidworks           soft    nofile          63536" >>/etc/security/limits.conf'
sudo bash -c 'echo "lucidworks           hard    nofile          63536" >>/etc/security/limits.conf'
#  set OS ulimit for max processes(threads)
sudo bash -c 'echo "lucidworks           soft    nproc          16384" >>/etc/security/limits.conf'
sudo bash -c 'echo "lucidworks           hard    nproc          16384" >>/etc/security/limits.conf'

dest=/opt/lucidworks
sudo mkdir $dest
sudo chown -R lucidworks:lucidworks $dest
# we have /opt/lucidworks ready to go
echo "Downloading Fusion, which is free to use for up to 30 days. Preety cool, right?"

ver=4.0.2
fusion_file=fusion-$ver.tar.gz
sudo -u lucidworks wget -v https://download.lucidworks.com/fusion-$ver/$fusion_file -O $dest/$fusion_file

#
# Optionally, redirect requests to port 80 to localhost:8080 where we would have Fusion App Studio (TwigKit) running
#
sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8764

my_external_ip=`curl -s ident.me`
echo "You can accses the server via SSH: ssh lucidworks@$my_external_ip"

cd $dest 
sudo -u lucidworks tar xvzf $fusion_file
echo Starting fusion....
sudo -u lucidworks fusion/$ver/bin/fusion start
echo
echo Finished!
echo
echo "Enjoy using Lucidworks Fusion! You can access the UI @ http://${my_external_ip}:8764/"
