module Wolfpack

  class Response

    def initialize(queue)
      @queue = queue
      @body = StringIO.new
      @status = nil
      @headers = {}
      @sent_status = false
      @sent_body = false
    end

    def status(code, message)
      if @status
        raise Exception.new("Already set status")
      end
      @status = ["HTTP/1.1", code, message].join(" ") # TODO: Check if I am lying about HTTP/1.1
    end

    def header(k, v)
      if @sent_headers
        raise Exception.new("Already sent headers")
      end
      @headers[k] = v
    end

    def write(data)
      @body << data
    end

    def flush
      if !@status
        status(200, "OK")
      end
      response = StringIO.new
      if !@sent_status
        response << @status << "\n"
        @sent_status = true
      end
      if !@sent_body && !@headers.empty?
        @headers.each do |k, v|
          response << k + ": " + v + "\n"
        end
        @headers.clear
      end
      if response.size > 0
        @queue.emit(response.string)
      end
      if @body.size > 0
        if !@sent_body
          @queue.emit("\n" + @body.string)
        else
          @queue.emit(@body.string)
        end
        @sent_body = true
      end
    end

  end

end
