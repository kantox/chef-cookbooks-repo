#
# Cookbook Name:: nginx
# Recipe:: upload_module
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

um_src_filename = ::File.basename(node['nginx']['upload']['url'])
um_src_filepath = "#{Chef::Config['file_cache_path']}/#{um_src_filename}"
um_extract_path = "#{Chef::Config['file_cache_path']}/nginx-upload-module/#{node['nginx']['upload']['checksum']}"

remote_file um_src_filepath do
  source node['nginx']['upload']['url']
  checksum node['nginx']['upload']['checksum']
  owner "root"
  group "root"
  mode 0644
end

bash "extract_upload_module" do
  cwd ::File.dirname(um_src_filepath)
  code <<-EOD
    mkdir -p #{um_extract_path}
    tar xzf #{um_src_filename} -C #{um_extract_path}
    mv #{um_extract_path}/*/* #{um_extract_path}/
  EOD

  not_if { ::File.exists?(um_extract_path) }
end

node.run_state['nginx_configure_flags'] =
  node.run_state['nginx_configure_flags'] | ["--add-module=#{um_extract_path}"]
  
