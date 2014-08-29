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

class BarclampSaltstack::Master < Role

  def sysdata(nr)
    addr = nr.node.addresses.detect{|addr|addr.v4?}.addr
    { "saltstack" => {
        "master" => {
          "name" => nr.node.name,
          "ip" => addr,
          "deploy" => true 
        }
      }
    }
  end

  def on_active(nr)
    begin
        j = BarclampSaltstack::Jig.where(:name => "saltstack").first
        j.server = Attrib.get("saltstack-master_ip",nr)
        j.key = Attrib.get("saltstack-master_public_key",nr)
        j.active = true
        j.save!
     rescue => e
        Rails.logger.error("Failed to save jig: saltstack")
        Rails.logger.error("  #{e.message}")
        Rails.logger.error("  #{e.backtrace.inspect}")
     end
  end


end

