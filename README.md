# Polyn
[![Ruby](https://github.com/SpiffInc/polyn-ruby/actions/workflows/ruby.yml/badge.svg)](https://github.com/SpiffInc/polyn-ruby/actions/workflows/ruby.yml)

Polyn is a dead simple service framework designed to be language agnostic while
and providing a simple, yet powerful, abstraction layer for building reactive events
based services. It is heavily inspired by [Akka](https://akka.io) and [Moleculer](https://moleculer.services), and
attempts to closely follow the [Reactive Manifesto](http://jonasboner.com/reactive-manifesto-1-0/) by adhering to the
following principles:

1. Follow the principle “do one thing, and one thing well” in defining service boundaries
2. Isolate the services
3. Ensure services act autonomously
4. Embrace asynchronous message passing
5. Stay mobile, but addressable
6. Design for the required level of consistency

Polyn implements this pattern in a manner that can be applied to multiple programming
languages, such as Ruby, Elixir, or Python, enabling you to build services that can
communicate regardless of the language you use.

Rather than defining its own event schema, Polyn uses [Cloud Events](https://github.com/cloudevents/spec) and strictly enforces the event format.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'polyn'
```

And then execute:

    $ bundle install

## Schema Creation

In order for Polyn to process and validate event schemas you will need to use [Polyn CLI](https://github.com/SpiffInc/polyn-cli) to create an `events` codebase. Once your `events` codebase is created you can create and manage your schemas there.

## Configuration

Use a configuration block to setup Polyn and NATS for your application

### `domain`

The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#type) specifies that every event "SHOULD be prefixed with a reverse-DNS name." This name should be consistent throughout your organization.

### `source_root`

  The [Cloud Event Spec](https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/spec.md#source-1) specifies that every event MUST have a `source` attribute and recommends it be an absolute [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier). Your application must configure the `source_root` to use for events produced at the application level. Each event producer can include its own `source` to append to the `source_root` if it makes sense.

```ruby
Polyn.configure do |config|
  config.domain = "app.spiff"
  config.source_root= "orders.payments"
end
```

## Usage

### Publishing Messages

Use `Polyn.publish` to publish new events to the server

```ruby
require "nats/client"
require "polyn"

nats = NATS.connect
polyn = Polyn.connect(nats)

polyn.publish("user.created.v1", { name: "Mary" })
```

Add `:source` to make the `source` of the event more specific


```ruby
polyn.publish("user.created.v1", { name: "Mary" }, source: "new.users")
```

You can also include options of `:header` and/or `:reply_to` to passthrough to NATS

### Consuming a Stream

```ruby
require "nats/client"
require "polyn"

nats = NATS.connect
polyn = Polyn.connect(nats)

psub = Polyn.pull_subscribe("user.created.v1")

loop do
  msgs = psub.fetch(5)
  msgs.each do |msg|
    msg.ack
  end
end
```

Polyn assumes you've already used [Polyn CLI](https://github.com/SpiffInc/polyn-cli) to generate a consumer.

Add the `:source` option to `pull_subscribe` if your consumer name includes more than just the `source_root`. Polyn automatically finds the consumer name from the `type` you pass in.
If your `source_root` was `user.backend` and the event type was `user.created.v1` it would look for a consumer named `user_backend_user_created_v1`. If your consumer had a more specific destination such as `notifications` you could pass that as the `:source` option and the consumer name lookup would use `user_backend_notifications_user_created_v1`.

### Subscribing to a message

```ruby
require "nats/client"
require "polyn"

nats = NATS.connect
polyn = Polyn.connect

sub = polyn.subscribe("user.created.v1") { |msg| puts msg.data }
```

`Polyn.subscribe` will process the block you pass it asynchronously in a separate thread

#### Errors

For most methods, `Polyn` will raise if there is a validation problem. The `subscribe` method from `nats-pure` handles the callback in a separate thread and rescues any errors in an attempt to reconnect. If you want to get Polyn errors handled for `subscribe` you need to call `nats.on_error { |e| raise e }` on your connection instance to tell `nats-pure` how to handle those errors.

```ruby
require "nats/client"

nats = NATS.connect
nats.on_error { |e| raise e }
polyn = Polyn.connect(nats)

sub = polyn.subscribe("user.created.v1") { |msg| puts msg.data }
```

## Testing

### Setup

Set an environment variable of `POLYN_ENV=test` or `RAILS_ENV=test`.

Add the following to your `spec_helper.rb`

```ruby
require "polyn/testing"

Polyn::Testing.setup
```

Add the following to individual test files `include_context :polyn`

### Test Isolation

Following the test setup instructions replaces *most* `Polyn` calls to NATS with mocks. Rather than hitting a real nats-server, the mocks will create an isolated sandbox for each test to ensure that message passing in one test is not affecting any other test. This will help prevent flaky tests and race conditions. It also makes concurrent testing possible. The tests will also all share the same schema store so that schemas aren't fetched from the nats-server repeatedly.

Despite mocking some NATS functionality you will still need a running nats-server for your testing.
When the tests start it will load all your schemas. The tests themselves will also use the running server to verify
stream and consumer configuration information. This hybrid mocking approach is intended to give isolation and reliability while also ensuring correct integration.

## Observability

### Tracing

Polyn uses [OpenTelemetry](https://opentelemetry.io/) to create distributed traces that will connect sent and received events in different services. Your application will need the [`opentelemetry-sdk` gem](https://opentelemetry.io/docs/instrumentation/ruby/getting-started/) installed to collect the trace information.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push git
commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SpiffInc/polyn-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/SpiffInc/polyn-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Polyn project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SpiffInc/polyn-ruby/blob/main/CODE_OF_CONDUCT.md).
