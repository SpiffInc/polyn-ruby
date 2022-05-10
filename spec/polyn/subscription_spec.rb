# frozen_string_literal: true

# Copyright 2021-2022 Spiff, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILTY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require_relative "../../lib/polyn/subscription"

RSpec.describe Polyn::Subscription do
  let(:nats) { NATS.connect }

  let(:transit) do
    Class.new do
      attr_reader :args

      def ev
        @ev ||= Concurrent::Event.new
      end

      def <<(args)
        @args = args
        ev.set
      end
    end.new
  end

  let(:js) { nats.jetstream }
  let(:sub) do
    js.add_stream(name: "test")
    js.pull_subscribe("test", "test")
  end

  subject { Polyn::Subscription.spawn(transit, sub) }

  it "consumes messages and passes them to the transit bus" do
    subject.start
    js.publish("test", "test")

    transit.ev.wait

    expect(transit.args).to match_array([:receive, [a_kind_of(NATS::Msg)]])
  end
end
