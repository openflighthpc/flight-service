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
require_relative 'errors'

require 'fileutils'
require 'whirly'
require_relative 'patches/unicode-display_width'

module Service
  module CommandUtils
    class << self
      def run_script(name, script, dir, op, args = [], context = {})
        if File.exists?(script)
          with_clean_env do
            run_fork(context) do |wr|
              wr.close_on_exec = false
              setup_bash_funcs(ENV, wr.fileno)
              log_file = File.join(
                dir,
                "#{name}.#{op}.log"
              )
              FileUtils.mkdir_p(dir)
              exec(
                {
                  'flight_SERVICE_etc' => Config.service_etc_dir
                },
                '/bin/bash',
                '-x',
                script,
                *args,
                close_others: false,
                [:out, :err] => [log_file ,'w']
              )
            end
          end
        else
          raise ScriptNotFoundError, "#{op} script not found"
        end
      end

      private
      def run_fork(context = {}, &block)
        Signal.trap('INT','IGNORE')
        rd, wr = IO.pipe
        pid = fork {
          rd.close
          Signal.trap('INT','DEFAULT')
          begin
            if block.call(wr)
              exit(0)
            else
              exit(1)
            end
          rescue Interrupt
            nil
          end
        }
        wr.close
        while !rd.eof?
          line = rd.readline
          if line =~ /^STAGE:/
            stage_stop
            @stage = line[6..-2]
            stage_start
          elsif line =~ /^SET:/
            k, v = line[4..-2].split('=',2)
            context[k] = v
          elsif line =~ /^ERR:/
            puts "== ERROR: #{line[4..-2]}"
          else
            puts " > #{line}"
          end
        end
        _, status = Process.wait2(pid)
        raise InterruptedOperationError, "Interrupt" if status.termsig == 2
        stage_stop(status.success?)
        Signal.trap('INT','DEFAULT')
        status.success?
      end

      def stage_start
        print "   > "
        Whirly.start(
          spinner: 'star',
          remove_after_stop: true,
          append_newline: false,
          status: Paint[@stage, '#2794d8']
        )
      end

      def stage_stop(success = true)
        return if @stage.nil?
        Whirly.stop
        puts "#{success ? "\u2705" : "\u274c"} #{Paint[@stage, '#2794d8']}"
        @stage = nil
      end

      def setup_bash_funcs(h, fileno)
        h['BASH_FUNC_flight_tool_comms()'] = <<EOF
() { local msg=$1
 shift
 if [ "$1" ]; then
 echo "${msg}:$*" 1>&#{fileno};
 else
 cat | sed "s/^/${msg}:/g" 1>&#{fileno};
 fi
}
EOF
        h['BASH_FUNC_tool_err()'] = "() { flight_tool_comms ERR \"$@\"\n}"
        h['BASH_FUNC_tool_stage()'] = "() { flight_tool_comms STAGE \"$@\"\n}"
        h['BASH_FUNC_tool_set()'] = "() { flight_tool_comms SET \"$@\"\n}"
        h['BASH_FUNC_tool_fileno()'] = "() { echo #{fileno} \n}"
        h['BASH_FUNC_tool_bg()'] = "() { setsid \"$@\" #{fileno}>&- </dev/null &>/dev/null &\n}"
      end

      def with_clean_env(&block)
        if Kernel.const_defined?(:OpenFlight) && OpenFlight.respond_to?(:with_standard_env)
          OpenFlight.with_standard_env(&block)
        else
          msg = Bundler.respond_to?(:with_unbundled_env) ? :with_unbundled_env : :with_clean_env
          Bundler.__send__(msg, &block)
        end
      end
    end
  end
end
