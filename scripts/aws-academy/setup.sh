AUTH='echo "ubuntu"'

# setup hostname 

$AUTH | sudo -S hostnamectl set-hostname $1

# install docker 

curl -fsSL https://get.docker.com -o get-docker.sh
$AUTH | sudo -S sh ~/get-docker.sh
$AUTH | sudo -S usermod -aG docker $USER
newgrp docker
docker run hello-world

# install those in case boki needs them

$AUTH | sudo -S apt-get install -y g++ make cmake pkg-config autoconf automake libtool curl unzip 

# create in memory file system

$AUTH | sudo -S mkdir /mnt/inmem
$AUTH | sudo -S mount tmpfs /mnt/inmem -t tmpfs -o size=4G
$AUTH | sudo -S echo "tmpfs       /mnt/inmem tmpfs   nodev,nosuid,nodiratime,size=4096M   0 0" | $AUTH | sudo -S tee -a /etc/fslab
$AUTH | sudo -S chmod a+w /mnt/inmem/