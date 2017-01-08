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

# set precision, 1 second by default
Timeouter.precision = 0.5.seconds

# spend 1.5.second
Timeouter.after(1.5.seconds).receive
```

## Helper: receive from Channel with timeout

```crystal
require "timeouter"

ch1 = Channel(Int32).new
ch2 = Channel(Int32).new

spawn do
  sleep 2.0
  ch1.send(1)
end

spawn do
  sleep 0.5
  ch2.send(2)
end

p Timeouter.receive_with_timeout(ch1, 1.seconds) # => nil
p Timeouter.receive_with_timeout(ch2, 1.seconds) # => 2
```

## Receive from channel with timeout manually
```crystal
require "timeouter"

channel = Channel(Int32).new
after = Timeouter.after(1.0.seconds)

spawn do
  sleep 10.0
  channel.send(1)
end

t = Time.now

select
when result = channel.receive
# Cancel timeouter manyally
#   it also would be cancel automatically
#   but this is remove it fast from scheduler
#   which allow less cpu usage
  after.close

  p result
when after.receive
  p :timeouted
end

p Time.now - t

# => :timeouted
# => 1.000
```
