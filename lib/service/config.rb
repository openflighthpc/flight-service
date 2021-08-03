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
require_relative 'type'
require 'xdg'
require 'tty-config'
require 'fileutils'

module Service
  module Config
    class << self
      SERVICE_DIR_SUFFIX = File.join('flight','service')

      def data
        @data ||= TTY::Config.new.tap do |cfg|
          cfg.append_path(File.join(root, 'etc'))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_data
        FileUtils.mkdir_p(File.join(root, 'etc'))
        data.write(force: true)
      end

      def data_writable?
        File.writable?(File.join(root, 'etc'))
      end

      def user_data
        @user_data ||= TTY::Config.new.tap do |cfg|
          xdg_config.all.map do |p|
            File.join(p, SERVICE_DIR_SUFFIX)
          end.each(&cfg.method(:append_path))
          begin
            cfg.read
          rescue TTY::Config::ReadError
            nil
          end
        end
      end

      def save_user_data
        FileUtils.mkdir_p(
          File.join(
            xdg_config.home,
            SERVICE_DIR_SUFFIX
          )
        )
        user_data.write(force: true)
      end

      def path
        config_path_provider.path ||
          config_path_provider.paths.first
      end

      def root
        @root ||= File.expand_path(File.join(__dir__, '..', '..'))
      end

      def type_paths
        @type_paths ||=
          data.fetch(
            :type_paths,
            default: [
              'etc/types'
            ]
          ).map {|p| File.expand_path(p, Config.root)}
      end

      def env_dir
        @env_dir ||=
          File.expand_path(
            data.fetch(
              :env_dir,
              default: 'etc/env'
            ),
            Config.root
          )
      end

      def service_etc_dir
        @service_etc_dir ||=
          File.expand_path(
            data.fetch(
              :service_etc_dir,
              default: 'var/lib'
            ),
            Config.root
          )
      end

      def service_state_dir
        @service_state_dir ||=
          File.expand_path(
            data.fetch(
              :service_state_dir,
              default: 'var/run'
            ),
            Config.root
          )
      end

      def timeout
        @timeout ||= begin
          str = data.fetch(:timeout, default: '5')
          Integer(str)
        end
      end

      def service_log_dir
        @service_log_dir ||=
          File.expand_path(
            data.fetch(
              :service_log_dir,
              default: 'var/log'
            ),
            Config.root
          )
      end

      private
      def xdg_config
        @xdg_config ||= XDG::Config.new
      end

      def xdg_data
        @xdg_data ||= XDG::Data.new
      end

      def xdg_cache
        @xdg_cache ||= XDG::Cache.new
      end
    end
  end
end
