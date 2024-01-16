#!/bin/bash


AUTH='echo "ubuntu"'

# setup hostname 

$AUTH | sudo -S hostnamectl set-hostname $1

# install docker 

curl -fsSL https://get.docker.com -o get-docker.sh
$AUTH | sudo -S sh /home/ubuntu/get-docker.sh
#newgrp docker
$AUTH | sudo -S usermod -aG docker $USER
#docker run hello-world

# install those in case boki executables needs them

$AUTH | sudo -S apt-get install -y g++ make cmake pkg-config autoconf automake libtool curl unzip sysstat

# create in memory file system

$AUTH | sudo -S mkdir /mnt/inmem
$AUTH | sudo -S mount tmpfs /mnt/inmem -t tmpfs -o size=2G
$AUTH | sudo bash -c 'echo "tmpfs       /mnt/inmem tmpfs   nodev,nosuid,nodiratime,size=4096M   0 0" > /etc/fslab'
$AUTH | sudo -S chmod a+w /mnt/inmem/

if [ $2 ]
then
    $AUTH | sudo -S mkfs -t ext4 /dev/nvme1n1
    $AUTH | sudo -S mkdir /mnt/storage
    $AUTH | sudo -S mount -o defaults,noatime /dev/nvme1n1 /mnt/storage
    $AUTH | sudo -S chmod a+w /mnt/storage/
fi
                 
