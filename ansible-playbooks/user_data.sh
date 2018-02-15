#!/bin/bash -e

# Logging user data output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "BEGIN"

# Install PIVX
apt-get update
sudo apt-get install build-essential libtool autotools-dev autoconf pkg-config libssl-dev -y
sudo add-apt-repository ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
apt-get install wget nano vim-common -y
mkdir ~/pivx
cd ~/pivx
wget https://github.com/PIVX-Project/PIVX/releases/download/v2.2.1/pivx-2.2.1-x86_64-linux-gnu.tar.gz
tar xvzf pivx-2.2.1-x86_64-linux-gnu.tar.gz
mkdir ~/.pivx/
cp pivx-2.2.1/bin/pivx-cli ~/.pivx
cp pivx-2.2.1/bin/pivxd ~/.pivx
cp -v pivx-2.2.1/bin/* /usr/local/bin

# Update pivx.conf file
echo "rpcuser=pivxrpc" >> ~/.pivx/pivx.conf
echo -e "rpcpassword=$(xxd -l 16 -p /dev/urandom)" >> ~/.pivx/pivx.conf 
echo "rpcallowip=127.0.0.1" >> ~/.pivx/pivx.conf
echo "listen=0" >> ~/.pivx/pivx.conf
echo "server=1" >> ~/.pivx/pivx.conf
echo "daemon=1" >> ~/.pivx/pivx.conf
echo "logtimestamps=1" >> ~/.pivx/pivx.conf
echo "maxconnections=256" >> ~/.pivx/pivx.conf

# init scripts and service configuration for pivxd
echo "[Unit]" >> /lib/systemd/system/pivxd.service
echo "Description=PIVX's distributed currency daemon" >> /lib/systemd/system/pivxd.service
echo "After=network.target" >> /lib/systemd/system/pivxd.service
echo " " >> /lib/systemd/system/pivxd.service
echo "[Service]" >> /lib/systemd/system/pivxd.service
echo "User=root" >> /lib/systemd/system/pivxd.service
echo "Group=root" >> /lib/systemd/system/pivxd.service
echo " " >> /lib/systemd/system/pivxd.service
echo "Type=forking" >> /lib/systemd/system/pivxd.service
echo "PIDFile=/root/.pivx/pivxd.pid" >> /lib/systemd/system/pivxd.service
echo " " >> /lib/systemd/system/pivxd.service
echo "ExecStart=/usr/local/bin/pivxd -daemon -pid=/root/.pivx/pivxd.pid -conf=/root/.pivx/pivx.conf -datadir=/root/.pivx" >> /lib/systemd/system/pivxd.service
echo " " >> /lib/systemd/system/pivxd.service
echo "ExecStop=-/usr/local/bin/pivx-cli -conf=/root/.pivx/pivx.conf -datadir=/root/.pivx stop" >> /lib/systemd/system/pivxd.service
echo " " >> /lib/systemd/system/pivxd.service
echo "Restart=always" >> /lib/systemd/system/pivxd.service
echo "PrivateTmp=true" >> /lib/systemd/system/pivxd.service
echo "TimeoutStopSec=60s" >> /lib/systemd/system/pivxd.service
echo "TimeoutStartSec=2s" >> /lib/systemd/system/pivxd.service
echo "StartLimitInterval=120s" >> /lib/systemd/system/pivxd.service
echo "StartLimitBurst=5" >> /lib/systemd/system/pivxd.service
echo " " >> /lib/systemd/system/pivxd.service
echo "[Install]" >> /lib/systemd/system/pivxd.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/pivxd.service

systemctl daemon-reload

# Start PIVX service
systemctl start pivxd

# Enable pivxd to run at boot
systemctl enable pivxd

echo "END"
