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
    class Restart < Command
      def run
        puts "Restarting '#{Paint[service.name, :cyan]}' service:\n\n"
        status_text = Paint["Restarting service", '#2794d8']
        print "   > "
        begin
          Whirly.start(
            spinner: 'star',
            remove_after_stop: true,
            append_newline: false,
            status: status_text
          )
          success = service.restart
          Whirly.stop
        rescue
          puts "\u274c #{status_text}\n\n"
          raise
        end
        puts "#{success ? "\u2705" : "\u274c"} #{status_text}\n\n"
        if success
          puts "The '#{Paint[service.name, :cyan]}' service has been restarted."
        else
          raise ServiceOperationError, "unable to restart service"
        end
      end

      private
      def service
        @service ||= Type[args[0]]
      end
    end
  end
end
