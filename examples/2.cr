require "../src/timeouter"

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
