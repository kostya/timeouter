require "../src/timeouter"

ch1 = Channel(Int32).new
ch2 = Channel(Int32).new

spawn do
  sleep 2.0
  p ch1.receive
end

spawn do
  sleep 0.5
  p ch2.receive
end

Timeouter.send_with_timeout(ch1, 1, 1.seconds) # => nil
Timeouter.send_with_timeout(ch2, 2, 1.seconds) # => true

# 2
