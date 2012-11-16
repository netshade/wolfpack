class TestJob

  def run(request)
    "TestJobRan!" + request.headers.inspect
  end

end
