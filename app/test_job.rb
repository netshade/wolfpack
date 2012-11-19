class TestJob

  def run(request, response)
    response.status(200, "OK")
    response.write("TestJobRan!" + request.headers.inspect)
  end

end
