#!/bin/bash

set restart=0

if has_attribute "saltstack/master/public_key"; then
    TMP_KEY_FILE="/tmp/tt.$$.pub.key"
    read_attribute_file_content "saltstack/master/public_key" "$TMP_KEY_FILE"
    if diff -q "$TMP_KEY_FILE" /etc/salt/pki/master/master.pub 2>&1 >/dev/null; then
        restart=1
        mkdir -p /etc/salt/pki/master
        cp "$TMP_KEY_FILE" /etc/salt/pki/master/master.pub
    fi
    rm -f "$TMP_KEY_FILE"
fi

if has_attribute "saltstack/master/private_key"; then
    TMP_KEY_FILE="/tmp/tt.$$.priv.key"
    read_attribute_file_content "saltstack/master/private_key" "$TMP_KEY_FILE"
    if diff -q "$TMP_KEY_FILE" /etc/salt/pki/master/master.pem 2>&1 >/dev/null; then
        restart=1
        mkdir -p /etc/salt/pki/master
        cp "$TMP_KEY_FILE" /etc/salt/pki/master/master.pem
    fi
    rm -f "$TMP_KEY_FILE"
fi

if ! which salt-master; then
    if [[ -f /etc/redhat-release || -f /etc/centos-release ]]; then
        yum -y makecache
        yum install -y salt-master
        chkconfig salt-master on
        restart=1
    elif [[ -d /etc/apt ]]; then
        apt-get -y update
        apt-get -y --force-yes install salt-master
    elif [[ -f /etc/SuSE-release ]]; then
        zypper install -y -l salt salt-master
        systemctl enable salt-master.service
        restart=1
    else
        die "Staged on to unknown OS media!"
    fi
fi

if [[ $restart -eq 1 ]]; then
    if [[ -f /etc/redhat-release || -f /etc/centos-release ]]; then
        service salt-master stop
        service salt-master start
    elif [[ -d /etc/apt ]]; then
        service salt-master restart
    elif [[ -f /etc/SuSE-release ]]; then
        systemctl stop salt-master.service
        systemctl start salt-master.service
    else
        die "Staged on to unknown OS media!"
    fi
fi

# Save the cred files
write_attribute_file_content "saltstack/master/public_key" /etc/salt/pki/master/master.pub
write_attribute_file_content "saltstack/master/private_key" /etc/salt/pki/master/master.pem

