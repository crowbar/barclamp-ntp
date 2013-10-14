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

require 'json'
class BarclampNtp::Server < Role
  
  # update just one value in the template (assumes just 1 level deep!)
  # use via /api/v2/roles/[role]/template/[key]/[value]
  def update_template(key, value)
    raw = read_attribute("template")
    d = raw.nil? ? {} : JSON.parse(raw)
    case key
      when "external_servers"
        t = { :"crowbar"=> { :"ntp" => { :"external_servers" => value } }}
    end  
    if t
      merged = d.deep_merge(t)
      self.template = JSON.generate(merged)
      self.save!
    else
      Rails.logger.warn "BarclampNtp did not update template for key #{key} because no match was found"
    end
  end

end