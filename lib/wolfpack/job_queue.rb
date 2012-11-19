require 'thread'
require 'wolfpack/response'
java_import java.util.concurrent.Executors
java_import java.util.concurrent.Semaphore

module Wolfpack

  class Job
    def initialize(job_klass, request, observers, job_queue)
      @klass = job_klass
      @request = request
      @observers = observers
      @queue = job_queue
      @response = Wolfpack::Response.new(observers)
    end

    def call()
      job = @klass.new()
      job.run(@request, @response)
      @response.flush
      @observers.close
    rescue Exception => e
      puts "ERROR: %s\n%s" % [e.message, e.backtrace.join("\n")]
      begin
        @response.status(500, "INTERNAL ERROR")
        @response.write("%s\n%s\n" % [e.message, e.backtrace.join("\n")])
        @response.flush
        @observers.close
      rescue Exception => ex
        puts "INTERNAL ERROR\n%s\n%s" % [ex.message, ex.backtrace.join("\n")]
      end
    ensure
      EM::next_tick do
        @queue.remove(@klass, @observers) # TODO: this pattern is falling apart, think of something better
      end
    end
  end

  class ObserverQueue

    def initialize()
      @clients = []
      @semaphore = Semaphore.new(1)
      @accepting = true
    end

    def stop_accepting!
      @accepting, original = false, @accepting
      if original
        @semaphore.acquire
      end
    end

    # When emit is first called it stops this particular queue from accepting clients
    # to allow jobs to start writing results directly to queued clients
    # Not sure if I should do it this way or keep the results buffered and keep accepting
    # clients.  TODO: Benchmark / investigate
    def emit(data)
      stop_accepting!
      @clients.each do |observer|
        observer.safewrite(data)
      end
    end


    def close()
      stop_accepting!
      @clients.each do |observer|
        observer.safeclose
      end
    end

    def add(observer)
      if @semaphore.tryAcquire
        @clients << observer
        @semaphore.release
        true
      else
        false
      end
    end
    alias_method :<<, :add

    def size
      @clients.size
    end

  end

  class JobQueue

    def initialize
      @observers = {}
      #@thread_pool = Executors.newFixedThreadPool(4)
      @thread_pool = Executors.newCachedThreadPool
    end

    def enqueue(job_klass, request, client)
      @observers[job_klass] ||= []
      if last_queue = @observers[job_klass].last
        if !last_queue.add(client)
          last_queue = nil
        end
      end
      if !last_queue
        last_queue = ObserverQueue.new
        last_queue.add(client)
        @observers[job_klass] << last_queue
        @thread_pool.submit Job.new(job_klass, request, last_queue, self)
      end
    end

    def remove(klass, observers)
      if @observers[klass]
        @observers[klass].delete(observers)
        puts "Served %i requests" % [observers.size]
      end
    end

  end

end
