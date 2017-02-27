module Timeouter
  VERSION = "0.1"

  # Simple linked list
  class Node
    property right : Node?
    property left : Node?

    @expire_at : Time

    getter channel : Channel::Buffered(Bool)
    getter added_at

    def initialize(interval : Time::Span)
      @added_at = Time.now
      @expire_at = @added_at + interval
      @channel = Channel::Buffered(Bool).new(1)
    end

    def closed?
      @channel.closed?
    end

    def expired?(now = Time.now)
      now > @expire_at
    end

    def timeout!
      @channel.send(true)
    rescue Channel::ClosedError
    ensure
      @channel.close
    end
  end

  @@root : Node = Node.new(-1.0.seconds)
  @@runned = false
  @@precision : Time::Span = 1.second
  @@count = 0

  def self.precision
    @@precision
  end

  def self.precision=(i)
    @@precision = i
  end

  def self.count
    @@count
  end

  def self.background_run
    return if @@runned
    @@runned = true
    spawn do
      loop do
        free_expired_tasks
        sleep(precision)
      end
    end
  end

  def self.free_expired_tasks
    return if @@count == 0
    now = Time.now
    self.each do |node|
      if node.closed?
        del(node)
      elsif node.expired?(now)
        node.timeout!
        del(node)
      end
    end
  end

  private def self.add(node)
    right = @@root.right

    if right
      right.left = node
    end

    @@root.right = node
    node.left = @@root
    node.right = right

    @@count += 1
  end

  private def self.del(node)
    if left = node.left
      left.right = node.right
    end

    if right = node.right
      right.left = node.left
    end

    @@count -= 1
  end

  def self.each
    node = @@root
    while node = node.right
      yield node
    end
  end

  def self.stats
    min_at = nil
    each do |node|
      min_at = node.added_at if !min_at || (node.added_at < min_at)
    end
    oldest_wait_interval = if min_at
                             (Time.now - min_at).to_f
                           end
    {tasks: @@count, oldest: oldest_wait_interval}
  end

  # User methods

  def self.after(span : Time::Span)
    node = Node.new(span)
    add(node)
    background_run
    node.channel
  end

  def self.receive_with_timeout(ch, span : Time::Span)
    timeouter_channel = after(span)
    select
    when val = ch.receive
      timeouter_channel.close
      val
    when timeouter_channel.receive
      nil
    end
  end

  def self.send_with_timeout(ch, value, span : Time::Span)
    timeouter_channel = after(span)
    select
    when ch.send(value)
      timeouter_channel.close
      true
    when timeouter_channel.receive
      nil
    end
  end
end
