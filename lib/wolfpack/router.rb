module Wolfpack

  class Router

    def initialize(router_file)
      @data = YAML.load(File.read(router_file))

      @data = Hash[@data.collect do |k, v|
        components = v.split("::")
        klass = Kernel
        while (name = components.shift)
          klass = klass.const_get(name)
        end
        if klass != Kernel
          [Regexp.new(k), klass]
        else
          raise Exception.new("Could not find class %s" % v)
        end
      end]
    end

    def recognize(str)
      result = @data.detect do |k, v|
        k.match(str)
      end
      if result
        result.last
      end
    end

  end

end