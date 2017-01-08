# Timeouter

Simple timeouter for crystal lang. Used one coroutine which triggered with precision interval. Also it avoid crystal memory leak with many coroutines: https://github.com/crystal-lang/crystal/issues/3333

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  timeouter:
    github: kostya/timeouter
```

## Usage

```crystal
require "timeouter"

Timeouter.precision = 0.5.seconds # set precision, 1 second by default

# receive from single channel with timeout
channel = Channel(Int32).new
after = Timeouter.after(1.0.seconds)

spawn do
  sleep 10.0
  channel.send(1)
end

t = Time.now

select
when result = channel.receive
  # Cancel timeouter (it also would be cancel automatically, but this remove it fast from scheduler)
  after.close
  p result
when after.receive
  channel.close
  p :timeouted
end

p Time.now - t

# => :timeouted
```

## Helper receive_with_timeout

```crystal
require "timeouter"

Timeouter.precision = 0.1.seconds

ch = Channel(Int32).new

spawn { loop { sleep 1.0; ch.send(rand(1000)) } }

p Timeouter.receive_with_timeout(ch, 0.5.seconds) # => nil

p Timeouter.receive_with_timeout(ch, 1.5.seconds) # => 1562
```
