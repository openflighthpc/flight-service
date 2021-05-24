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

require 'fileutils'
require 'yaml'

module Service
  module Commands
    class Configure < Command
      def run
        if !$stdout.tty? && !options.config
          raise InvalidInput, <<~ERROR.chomp
            Can not continue within a non-interactive terminal!
            Please specify the configs with the following flag: #{Paint['--config JSON', :yellow]}
          ERROR
        end

        if service.configurable?
          # Load the data either via the dialog or non-interactively
          data = if options.config
            json = begin
                     JSON.parse(config_input)
                   rescue JSON::ParserError
                     raise InvalidInput, 'The --config input is not valid JSON'
                   end
            unless json.is_a? Hash
              raise InvalidInput, 'The --config input does not produce a hash'
            end
            dialog.data.merge(json)
          else
            dialog.request
            dialog.data
          end

          if options.force || options.config || dialog.changed?
            save(data)
            service.configure(data)
            puts "Changes applied."
          else
            puts Paint[<<~WARN.chomp, :red]
              The configuration has not changed. Skipping the post configure script.
              The script can be ran using the following flag: #{Paint["--force", :yellow]}
            WARN
          end
        else
          puts "The '#{Paint[service.name, :cyan]}' service does not provide configurable parameters."
        end
      end

      private
      def save(values)
        FileUtils.mkdir_p(Config.service_etc_dir)
        File.write(data_file, values.to_yaml)
      end

      def load
        YAML.load_file(data_file).to_h rescue {}
      end

      def data_file
        File.join(Config.service_etc_dir,"#{service.name}.yml")
      end

      def data
        @data ||= load
      end

      def config_input
        if ['@-', '@/dev/stdin'].include? options.config
          $stdin.read
        elsif options.config[0] == '@'
          path = options.config[1..]
          if File.exists? path
            File.read(path)
          else
            raise InvalidInput, "Could not locate file: #{path}"
          end
        else
          options.config
        end
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
                value h['label'], h['key'], h['length']
              end
            end
          end
      end

      def service
        Type[args[0]]
      end
    end
  end
end
