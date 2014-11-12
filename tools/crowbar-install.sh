#!/bin/bash

# Turn off firewalls.
chkconfig iptables off
service iptables stop

# Set selinux to permissive
setenforce 0
sed -i "s/SELINUX=.*/SELINUX=permissive/g" /etc/selinux/config

# Setup OCB repo
cd /etc/yum.repos.d
cat > ocb.repo <<EOF
[ocb]
name=repo for opencrowbar rpms
baseurl=http://opencrowbar.s3-website-us-east-1.amazonaws.com/el6
enabled=1
gpgcheck=0
type=none
autorefresh=1
keeppackages=1
EOF

cd -

# Clean up repos
yum clean all
yum makecache

# Install code
if [[ $1 = '--without-hardware' ]]; then
    yum install -y opencrowbar-core
else
    yum install -y opencrowbar-hardware
fi

# Get the default installation OS.
mkdir -p /tftpboot/isos
cd /tftpboot/isos
wget http://mirrors.kernel.org/centos/7/isos/x86_64/CentOS-7.0-1406-x86_64-DVD.iso
cd -

if [[ $1 != '--without-hardware' ]]; then
    mkdir -p /tftpboot/files/raid

    echo "Remember to populate /tftpboot/files/raid"
    echo "See: https://github.com/opencrowbar/hardware/tree/master/doc"
    echo ""
    echo "Files can be pulled from these links after accepting licenses."
    echo "  http://www.lsi.com/downloads/Public/Host%20Bus%20Adapters/Host%20Bus%20Adapters%20Common%20Files/SAS_SATA_6G_P19/SAS2IRCU_P19.zip"
    echo "  http://www.lsi.com/downloads/Public/RAID%20Controllers/RAID%20Controllers%20Common%20Files/8.07.14_MegaCLI.zip"
    echo ""
fi

