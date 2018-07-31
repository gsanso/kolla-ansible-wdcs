#!/bin/bash -x

nodes="10.1.1.100 10.1.1.10 10.1.1.11 10.1.1.12 10.1.1.13"

for node in $nodes
  do
	  

	echo "node: $node"
	#sshpass -f password.txt ssh-copy-id user@yourserver

	sshpass -p vagrant ssh-copy-id -i /home/$(whoami)/.ssh/id_rsa.pub -o StrictHostKeyChecking=no vagrant@${node}

  done

