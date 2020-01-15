require "./spec_helper"

Timeouter.precision = 0.1.seconds

def send_after(ch, interval, value)
  spawn do
    sleep interval
    begin
      ch.send(value)
    rescue Channel::ClosedError
    end
  end
end

describe Timeouter do
  it "just after" do
    ch = Timeouter.after(0.5.seconds)
    should_spend(0.5) do
      ch.receive.should eq true
    end
    Timeouter.count.should eq 0
  end

  it "aftered with select" do
    ch1 = Channel(Int32).new
    ch2 = Timeouter.after(0.5.seconds)
    Timeouter.count.should eq 1

    send_after(ch1, 0.7, 11)

    should_spend(0.5) do
      x = nil
      t = Time.local
      select
      when y = ch1.receive
        ch1.close
        x = y
      when ch2.receive
        ch1.close
        x = 1
      end

      x.should eq 1
    end

    sleep 0.3

    Timeouter.count.should eq 0
  end

  it "ok with select" do
    ch1 = Channel(Int32).new
    ch2 = Timeouter.after(0.5.seconds)
    Timeouter.count.should eq 1

    send_after(ch1, 0.3, 11)

    should_spend(0.3) do
      x = nil
      t = Time.local
      select
      when y = ch1.receive
        ch2.close
        x = y
      when ch2.receive
        ch1.close
        x = 1
      end

      x.should eq 11
    end

    sleep 0.3

    Timeouter.count.should eq 0
  end

  it "aftered with select" do
    ch1 = Channel(Int32).new

    send_after(ch1, 0.7, 11)

    should_spend(0.5) do
      x = nil
      t = Time.local
      select
      when y = ch1.receive
        ch1.close
        x = y
      when Timeouter.after(0.5.seconds).receive
        ch1.close
        x = 1
      end

      x.should eq 1
    end

    sleep 0.3

    Timeouter.count.should eq 0
  end

  it "ok with select" do
    ch1 = Channel(Int32).new

    send_after(ch1, 0.3, 11)

    should_spend(0.3) do
      x = nil
      t = Time.local
      select
      when y = ch1.receive
        ch1.close
        x = y
      when Timeouter.after(0.5.seconds).receive
        ch1.close
        x = 1
      end

      x.should eq 11
    end

    sleep 0.3

    Timeouter.count.should eq 0
  end

  it "multiple tasks" do
    ch1 = Timeouter.after(0.5.seconds)
    ch2 = Timeouter.after(0.3.seconds)
    ch3 = Timeouter.after(0.7.seconds)

    res = Channel(Int32).new

    spawn do
      select
      when ch1.receive
        res.send 1
      end
    end

    spawn do
      select
      when ch2.receive
        res.send 2
      end
    end

    spawn do
      select
      when ch3.receive
        res.send 3
      end
    end

    c = [] of Int32

    should_spend(0.7) do
      3.times { c << res.receive }
    end

    c.should eq [2, 1, 3]

    Timeouter.count.should eq 0
  end

  it "1000 tasks" do
    1000.times do
      Timeouter.after(0.2.seconds)
    end

    Timeouter.to_a.size.should eq 1000
    Timeouter.stats[:tasks].should eq 1000

    sleep 0.3

    Timeouter.to_a.size.should eq 0
  end

  context "with" do
    it "receive_with_timeout" do
      ch = Channel(Int32).new
      should_spend(0.5) do
        val = Timeouter.receive_with_timeout(ch, 0.5.seconds)
        val.should eq nil
      end
    end

    it "receive_with_timeout" do
      ch = Channel(Int32).new
      send_after(ch, 0.3, 11)
      should_spend(0.3) do
        val = Timeouter.receive_with_timeout(ch, 0.5.seconds)
        val.should eq 11
      end
    end

    it "send_with_timeout" do
      ch = Channel(Int32).new
      v = nil

      spawn do
        sleep 0.7
        v = ch.receive
      end

      should_spend(0.5) do
        val = Timeouter.send_with_timeout(ch, 11, 0.5.seconds)
        val.should eq nil
      end

      v.should eq nil
    end

    it "send_with_timeout" do
      ch = Channel(Int32).new
      v = nil

      spawn do
        sleep 0.3
        v = ch.receive
      end

      should_spend(0.3) do
        val = Timeouter.send_with_timeout(ch, 11, 0.5.seconds)
        val.should eq true
      end

      v.should eq 11
    end
  end
end
