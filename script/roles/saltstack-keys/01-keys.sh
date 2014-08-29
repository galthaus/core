#!/bin/bash

# Clean out minions
minions=$(ls /etc/salt/pki/master/minions)
if [[ "${minions}" != "" ]]; then
    for name in $minions
    do
        if [[ ! $(has_attribute "saltstack/master/keys/${name}") ]]; then
            rm -f "/etc/salt/pki/master/minions/${name}"
        fi
    done
fi

# Put minions in place.
key_names=$(get_keys "saltstack/master/keys")
if [[ "${key_names}" != "" ]]; then
    for name in $key_names
    do
      read_attribute_file_content "saltstack/master/keys/${name}" "/etc/salt/pki/master/minions/${name}"
      echo "" >> "/etc/salt/pki/master/minions/${name}"
    done
fi

# Clean up the pending minions
rm -rf /etc/salt/pki/master/minions_pre/*

