#$1 -- machine private ipv4
#$2 -- new machine hostname (as role) 

# copy built boki executables in machine
ssh -q ubuntu@$1 -- sudo mkdir /boki
ssh -q ubuntu@$1 -- sudo chmod a+rwx /boki
scp -q /home/ec2-user/ubuntu-build/* ubuntu@$1:/boki

# copy a setup script in the machine
scp -q ./setup.sh ubuntu@$1:~
ssh -q ubuntu@$1 -- sudo chmod a+x ~/setup.sh
ssh -q ubuntu@$1 -- sudo ~/setup.sh $2
