require "../src/timeouter"

Timeouter.precision = 0.1.seconds

ch = Channel(Int32).new

spawn { loop { sleep 1.0; ch.send(rand(1000)) } }

p Timeouter.receive_with_timeout(ch, 0.5.seconds) # => nil

p Timeouter.receive_with_timeout(ch, 1.5.seconds) # => 1562
