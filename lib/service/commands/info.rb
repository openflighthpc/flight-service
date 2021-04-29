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

module Service
  module Commands
    class Info < Command
      def run
        values = (service.configuration || {}).fetch('values', {})
        data = File.exists?(data_file) ? YAML.load_file(data_file).to_h : {}
        if values.empty?
          $stderr.puts 'No configuration options available'
        elsif $stdout.tty?
          Table.emit do |t|
            headers 'Label', 'Key', 'Default', 'Value'
            values.each do |opts|
              row Paint[opts['label'], :cyan],
                  opts['key'],
                  opts['value'] || '(none)',
                  data[opts['key']] || '(none)'
            end
          end
        else
          values.each do |opts|
            puts [
              opts['label'], opts['key'], opts['value'], data[opts['key']]
            ].join("\t")
          end
        end
      end

      private

      def data_file
        File.join(Config.service_etc_dir,"#{service.name}.yml")
      end

      def service
        @service ||= Type[args[0]]
      end
    end
  end
end
