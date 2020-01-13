require "spec"
require "../src/timeouter"

def should_spend(timeout, delta = timeout / 5.0)
  t = Time.local
  res = yield
  delta = 0.02 if delta < 0.02
  (Time.local - t).to_f.should be_close(timeout, delta)
  res
end

Spec.before_each do
  Timeouter.clear
end
