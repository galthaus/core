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

  def on_proposed(nr)
    node_roles.each do |the_master_nr|
      next if the_master_nr.deployment != nr.deployment

      m_pub = (Attrib.get("saltstack-master_public_key", the_master_nr) rescue nil)
      m_priv = (Attrib.get("saltstack-master_private_key", the_master_nr) rescue nil)
      if m_pub and m_priv
        Attrib.set("saltstack-master_public_key", nr, m_pub, :system)
        Attrib.set("saltstack-master_private_key", nr, m_priv, :system)
        break
      end
    end
  end

end

