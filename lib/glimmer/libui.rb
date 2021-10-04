# Copyright (c) 2021 Andy Maleh
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'glimmer/fiddle_consumer'

module Glimmer
  module LibUI
    class << self
      include Glimmer::FiddleConsumer
      
      def integer_to_boolean(int, allow_nil: true)
        int.nil? ? (allow_nil ? nil : false) : int == 1
      end
      
      def boolean_to_integer(bool, allow_nil: true)
        bool.nil? ? (allow_nil ? nil : 0) : (bool ? 1 : 0)
      end
      
      def degrees_to_radians(degrees)
        ((Math::PI * 2.0) / 360.00) * degrees.to_f
      end
      
      def interpret_color(value)
        if value.is_a?(Array) && value.last.is_a?(Hash)
          options = value.last
          value = value[0...-1]
        end
        value = value.first if value.is_a?(Array) && value.size == 1
        value = value.to_s if value.is_a?(Symbol)
        value = value[:color] if value.is_a?(Hash) && value[:color]
        result = if value.is_a?(Array)
          old_value = value
          value = {
            r: value[0],
            g: value[1],
            b: value[2],
          }
          value[:a] = value[3] unless value[3].nil?
          value
        elsif value.is_a?(Hash)
          old_value = value
          value = old_value.dup
          value[:r] = value.delete(:red) if value[:red]
          value[:g] = value.delete(:green) if value[:green]
          value[:b] = value.delete(:blue) if value[:blue]
          value[:a] = value.delete(:alpha) if value[:alpha]
          value
        elsif value.is_a?(String) && !value.start_with?('0x') && !value.downcase.match(/^((([1-9a-f]){6})|(([1-9a-f]){3}))$/)
          color = Color::RGB.extract_colors(value).first
          color.nil? ? {} : {
            r: color.red,
            g: color.green,
            b: color.blue,
          }
        else
          hex_to_rgb(value)
        end
        result.merge!(options) if options
        result
      end
    
      def hex_to_rgb(value)
        if value.is_a?(String)
          if !value.start_with?('0x')
            value = value.chars.map {|char| [char, char]}.flatten.join if value.length == 3
            value = "0x#{value}"
          end
          value = value.to_i(16)
        end
        if value.is_a?(Integer)
          hex_value = value
          value = {
            r: ((hex_value >> 16) & 0xFF),
            g: ((hex_value >> 8) & 0xFF),
            b: (hex_value & 0xFF),
          }
        end
        value
      end
      
      # Returns ruby underscored symbols for enum values starting with enum name (camelcase, e.g. 'ext_key')
      def enum_symbols(enum_name)
        enum_name = enum_name.to_s.underscore.to_sym
        @enum_symbols ||= {}
        @enum_symbols[enum_name] ||= ::LibUI.constants.select { |c| c.to_s.start_with?(enum_name.to_s.camelcase(:upper)) }.map { |c| c.to_s.underscore.sub("#{enum_name}_", '').to_sym }
      end
      
      def enum_symbol_to_value(enum_name, enum_symbol, default_index: 0)
        if enum_symbol.is_a?(Integer)
          enum_symbol
        elsif enum_symbols(enum_name).include?(enum_symbol.to_s.to_sym)
          ::LibUI.const_get("#{enum_name}_#{enum_symbol}".camelcase(:upper))
        else
          enum_symbol_to_value(enum_name, enum_symbols(enum_name)[default_index])
        end
      end
      
      def queue_main(&block)
        closure = fiddle_closure_block_caller(4, [0]) do
          block.call
          1
        end
        ::LibUI.queue_main(closure)
      end
      
      def timer(time_in_seconds, &block)
        closure = fiddle_closure_block_caller(4, [0]) do
          block.call
          1
        end
        ::LibUI.timer(time_in_seconds * 1000.0, closure)
      end
    end
  end
end
