require "spec"
require "../src/timeouter"

def should_spend(timeout, delta = timeout / 5.0)
  t = Time.now
  res = yield
  delta = 0.02 if delta < 0.02
  (Time.now - t).to_f.should be_close(timeout, delta)
  res
end
