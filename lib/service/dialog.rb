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
require 'mrdialog'

module Service
  class Dialog
    class << self
      attr_accessor :title, :text

      def build(&block)
        DSL.run(&block)
      end

      def create(*args, &block)
        build(&block).new(*args)
      end

      def values
        @values ||= []
      end
    end

    FormData = Struct.new(:label, :ly, :lx, :item, :iy, :ix, :flen, :ilen)

    attr_reader :data

    def initialize(data = {})
      @data = data
    end

    def method_missing(s, *a, &b)
      t = s.to_s
      if t[-1] == '=' && @data.key?(t[0..-2])
        @data[t[0..-2]] = a.first
      elsif @data.key?(t)
        @data[t]
      else
        super
      end
    end

    def respond_to_missing?(s, _)
      s = s.to_s
      if s[-1] == '='
        @data.key?(s[0..-2])
      else
        @data.key?(s.to_s)
      end
    end

    def changed?
      !!@changed
    end

    def key_for(label)
      (self.class.values.find {|h| h[:label] == label} || {})[:prop]
    end

    def request
      @changed = false
      dialog.form(self.class.text, items, 20, dialog_width, 0).tap do |results|
        results.each do |label,val|
          prop = key_for(label)
          unless send(prop.to_sym) == val
            send("#{prop}=".to_sym, val)
            @changed = true
          end
        end
      end
    end

    def dialog_width
      values = self.class.values
      label_length = values.map { |v| v[:label].length }.max
      input_length = values.map { |v| v[:length] }.compact.max || default_input_length
      [ label_length + input_length + 2, 50 ].max
    end

    def default_input_length
      10
    end

    def items
      i = 0
      label_length = self.class.values.map { |v| v[:label].length }.max

      self.class.values.map do |v|
        FormData.new.tap do |data|
          data.label = v[:label]
          data.ly = (i += 1)
          data.lx = 1
          data.item = send(v[:prop])
          data.iy = i
          data.ix = label_length + 2
          data.flen = v[:length] || data.item.length + default_input_length
          data.ilen = 0
        end.to_a
      end
    end

    def dialog
      MRDialog.new.tap do |d|
        d.dialog_options = '--keep-tite'
        d.rc_file = File.join(Config.root,"etc/dialog.rc")
        d.title = self.class.title
      end
    end

    class DSL
      class << self
        def run(&block)
          Class.new(Dialog).tap do |dialog_class|
            new(dialog_class).tap do |dsl|
              dsl.instance_eval(&block)
            end
          end
        end
      end

      def extend(&block)
        @dclass.class_eval(&block)
      end

      def initialize(dialog)
        @dclass = dialog
      end

      def title(v)
        @dclass.title = v
      end

      def text(v)
        @dclass.text = v
      end

      def value(label, prop, length)
        @dclass.values << {label: label, prop: prop, length: length}
      end
    end
  end
end
