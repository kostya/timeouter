require "../src/timeouter"

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
