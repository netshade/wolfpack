module Wolfpack

  class Request

    attr_accessor :headers, :request_method, :request_uri, :fragment, :request_path, :query_string, :http_version, :header_done

    def initialize()
      @headers = {}
    end

  end

end
