#!/bin/bash

#$1 -- machine private ipv4
#$2 -- new machine hostname (as role) 

AUTH='echo "ubuntu"'

# copy built boki executables in machine
ssh -q ubuntu@$1 -- $AUTH | sudo -S mkdir /boki
ssh -q ubuntu@$1 -- $AUTH | sudo -S chmod a+rwx /boki
scp -q /home/ec2-user/ubuntu-build/* ubuntu@$1:/boki

# copy a setup script in the machine
scp -q /home/ec2-user/boki-benchmarks/scripts/aws-academy/setup.sh ubuntu@$1:/home/ubuntu
ssh -q ubuntu@$1 -- $AUTH | sudo -S chmod a+x /home/ubuntu/setup.sh
ssh -q ubuntu@$1 -- $AUTH | sudo -S /home/ubuntu/setup.sh $2
