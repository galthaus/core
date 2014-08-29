# Copyright 2014, Greg Althaus
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 

class BarclampSaltstack::Keys < Role

  def on_node_change(n)
    Rails.logger.info("saltstack-keys: Updating for change node #{n.name}")

    # Get the minion node role and the key node role
    the_nr, the_keys_nr, the_name, the_key = find_node_roles(n)

    # return if nothing exists
    return unless the_name and the_key and the_nr and the_keys_nr

    # Update the id/key pair in the key node role
    queue_it = false
    sd = the_keys_nr.sysdata
    k = (sd["saltstack"]["master"]["keys"][the_name] rescue nil)
    if k != the_key
      nd = { "saltstack" => { "master" => { "keys" => { the_name => the_key } } } }
      the_keys_nr.sysdata_update(nd)
      queue_it = true
    end

    # Run the node role if we changed it
    Run.enqueue(the_keys_nr) if queue_it
  end

  def on_node_delete(n)
    Rails.logger.info("saltstack-keys: Updating for delete node #{n.name}")

    # Get the minion node role and the key node role
    the_nr, the_keys_nr, the_name, the_key = find_node_roles(n)

    # return if nothing exists
    return unless the_nr and the_keys_nr and the_name and the_key

    # Remove the id/key pair in the key node role
    queue_it = false
    sd = the_keys_nr.sysdata
    k = (sd["saltstack"]["master"]["keys"][the_name] rescue nil)
    if k
      sd["saltstack"]["master"]["keys"].delete(the_name)
      the_keys_nr.sysdata = sd
      queue_it = true
    end

    # Run the node role if we changed it
    Run.enqueue(the_keys_nr) if queue_it
  end

  private

  def find_node_roles(n)
    # Find the saltstack-minion node role, name, and addr
    the_nr = nil
    the_addr = nil
    the_name = nil
    n.node_roles.each do |nr|
      the_name = (nr.sysdata["saltstack"]["minion"]["name"] rescue nil)
      the_addr = (nr.sysdata["saltstack"]["master"]["ip"] rescue nil)
      if the_name and the_addr
        the_nr = nr
        break
      end
    end

    # return if neither exist
    return [nil, nil, nil, nil] unless the_nr

    # Find the keys node role for this master
    the_keys_nr = nil
    node_roles.each do |nr|
      nr.with_lock('FOR NO KEY UPDATE') do
        addr = nr.node.addresses.detect{|addr|addr.v4?}.addr
        if addr == the_addr
          the_keys_nr = nr
          break
        end
      end
    end

    # return if neither exist
    return [the_nr, the_keys_nr, nil, nil] unless the_keys_nr

    # Read the minion id and key
    the_key = nil
    the_nr.with_lock do
      the_key = (the_nr.all_my_data["saltstack"]["minion"]["public_key"] rescue nil)
    end

    # If we have neither, do nothing
    [ the_nr, the_keys_nr, the_name, the_key ]
  end

end

