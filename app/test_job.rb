class TestJob

  def run(request)
    1.upto(100_000_000) do |i|
    end
    "TestJobRan" + request.headers.inspect
  end

end
