require 'java'
require 'wolfpack/request'

module Wolfpack

  class Parser
    java_import org.jruby.mongrel.Http11Parser
    java_import org.jruby.util.ByteList

    class ElementOutputter
      include Http11Parser::ElementCB

      def initialize(input, &block)
        @block = block
        @input = input
      end

      def call(data, at, length)
        @block.call(@input[at..at+length])
      end
    end

    class FieldOutputter
      include Http11Parser::FieldCB

      def initialize(input, &block)
        @block = block
        @input = input
      end

      def call(data, field, flen, value, vlen)
        @block.call(@input[field..field+(flen-1)], @input[value..value+vlen].chomp)
      end
    end

    attr_reader :request

    def initialize()
      @offset = 0
    end

    def parse(input)
      if !@parser
        @parser = Http11Parser.new
        @request = Wolfpack::Request.new
        @parser.parser.request_method = ElementOutputter.new(input) { |v| @request.request_method = v }
        @parser.parser.http_field = FieldOutputter.new(input) { |k, v| @request.headers[k] = v }
        @parser.parser.request_uri = ElementOutputter.new(input) { |v| @request.request_uri = v }
        @parser.parser.fragment = ElementOutputter.new(input) { |v| @request.fragment = v }
        @parser.parser.request_path = ElementOutputter.new(input) { |v| @request.request_path = v }
        @parser.parser.query_string = ElementOutputter.new(input) { |v| @request.query_string = v }
        @parser.parser.http_version = ElementOutputter.new(input) { |v| @request.http_version = v }
        @parser.parser.header_done = ElementOutputter.new(input) { |v| @request.header_done = v }
        @parser.parser.init
      end
      bts = ByteList.new
      bts.append(ByteList.plain(input))
      @parser.execute(bts, @offset)
      @offset += input.size
    end

    def error?
      @parser.has_error
    end

    def finished?
      @parser.is_finished
    end
  end

end