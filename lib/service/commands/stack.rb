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

require 'whirly'

module Service
  module Commands
    class Stack < Command
      def run
        if Type.enabled.any?
          case action
          when 'start'
            puts "Starting enabled services:\n\n"
            start
          when 'stop'
            puts "Stopping enabled services:\n\n"
            stop
          when 'restart'
            puts "Restarting enabled services:\n\n"
            restart
          when 'reload'
            puts "Reloading enabled services:\n\n"
            reload
          when 'status'
            status
          end
        else
          puts "No services are enabled."
        end
      end

      private
      def status
        if $stdout.tty?
          Table.emit do |t|
            headers 'Service', 'Status', 'PID'
            Type.safe_enabled_types.each do |t|
              row Paint[t.name, :cyan],
                  t.running? ? 'active' : 'stopped',
                  t.pid
            end
          end
        else
          Type.safe_enabled_types.each do |t|
            puts [t.name, t.running? ? 'active' : 'stopped', t.pid].join("\t")
          end
        end
      end

      def start
        Type.safe_enabled_types.each do |service|
          print "   > "
          if service.running?
            text = Paint["Service already running: #{service.name}", '#2794d8']
            puts "\u2705 #{text}"
          else
            status_text = Paint["Starting service: #{service.name}", '#2794d8']
            begin
              success = whirly(status_text) { service.start }
              puts "#{success ? "\u2705" : "\u274c"} #{status_text}"
            rescue
              puts "\u274c #{status_text} (#{$!.message})"
            end
          end
        end
        puts "\nStack services started."
      end

      def restart
        Type.safe_enabled_types.each do |service|
          print "   > "
          status_text = Paint["Restarting service: #{service.name}", '#2794d8']
          begin
            success = whirly(status_text) { service.restart }
            puts "#{success ? "\u2705" : "\u274c"} #{status_text}"
          rescue
            puts "\u274c #{status_text} (#{$!.message})"
          end
        end
        puts "\nStack services restarted."
      end

      def stop
        Type.safe_enabled_types.each do |service|
          print "   > "
          if !service.running?
            text = Paint["Service already stopped: #{service.name}", '#2794d8']
            puts "\u2705 #{text}"
          else
            status_text = Paint["Stopping service: #{service.name}", '#2794d8']
            begin
              success = whirly(status_text) { service.stop }
              puts "#{success ? "\u2705" : "\u274c"} #{status_text}"
            rescue
              puts "\u274c #{status_text} (#{$!.message})"
            end
          end
        end
        puts "\nStack services stopped."
      end

      def reload
        Type.safe_enabled_types.each do |service|
          print "   > "
          if !service.running?
            text = Paint["Service not running: #{service.name}", '#2794d8']
            puts "\u274c #{text}"
          else
            if service.reloadable?
              status_text = Paint["Reloading service: #{service.name}", '#2794d8']
              begin
                success = whirly(status_text) { service.reload }
                puts "#{success ? "\u2705" : "\u274c"} #{status_text}"
              rescue
                puts "\u274c #{status_text} (#{$!.message})"
              end
            else
              text = Paint["Service not reloadable: #{service.name}", '#2794d8']
              puts "\u274c #{text}"
            end
          end
        end
        puts "\nStack services reloaded."
      end

      def action
        @action ||= args[0].tap do |a|
          unless ['start', 'stop', 'restart', 'reload', 'status'].include?(a)
            raise UnknownStackActionError, "unknown stack action: #{a}"
          end
        end
      end

      def whirly(status_text, &block)
        Whirly.start(
          spinner: 'star',
          remove_after_stop: true,
          append_newline: false,
          status: status_text
        )
        block.call
      ensure
        Whirly.stop
      end
    end
  end
end
