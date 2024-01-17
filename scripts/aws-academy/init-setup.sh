#!/bin/bash

#$1 -- machine private ipv4
#$2 -- new machine hostname (as role) 
#$3 -- is storage node ( do not provide if node is not a storage node )

AUTH='echo "ubuntu"'

# copy built boki executables in machine
ssh -q ubuntu@$1 -- "$AUTH | sudo -S mkdir /boki"
ssh -q ubuntu@$1 -- "$AUTH | sudo -S chmod a+rwx /boki"
scp -q /home/ec2-user/ubuntu-build/* ubuntu@$1:/boki

# copy a setup script in the machine
scp -q ./setup.sh ubuntu@$1:~
ssh -q ubuntu@$1 -- "$AUTH | sudo -S chmod a+x ~/setup.sh"
ssh -q ubuntu@$1 -- "$AUTH | sudo -S ~/setup.sh $2 $3"
