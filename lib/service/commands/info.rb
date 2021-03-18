# =============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Service.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Service is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Service. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Service, please visit:
# https://github.com/openflighthpc/flight-service
# ==============================================================================
require_relative '../command'
require_relative '../type'

require 'tty-markdown'
require 'erb'
require 'ostruct'

module Service
  module Commands
    class Info < Command
      TEMPLATE = <<~ERB
      # <%= title %>

      <%= text %>

      <% values.each do |opts| -%>
      ## <%= opts['label'] %>
      *Key:* <%= opts['key'] %>
      *Default:* <%= opts['value'] %>
      *Value:* <%= data[opts['key']] %>

      <% end -%>
      ERB

      def run
        bind = OpenStruct.new(service.configuration.merge(data: data)).instance_exec { self.binding }
        markdown = ERB.new(TEMPLATE, nil, '-').result(bind)
        puts TTY::Markdown.parse(markdown)
      end

      private

      def data
        @data ||= File.exists?(data_file) ? YAML.load_file(data_file).to_h : {}
      end

      def data_file
        File.join(Config.service_etc_dir,"#{service.name}.yml")
      end

      def service
        @service ||= Type[args[0]]
      end
    end
  end
end
