# WOLFPACK

Wolfpack is an experiment in trying to take advantage of the fact that on a highly loaded public website, many of the reqests are for the same content. As requests arrive for a specific piece of content, the first request in creates a `Job` to service that request; all simultaneous requests for that content then queue for the result, allowing simultaneous requests for content to be serviced by only a single result.

## WHY DO THIS

The Indy.rb meeting that spawned this asked attendees to create a Reddit clone using several different microframeworks.  All the frameworks discussed defaulted to a few general assumptions when it comes to how a Ruby web framework should operate:

* Model View Controller pattern or HTTP method-like DSL
* No concurrency
* HTTP request serving is the responsibility of a different entity

The interesting part of creating a Reddit clone to me was finding ways to optimize how they serve requests. Reddits traffic is immense, and at at that level of traffic it seemed there might be ways to exploit their traffic patterns to utilize a server machine's resources to the fullest extent.

### NO SERIOUSLY

Okay I like threads

## IS IT AWESOME?

Not really.  It's just some neat ideas right now, cobbled together with code.  I've only put an extra hour or two into it after the Indy.rb meeting, so right now its pretty much good for generating microbenchmarks and playing around with `java.util.concurrent` + JRuby

## WHY JRUBY

JRuby will actually run threads on separate CPUs, so its closer to the thing I intended: saturating a server's CPUs with actual work as opposed to just sitting on a single process and taking advantage of CPU idle.

## SO IS THIS THREAD PER REQUEST?

Sort of, right now. More like 1 Thread == 1 Unique Request for the Duration of The Work Completed Which May Have Many Other Requests Simultaneously Interested In The Results Of That Request. But basically thread per request at the moment until I do something smarter.

## YOU MENTIONED MODEL VIEW CONTROLLER WAS CLOWN SHOES

Well yeah. I'm just bored of the pattern, and it felt interesting to try visualizing web framework work as Jobs.  The code will likely effectively be the same, but I think using separate terminology and basic structure in cases like this will cause me to think differently about how to send back responses.

## HOW DO I PLAY WITH THIS

There is some super basic router code in `config/router.yml`.  It's a big hash where the keys are `Regexp` strings that match request paths, and the values are constants that live in `app/`. Create a basic Ruby class in `app/` that has a `#run` method that accepts a single parameter, `request`.  The return value can either be a basic string, or an array that is [status code `int`, headers `hash`, response body `string`]. Then just run `bin/start.rb` and hit port 1337 (Yes, I'm a child, I know) with `curl` or `ab`.  (I've been using `ab` to benchmark / test the parallelism stuff, would recommend that)

## WHAT ARE YOU PLANNING ON IMPLEMENTING

Right now URLs are tied to a single job, and I'd like to change that to chains of jobs.  I'd also like to add parallelism hints to the jobs so that I could do more intelligent request grouping ( or not doing it if it's not an option on certain requests ).  I'd also like jobs to be able to emit data at any point, as opposed to using return values to inform the data.  I also want to make some comparative benchmarks against traditional Ruby app servers to gauge whether or not this is even a good idea or just me playing with JRuby.

## CAN I ADD STUFF

Please! Play around, this is just an experiment.
