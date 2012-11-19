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
      @closed = false
    end

    def receive_data(data)
      @parser.parse(data)
      if @parser.error?
        send_data("400 BAD REQUEST\n")
        close_connection_after_writing
      else
        if @parser.finished?
          job_klass = server.recognize(@parser.request.request_path)
          @server.enqueue(job_klass, @parser.request, self)
        end
      end
    end

    def safewrite(data)
      EM::next_tick do
        if !@closed
          send_data(data)
        end
      end
    end

    def safeclose()
      EM::next_tick do
        if !@closed
          close_connection_after_writing
        end
      end
    end

    def unbind
      @closed = true
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

    def enqueue(sender, request, client)
      @queue.enqueue(sender, request, client)
    end

    def run
      EM.epoll
      EM.set_descriptor_table_size( 64_000 )
      EventMachine.run {
        EventMachine.start_server '0.0.0.0', 1337, Wolfpack::HttpClient, self
      }
    end

  end

end
