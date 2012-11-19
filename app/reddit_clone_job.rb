class RedditCloneJob

  def run(request, response)
    response.status("200", "OK")
    response.write(`curl http://www.reddit.com`.chomp) # ;)
  end

end
