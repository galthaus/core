#!/bin/bash

if ! which salt-minion; then
    if [[ -f /etc/redhat-release || -f /etc/centos-release ]]; then
        yum -y makecache
        yum install -y salt-minion
        chkconfig salt-minion on
        service salt-minion stop
        service salt-minion start
    elif [[ -d /etc/apt ]]; then
        apt-get -y update
        apt-get -y --force-yes install salt-minion
    elif [[ -f /etc/SuSE-release ]]; then
        zypper install -y -l salt salt-minion
        systemctl enable salt-minion.service
        systemctl stop salt-minion.service
        systemctl start salt-minion.service
    else
        die "Staged on to unknown OS media!"
    fi
fi

