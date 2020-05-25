#!/bin/bash

# modified from https://gist.github.com/JohnMount/3694b155d2d184d263e4e34c6ae4a943

# read instance id and write to key file
echo "What is the Instance id ?"
read instanceId
echo $instanceId > $(dirname ${BASH_SOURCE[0]})/.instanceId

# read username and password
echo "Set a username:"
read username
while true; do
    read -s -p "Password: " password
    echo
    read -s -p "Password (again): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Please try again"
done

# start ec2 instance
instanceStatus=$(aws ec2 describe-instance-status --instance-id $instanceId --query 'InstanceStatuses[0].SystemStatus.Status' | sed -e 's/^"//' -e 's/"$//')
if [ "$instanceStatus" == "ok" ]; then
    echo "EC2 instance is already running..."
else
    echo "Starting EC2 instance..."
    aws ec2 start-instances --instance-ids $instanceId > /dev/null 2>&1
    aws ec2 wait instance-status-ok --instance-ids $instanceId
fi

# set up ec2 instance
dnsAdress=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].PublicDnsName' | jq ".[0]" | sed s/\"//g)
ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$dnsAdress << EOBLOCK
# on remote machine
sudo apt-get -y update
sudo apt-get -y upgrade

# install r https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-16-04-2
sudo add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'
sudo apt-get update
sudo apt-get -y --allow-unauthenticated install r-base r-base-dev
sudo apt-get -y install gdebi whois

# dependecy for tidyverse
sudo apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev

# install rstudio server
wget https://download2.rstudio.org/rstudio-server-1.1.383-amd64.deb
sudo gdebi -n rstudio-server-1.1.383-amd64.deb
sudo /bin/bash -c "echo 'www-address=127.0.0.1' >> /etc/rstudio/rserver.conf"
sudo rstudio-server restart

#create user
sudo useradd -m -p `mkpasswd -m sha-512 $password` -s /bin/bash $username
EOBLOCK