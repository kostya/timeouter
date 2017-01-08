require "../src/timeouter"

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
