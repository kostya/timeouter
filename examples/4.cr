require "../src/timeouter"

ch = Channel(Int32).new

5.times do
  spawn do
    val = Timeouter.receive_with_timeout(ch, 1.second)
    p val
  end
end

spawn do
  loop do
    10.times do |i|
      Timeouter.send_with_timeout(ch, i, 1.second)
    end
  end
end

sleep 3.0
