require 'wolfpack/job_queue'
require 'wolfpack/parser'
require 'wolfpack/router'

module Wolfpack

  class HttpClient < EventMachine::Connection

    attr_reader :server

    def initialize(srv)
      super
      @server = srv
      @parser = Wolfpack::Parser.new
    end

    def receive_data(data)
      @parser.parse(data)
      if @parser.error?
        send_data("500 FUUUUUU\n")
        close_connection_after_writing
      else
        if @parser.finished?
          job_klass = server.recognize(@parser.request.request_path)
          @server.enqueue(job_klass, @parser.request) do |result|
            status, headers, body = result
            headers["Content-Length"] ||= body.size
            header_str = headers.collect { |k, v| "%s: %s" % [k, v] }.join("\n")
            send_data("HTTP/1.1 #{status}\n" +
              header_str + "\n\n" +
              body
            )
            close_connection_after_writing
          end
        end
      end
    end
  end

  class Server

    def initialize(router_file)
      @queue = Wolfpack::JobQueue.new
      @router = Wolfpack::Router.new(router_file)
    end

    def recognize(uri)
      @router.recognize(uri)
    end

    def enqueue(sender, request, &block)
      @queue.enqueue(sender, request) do |args|
        EM::next_tick do
          block.call(args)
        end
      end
    end

    def run
      EventMachine.run {
        EventMachine.start_server '0.0.0.0', 1337, Wolfpack::HttpClient, self
      }
    end

  end

end
