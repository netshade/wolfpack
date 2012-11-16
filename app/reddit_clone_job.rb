class RedditCloneJob

  def run(request)
    `curl http://www.reddit.com`.chomp # ;)
  end

end
