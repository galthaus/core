# Copyright 2013, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#

require 'json'
require 'chef'
require 'fileutils'
require 'thread'

class BarclampSaltstack::Jig < Jig
  @@load_role_mutex ||= Mutex.new

  def run(nr,data)
    raise "GREG: SaltStack Jig is not implemented"

    prep_chef_auth
    if nr.role.respond_to?(:jig_role)
      jr = nr.role.jig_role(nr)
      unless (Chef::Role.load(jr['name']) rescue nil)
        begin
          Chef::Role.json_create(nr.role.jig_role(nr)).save
        rescue Net::HTTPServerException
          Rails.logger.info("Role #{jr["name"]} already exists in the Chef server")
        end
      end
    end
    unless (Chef::Role.load(nr.role.name) rescue nil)
      raise "Chef role for #{nr.role.name} is not in the Chef server!"
    end
    chef_node, chef_noderole = chef_node_and_role(nr.node)
    chef_noderole.default_attributes(data[:data])
    chef_noderole.run_list(data[:runlist])
    chef_noderole.save
    # For now, be bloody stupid.
    # We should really be much more clever about building
    # and maintaining the run list, but this will do to start off.
    chef_node.attributes.normal = {}
    chef_node.run_list(Chef::RunList.new(chef_noderole.to_s))
    chef_node.save
    # SSH into the node and kick chef-client.
    # If it passes, go to ACTIVE, otherwise ERROR.
    out,err,ok = nr.node.ssh("chef-client")
    raise("Chef jig run for #{nr.name} failed\nOut: #{out}\nErr:#{err}") unless ok.success?
    # Reload the node, find any attrs on it that map to ones this
    # node role cares about, and write them to the wall.
    Rails.logger.info("Chef jig: Reloading Chef objects")
    chef_node, chef_noderole = chef_node_and_role(nr.node)
    NodeRole.transaction do
      wall = mash_to_hash(chef_node.attributes.normal)
      discovery = {"ohai" => mash_to_hash(chef_node.attributes.automatic.to_hash)}
      Rails.logger.debug("Chef jig: Saving runlog")
      nr.update!(runlog: out)
      Rails.logger.debug("Chef jig: Saving wall")
      nr.update!(wall: wall)
      Rails.logger.debug("Chef jig: Saving discovery attributes")
      nr.node.discovery_merge(discovery)
    end
  end

  def create_node(node)
    Rails.logger.info("GREG: SaltStack Jig Creating node #{node.name}")
  end

  def delete_node(node)
    Rails.logger.info("GREG: DO THIS: SaltStack Jig Deleting node #{node.name}")
  end

end # class
