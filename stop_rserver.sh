#! /bin/bash

sourceDir="${BASH_SOURCE[0]}"
instanceId=$(cat $(dirname $sourceDir)/.instanceId)

instanceStatus=$(aws ec2 describe-instance-status --instance-id $instanceId --query 'InstanceStatuses[0].SystemStatus.Status' | sed -e 's/^"//' -e 's/"$//')
if [ "$instanceStatus" -ne "ok" ]; then
    echo "EC2 instance isn't up"
else
	# stop rstudio server
	echo "Stop RStudio Server ..."
	dnsAdress=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[].Instances[].PublicDnsName' | jq ".[0]" | sed s/\"//g)
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -T ubuntu@$dnsAdress << EOF
		sudo rstudio-server stop
EOF

	echo "Kill Port Forwarding..."
	# kill fort forwarding
	kill $(ps aux | grep ssh\.\*8787:localhost:8787 | grep -v grep | awk '{print $2}')

	# stop instance
	echo "Stop EC2 Instance"
	aws ec2 stop-instances --instance-ids $instanceId > /dev/null 2>&1
fi