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
require_relative 'config'
require_relative 'errors'
require_relative 'command_utils'
require_relative 'env_parser'

require 'sys/proctable'
require 'fileutils'
require 'yaml'

module Service
  class Type
    class << self
      def each(&block)
        all.values.each(&block)
      end

      def [](k)
        all[k.to_sym].tap do |t|
          if t.nil?
            raise UnknownServiceTypeError, "unknown service type: #{k}"
          end
        end
      end

      def all
        @types ||=
          begin
            {}.tap do |h|
              Config.type_paths.each do |p|
                Dir[File.join(p,'*')].sort.each do |d|
                  begin
                    md = YAML.load_file(File.join(d,'metadata.yml'))
                    h[md[:name].to_sym] = Type.new(md, d)
                  rescue
                    nil
                  end
                end
              end
            end
          end
      end

      def enabled
        @enabled ||= begin
          names = begin
            YAML.load_file(File.join(Config.service_etc_dir, 'enabled.yml'))
          rescue
            []
          end
          names.map do |name|
            begin
              self[name]
            rescue
              @missing_enabled_types ||= []
              @missing_enabled_types << name
              nil
            end
          end
        end.reject(&:nil?)
      end

      def missing_enabled_types
        enabled # Ensure the cache is populated
        @missing_enabled_types
      end

      def save_enabled_file
        FileUtils.mkdir_p(Config.service_etc_dir)
        types = [*enabled.map(&:name), *missing_enabled_types]
        File.write(
          File.join(Config.service_etc_dir, 'enabled.yml'),
          types
        )
      end
    end

    attr_reader :name
    attr_reader :summary

    def initialize(md, dir)
      @name = md[:name]
      @summary = md[:summary]
      @dir = dir
    end

    def start
      ctx = {}
      run_operation('start', context: ctx).tap do |s|
        if s
          raise ServiceOperationError, 'PID of service was not reported' if ctx['pid'].nil?
          FileUtils.mkdir_p(Config.service_state_dir)
          File.write(pidfile, ctx['pid'])
        end
      end
    end

    def stop
      run_operation('stop', args: [pidfile]).tap do |s|
        if s
          FileUtils.rm_f(pidfile)
        end
      end
    end

    def reload
      raise ServiceOperationError, 'Service is not reloadable' unless reloadable?
      run_operation('reload', args: [pidfile])
    end

    def restart
      ctx = {}
      run_operation('restart', args: [pidfile], context: ctx).tap do |s|
        if s
          raise ServiceOperationError, 'PID of service was not reported' if ctx['pid'].nil?
          FileUtils.mkdir_p(Config.service_state_dir)
          File.write(pidfile, ctx['pid'])
        end
      end
    end

    def configuration
      @configuration ||= YAML.load_file(File.join(@dir,'configuration.yml'))
    rescue
      nil
    end

    def configurable?
      !configuration.nil?
    end

    def daemon?
      File.exists?(File.join(@dir, "start.sh"))
    end

    def configure(values)
      value_args = values.map {|k,v| "#{k}=#{v}"}
      run_operation('configure', args: value_args)
    end

    def enable
      return false if enabled?
      self.class.enabled << self
      self.class.save_enabled_file
      true
    end

    def enabled?
      self.class.enabled.include?(self)
    end

    def disable
      return false unless enabled?
      self.class.enabled.delete(self)
      self.class.save_enabled_file
      true
    end

    def pid
      running? ? File.read(pidfile).chomp : 'n/a'
    end

    def pidfile
      @pidfile ||=
        File.join(Config.service_state_dir, "#{self.name}.pid")
    end

    def running?
      if File.exists?(pidfile)
        pid = File.read(pidfile)
        !!Sys::ProcTable.ps(pid: pid.to_i)
      end
    end

    def reloadable?
      File.exists?(File.join(@dir, "reload.sh"))
    end

    private
    def env
      {}.tap do |h|
        default_env_file = File.join(Config.env_dir,'default')
        h.merge!(
          EnvParser.parse(File.read(default_env_file))
        ) if File.exists?(default_env_file)

        service_env_file = File.join(Config.env_dir, self.name)
        h.merge!(
          EnvParser.parse(File.read(service_env_file))
        ) if File.exists?(service_env_file)
      end
    end

    def run_operation(op, context: {}, args: [])
      CommandUtils.run_script(
        self.name,
        File.join(@dir, "#{op}.sh"),
        Config.service_log_dir,
        op,
        args,
        context,
        env
      )
    end
  end
end
