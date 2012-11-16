require 'thread'
java_import java.util.concurrent.Executors
java_import java.util.concurrent.Semaphore

module Wolfpack

  class Job
    def initialize(job_klass, request, args, observers)
      @klass = job_klass
      @request = request
      @observers = observers
      @arguments = args
    end

    def call()
      job = @klass.new(*@arguments)
      if job.respond_to?(:run)
        result = job.run(@request)
      else
        result = ""
      end
      unless result.is_a?(Array)
        result = [200, {}, result]
      end
      @observers.notify(result)
    rescue Exception => e
      puts "ERROR: %s\n%s" % [e.message, e.backtrace.join("\n")]
      @callback.call [500, {}, "ERROR"]
    end
  end

  class JobObserver

    def initialize(block)
      @callback = block
    end

    def notify(result)
      @callback.call result
    end

  end

  class ObserverQueue

    def initialize()
      @queue = Queue.new
      @semaphore = Semaphore.new(1)
      @acquired = false
    end

    def notify(result)
      served = 0
      while @queue.size > 0
        observer = @queue.pop
        observer.notify(result)
        served += 1
      end
    ensure
      if @acquired
        @acquired = false
        @semaphore.release
      end
    end

    def add(observer)
      @queue << observer
    end
    alias_method :<<, :add

    def call_if_ready(&block)
      if @semaphore.tryAcquire
        @acquired = true
        yield
      end
    end

  end

  class JobQueue

    def initialize
      @queue = Queue.new
      @observers = {}
      @thread_pool = Executors.newCachedThreadPool
    end

    def enqueue(job_klass, request, *args , &block)
      @observers[job_klass] ||= ObserverQueue.new
      observer = JobObserver.new(block)
      @observers[job_klass] << observer
      @observers[job_klass].call_if_ready do
        @thread_pool.submit Job.new(job_klass, request, args, @observers[job_klass])
      end
    end

  end

end
