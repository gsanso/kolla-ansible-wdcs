#!/bin/bash -x

nodes="172.16.0.100 172.16.0.10 172.16.0.11 172.16.0.12 172.16.0.13"

for node in $nodes
  do
	  

	echo "node: $node"
	#sshpass -f password.txt ssh-copy-id user@yourserver

	sshpass -p vagrant ssh-copy-id -i /home/$(whoami)/.ssh/id_rsa.pub -o StrictHostKeyChecking=no vagrant@${node}

  done

