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
require_relative 'commands'
require_relative 'version'

require 'tty/reader'
require 'commander'

module Service
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME','service')

    extend Commander::Delegates
    program :application, "Flight Service"
    program :name, PROGRAM_NAME
    program :version, "Release 2019.1 (v#{Service::VERSION})"
    program :description, 'Manage HPC environment services.'
    program :help_paging, false
    default_command :help
    silent_trace!

    error_handler do |runner, e|
      case e
      when TTY::Reader::InputInterrupt
        $stderr.puts "\n#{Paint['WARNING', :underline, :yellow]}: Cancelled by user"
        exit(130)
      else
        Commander::Runner::DEFAULT_ERROR_HANDLER.call(runner, e)
      end
    end

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/
      Paint.mode = 0
    end

    class << self
      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command :avail do |c|
      cli_syntax(c)
      c.summary = 'Show available services'
      c.action Commands, :avail
      c.description = <<EOF
Display a list of available services and whether they are enabled for
batch launching by the 'launch' command.
EOF
    end
    alias_command :av, :avail

    command :enable do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Enable a service'
      c.action Commands, :enable
      c.description = <<EOF
Add SERVICE to the batch launching list used by the 'launch' command.

See 'avail' command for the list of services.
EOF
    end

    command :disable do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Disable a service'
      c.action Commands, :disable
      c.description = <<EOF
Remove SERVICE from the batch launching list used by the 'launch'
command.

See 'avail' command for the list of services.
EOF
    end

    command :start do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Start a service'
      c.action Commands, :start
      c.description = <<EOF
Start a service.
EOF
    end

    command :launch do |c|
      cli_syntax(c)
      c.summary = 'Start all enabled services'
      c.action Commands, :launch
      c.description = <<EOF
Start all services enabled for batch launching via the 'enable' command.

See 'avail' command for the list of services.
EOF
    end

    command :restart do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Restart a service'
      c.action Commands, :restart
      c.description = <<EOF
Restart a service.
EOF
    end

    command :stop do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Stop a service'
      c.action Commands, :stop
      c.description = <<EOF
Stop a service.
EOF
    end

    command :status do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Show status of a service'
      c.action Commands, :status
      c.description = <<EOF
Disable a service.
EOF
    end

#     command :info do |c|
#       cli_syntax(c, 'SERVICE')
#       c.summary = 'Show details about a service'
#       c.action Commands, :info
#       c.description = <<EOF
# Display more detail about a service and its current configuration.
# EOF
#     end
#     alias_command :show, :info

    command :configure do |c|
      cli_syntax(c, 'SERVICE')
      c.summary = 'Configure a service'
      c.action Commands, :configure
      c.description = <<EOF
Perform configuration of a service.
EOF
    end

    command :list do |c|
      cli_syntax(c)
      c.summary = 'List running services'
      c.action Commands, :list
      c.description = <<EOF
List running services.
EOF
    end
  end
end
