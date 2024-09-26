#!/bin/bash

echo "Port 5000" >> /etc/ssh/sshd_config
echo "Port 5000" >> /etc/ssh/ssh_config

service ssh start

# Keep the container alive indefinitely
cat
