# Install the things
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update && sudo apt-get install -y git wget vim curl dnsmasq ntp mongodb-org libarchive-dev #openjdk-7-jre-headless

sudo /etc/init.d/networking restart

# DNSMASQ
sudo su -
MY_IP=$(ifconfig eth1 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
IP_BROADCAST=$(ifconfig eth1| awk '/Bcast/ {split ($3,A,":"); print A[2]}')
IP_RANGE="172.16.2.150"
cat > /etc/dnsmasq.conf <<EOF
server=$MY_IP@eth1
interface=eth1
no-dhcp-interface=eth0
domain=razor.one
# conf-dir=/etc/dnsmasq.d
# This works for dnsmasq 2.45
# iPXE sets option 175, mark it for network IPXEBOOT
dhcp-match=IPXEBOOT,175
dhcp-boot=net:IPXEBOOT,bootstrap.ipxe
dhcp-boot=undionly.kpxe
# TFTP setup
enable-tftp
tftp-root=/var/lib/tftpboot
dhcp-range=$MY_IP,$IP_RANGE,12h

dhcp-option=option:ntp-server,$MY_IP
EOF

sleep 10
service dnsmasq status

# NTP  
cat >> /etc/ntp.conf <<EOF
broadcast $IP_BROADCAST
EOF

# NAT
iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
iptables --append FORWARD --in-interface eth1 -j ACCEPT
iptables-save | sudo tee /etc/iptables.conf
iptables-restore < /etc/iptables.conf
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sed -i "s/exit 0/iptables-restore < \/etc\/\iptables.conf \nexit 0/g" /etc/rc.local
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

# Java Things
sudo apt-get install python-software-properties software-properties-common -y
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -q -y install oracle-java7-installer
sudo bash -c "echo JAVA_HOME=/usr/lib/jvm/java-7-oracle/ >> /etc/environment"

# Do the Ruby Things
curl -s https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash

cat >>/root/.profile <<EOF
# rbenv
export RBENV_ROOT="\${HOME}/.rbenv"
if [ -d "\${RBENV_ROOT}" ]; then
  export PATH="\${RBENV_ROOT}/bin:\${PATH}"
  eval "\$(rbenv init -)"
fi
EOF

source /root/.profile

rbenv bootstrap-ubuntu-12-04
git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
rbenv install jruby-1.7.8
rbenv install 1.9.3-p545
rbenv rehash && rbenv global 1.9.3-p545
gem install bundler

mkdir /opt/hanlon
cd /opt/hanlon
git clone https://github.com/bunchc/Hanlon.git .
bundle install

/opt/hanlon/hanlon_init

cd /opt/hanlon/web
./run-puma.sh &

# Get some ISOs
cd /tmp
wget https://github.com/csc/Hanlon-Microkernel/releases/download/v1.0/hnl_mk_debug-image.1.0.iso
wget http://mirror.anl.gov/pub/ubuntu-iso/CDs/trusty/ubuntu-14.04.1-server-amd64.iso

# Add the things to Hanlon
cd /opt/hanlon/
/opt/hanlon/cli/hanlon image add -t mk -p /tmp/hnl_mk_debug-image.1.0.iso
#/opt/hanlon/cli/hanlon image add -t os -p /tmp/ubuntu-14.04.1-server-amd64.iso