#
# Copyright 2011-2013, Dell
# Copyright 2013-2014, SUSE LINUX Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class NtpService < ServiceObject
  def initialize(thelogger)
    super(thelogger)
    @bc_name = "ntp"
  end

  class << self
    def role_constraints
      {
        "ntp-server" => {
          "unique" => true,
          "count" => -1,
          "admin" => true,
          "exclude_platform" => {
            "windows" => "/.*/"
          }
        },
        "ntp-client" => {
          "unique" => true,
          "count" => -1,
          "admin" => true
        }
      }
    end
  end

  def create_proposal
    @logger.debug("NTP create_proposal: entering")
    base = super
    @logger.debug("NTP create_proposal: exiting")
    base
  end

  def validate_proposal_after_save proposal
    validate_at_least_n_for_role proposal, "ntp-server", 1

    super
  end

  def transition(inst, name, state)
    @logger.debug("NTP transition: make sure that network role is on all nodes: #{name} for #{state}")

    #
    # If we are discovering the node, make sure that we add the ntp client or server to the node
    #
    if state == "discovered"
      @logger.debug("NTP transition: discovered state for #{name} for #{state}")
      db = Proposal.where(barclamp: "ntp", name: inst).first
      role = RoleObject.find_role_by_name "ntp-config-#{inst}"

      if role.override_attributes["ntp"]["elements"]["ntp-server"].nil? or
         role.override_attributes["ntp"]["elements"]["ntp-server"].empty?
        @logger.debug("NTP transition: make sure that ntp-server role is on first: #{name} for #{state}")
        result = add_role_to_instance_and_node("ntp", inst, name, db, role, "ntp-server")
      else
        node = NodeObject.find_node_by_name name
        unless node.role? "ntp-server"
          @logger.debug("NTP transition: make sure that ntp-client role is on all nodes but first: #{name} for #{state}")
          result = add_role_to_instance_and_node("ntp", inst, name, db, role, "ntp-client")
        end
      end

      @logger.debug("NTP transition: leaving from discovered state for #{name} for #{state}")
      return [200, { :name => name } ] if result
      return [400, "Failed to add role to node"] unless result
    end

    @logger.debug("NTP transition: leaving for #{name} for #{state}")
    [200, { :name => name } ]
  end
end
