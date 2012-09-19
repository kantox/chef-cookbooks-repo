#
# Cookbook Name:: nginx
# Recipe:: push_stream_module
#
# Author:: Hristo Erinin (<zorlem@gmail.com>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

psm_src_filename = ::File.basename(node['nginx']['push_stream']['url'])
psm_src_filepath = "#{Chef::Config['file_cache_path']}/#{psm_src_filename}"
psm_extract_path = "#{Chef::Config['file_cache_path']}/nginx-push-stream-module/#{node['nginx']['push_stream']['checksum']}"

remote_file psm_src_filepath do
  source node['nginx']['push_stream']['url']
  checksum node['nginx']['push_stream']['checksum']
  owner "root"
  group "root"
  mode 0644
end

bash "extract_push_stream_module" do
  cwd ::File.dirname(psm_src_filepath)
  code <<-EOD
    mkdir -p #{psm_extract_path}
    tar xzf #{psm_src_filename} -C #{psm_extract_path}
    mv #{psm_extract_path}/*/* #{psm_extract_path}/
  EOD

  not_if { ::File.exists?(psm_extract_path) }
end

node.run_state['nginx_configure_flags'] =
  node.run_state['nginx_configure_flags'] | ["--add-module=#{psm_extract_path}"]
  
