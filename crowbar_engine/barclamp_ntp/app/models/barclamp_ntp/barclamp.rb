# Copyright 2013, Dell 
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

class BarclampNtp::Barclamp < Barclamp

  def transition(inst, name, state)
    @logger.debug("NTP transition: make sure that network role is on all nodes: #{name} for #{state}")

    #
    # If we are discovering the node, make sure that we add the ntp client or server to the node
    #
    if state == "discovered"
      @logger.debug("NTP transition: discovered state for #{name} for #{state}")

      prop = @barclamp.get_proposal(inst)

      return [400, "NTP Proposal is not active"] unless prop.active?

      nodes = prop.active_config.get_nodes_by_role("ntp-server")
      result = true
      if nodes.empty?
        @logger.debug("NTP transition: make sure that ntp-server role is on first: #{name} for #{state}")
        result = add_role_to_instance_and_node(name, inst, "ntp-server")
      else
        node = Node.find_by_name(name)
        unless nodes.include? node
          @logger.debug("NTP transition: make sure that ntp-client role is on all nodes but first: #{name} for #{state}")
          result = add_role_to_instance_and_node(name, inst, "ntp-client")
        end
      end

      @logger.debug("NTP transition: leaving from discovered state for #{name} for #{state}")
      return [200, "" ] if result
      return [400, "Failed to add role to node"] unless result
    end

    @logger.debug("NTP transition: leaving for #{name} for #{state}")
    [200, ""]
  end

end

