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
    class Launch < Command
      def run
        if Type.enabled.any?
          puts "Launching enabled services:\n\n"
          Type.enabled.each do |svc|
            service = Type[svc]
            print "   > "
            if service.running?
              already_running_text = Paint["Service already running: #{service.name}", '#2794d8']
              puts "\u2705 #{already_running_text}"
            else
              status_text = Paint["Starting service: #{service.name}", '#2794d8']
              begin
                Whirly.start(
                  spinner: 'star',
                  remove_after_stop: true,
                  append_newline: false,
                  status: status_text
                )
                success = service.start
                Whirly.stop
              rescue
                puts "\u274c #{status_text}"
              end
              puts "#{success ? "\u2705" : "\u274c"} #{status_text}"
            end
          end
          puts "\nEnabled services launch complete."
        else
          puts "No services are enabled."
        end
      end
    end
  end
end
