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
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# require "spec_helper"
# require_relative "../../helpers/transporters"
# require_relative "../../../lib/polyn/transporters/pubsub"

# RSpec.describe Polyn::Transporters::Pubsub do
#   include_examples "a transporter" do
#     let(:options) do
#       {
#         project_id:    "test-project",
#         emulator_host: "localhost:8085",
#       }
#     end

#     let(:pubsub_client) { Google::Cloud::Pubsub.new(**options) }

#     before :each do
#       topic   = pubsub_client.topic("test-topic")
#       topic ||= pubsub_client.create_topic("test-topic")

#       subscription   = pubsub_client.subscription("test-topic")
#       topic.subscribe("test-test-topic") unless subscription
#     end

#     after :each do
#       pubsub_client.subscription("test-test-topic")&.delete
#       pubsub_client.topic("test-topic")&.delete
#     end

#     describe "#connect!" do
#       it "should raise Polyn::Transporters::Errors::TimeoutError when a time out occurs during connect" do
#         expect_any_instance_of(Google::Cloud::PubSub::Project).to receive(:topics)
#           .and_raise(Google::Cloud::DeadlineExceededError)

#         expect { subject.connect! }.to raise_exception(Polyn::Transporters::Errors::TimeoutError)
#       end

#       it "should connect to the pubsub instance without exception when a timeout does not occur" do
#         expect { subject.connect! }.not_to raise_exception
#       end
#     end

#     describe "#publish" do
#       before :each do
#         subject.connect!

#         topic   = pubsub_client.topic("test-topic")
#         pubsub_client.create_topic("test-topic") unless topic
#       end

#       after :each do
#         subject.disconnect!

#         pubsub_client.topic("test-topic")&.delete
#       end

#       it "should raise Polyn::Transporters::Errors::TimeoutError when a time out occurs during publish" do
#         expect_any_instance_of(Google::Cloud::PubSub::Topic).to receive(:publish)
#           .and_raise(Google::Cloud::DeadlineExceededError)

#         expect do
#           subject.publish!("test-topic",
#             "test-message")
#         end.to raise_exception(Polyn::Transporters::Errors::TimeoutError)
#       end

#       it "should publish a message to the pubsub instance without exception when a timeout does not occur" do
#         expect do
#           subject.publish!("test-topic",
#             "test-message")
#         end.not_to raise_exception
#       end
#     end

#     describe "#subscribe" do
#       it "should raise Polyn::Transporters::Errors::TimeoutError when a time out occurs during subscribe" do
#         expect_any_instance_of(Google::Cloud::PubSub::Subscription).to receive(:listen)
#           .and_raise(Google::Cloud::DeadlineExceededError)

#         expect do
#           subject.subscribe!("test", "test-topic")
#         end.to raise_exception(Polyn::Transporters::Errors::TimeoutError)
#       end

#       it "raises a Polyn::Transporters::Errors::TopicNotFoundError when the topic does not exist" do
#         expect do
#           subject.subscribe!("test", "test-non-topic")
#         end.to raise_exception(Polyn::Transporters::Errors::TopicNotFoundError)
#       end

#       it "should subscribe to the pubsub instance without exception when a timeout does not occur" do
#         expect do
#           subject.subscribe!("test", "test-topic")
#         end.not_to raise_exception
#       end
#     end
#   end
# end
