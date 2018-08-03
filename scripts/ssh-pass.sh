#!/bin/bash -x

nodes="172.16.117.100 172.16.117.10 172.16.117.11 172.16.117.12 172.16.117.13"

for node in $nodes
  do
	  

	echo "node: $node"
        ssh-keygen -f "/home/gsanso/.ssh/known_hosts" -R "$node"
	sshpass -p vagrant ssh-copy-id -i /home/$(whoami)/.ssh/id_rsa.pub -o StrictHostKeyChecking=no vagrant@${node}

  done

