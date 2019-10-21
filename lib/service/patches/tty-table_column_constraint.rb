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
# Allow ColumnConstraint to be disabled
class TTY::Table::ColumnConstraint
  class << self
    attr_accessor :rotate
  end
  self.rotate = false

  def enforce
    assert_minimum_width
    padding = renderer.padding

    if natural_width <= renderer.width
      if renderer.resize
        expand_column_widths
      else
        renderer.column_widths.map do |width|
          padding.left + width + padding.right
        end
      end
    else
      if renderer.resize
        shrink
      else
        if self.class.rotate == true
          rotate
        else
          renderer.column_widths.map do |width|
            padding.left + width + padding.right
          end
        end
      end
    end
  end
end
