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
    class Status < Command
      def run
        if $stdout.tty?
          if !service.daemon?
            puts "Service '#{Paint[service.name, :cyan]}' is a static service"
          elsif service.running?
            puts "Service '#{Paint[service.name, :cyan]}' is active (#{service.pid})"
          else
            puts "Service '#{Paint[service.name, :cyan]}' is stopped"
          end
        else
          state =
            if !service.daemon?
              'static'
            elsif service.running?
              "active\t#{service.pid}"
            else
              'stopped'
            end
          puts state
        end
      end

      private
      def service
        @service ||= Type[args[0]]
      end
    end
  end
end
