# setup hostname 

sudo hostnamectl set-hostname $1

# install docker 

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ~/get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world

# install those in case boki needs them

sudo apt-get install -y g++ make cmake pkg-config autoconf automake libtool curl unzip 

# create in memory file system

sudo mkdir /mnt/inmem
sudo mount tmpfs /mnt/inmem -t tmpfs -o size=4G
sudo echo "tmpfs       /mnt/inmem tmpfs   nodev,nosuid,nodiratime,size=4096M   0 0" | sudo tee -a /etc/fslab
sudo chmod a+w /mnt/inmem/