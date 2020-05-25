#! /bin/bash

sourceDir="${BASH_SOURCE[0]}"
instanceId=$(cat $(dirname $sourceDir)/.instanceId)

# check status
instanceStatus=$(aws ec2 describe-instance-status --instance-id $instanceId --query 'InstanceStatuses[0].SystemStatus.Status' | sed -e 's/^"//' -e 's/"$//')
if [ "$instanceStatus" == "ok" ]; then
    echo "EC2 instance is already running..."
else
    # start ec2 instance
    echo "Starting EC2 instance..."
    aws ec2 start-instances --instance-ids $instanceId > /dev/null 2>&1
    aws ec2 wait instance-status-ok --instance-ids $instanceId
fi

# start rstudio server
dnsAdress=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].PublicDnsName' | jq ".[0]" | sed s/\"//g)
ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@$dnsAdress << EOF
    sudo rstudio-server start
EOF

# forward port
echo "Forwarding Port 8787..."
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -f -N -L 8787:localhost:8787 ubuntu@$dnsAdress > /dev/null 2>&1

# open webapp in browser
echo "Starting the Browser..."
open http://localhost:8787

