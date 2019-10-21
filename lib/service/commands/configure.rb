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
require_relative '../dialog'

require 'yaml'

module Service
  module Commands
    class Configure < Command
      def run
        if configurable?
          dialog.request
          if dialog.changed?
            save(dialog.data)
            service.configure(dialog.data)
            puts "Changes applied."
          else
            puts "No changes made."
          end
        else
          puts "No configuration for service"
        end
      end

      private
      def save(values)
        File.write(data_file, values.to_yaml)
      end

      def load
        YAML.load_file(data_file) rescue {}
      end

      def data_file
        File.join(Config.service_etc_dir,"#{service.name}.yml")
      end

      def data
        @data ||= load
      end

      def dialog
        @dialog ||=
          begin
            cfg = service.configuration
            values = {}.tap do |h|
              cfg['values'].each do |vh|
                h[vh['key']] = data[vh['key']] || vh['value'].to_s
              end
            end
            Dialog.create(values) do
              title cfg['title']
              text cfg['text']
              cfg['values'].each do |h|
                value h['label'], h['key']
              end
            end
          end
      end

      def configurable?
        !service.configuration.nil?
      end

      def service
        Type[args[0]]
      end
    end
  end
end
