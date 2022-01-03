# Polyn
[![Ruby](https://github.com/SpiffInc/polyn-ruby/actions/workflows/ruby.yml/badge.svg)](https://github.com/SpiffInc/polyn-ruby/actions/workflows/ruby.yml)

Polyn is a dead simple service framework designed to be language agnostic while
and providing a simple, yet powerful, abstraction layer for building reactive events
based services.

According to [Jonas Boner](http://jonasboner.com/), reactive Microservices require you to:
1. Follow the principle “do one thing, and one thing well” in defining service boundaries
2. Isolate the services
3. Ensure services act autonomously
4. Embrace asynchronous message passing 
5. Stay mobile, but addressable 
6. Design for the required level of consistency

Polyn implements this pattern in a manner that can be applied to multiple programming
languages, such as Ruby, Elixir, or Python, enabling you to build services that can
communicate regardless of the language you use.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'polyn'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install polyn

## Usage

A Polyn `Application` is made up of one or more `Services`, where a service subscribes
to one or more events.

## Configuration

| Key | Type | Required | Default                           | Description                             |
| --- | --- | --- |-----------------------------------|-----------------------------------------|
| `:name` | `String` | true |                                   | The name of the application             |
| `:services` | `Array` | true |                                   | An array of `Polyn::Service` subclasses |
| `:validator` | `Polyn::Validators::Base` | true | |  The event schem validator to use       |
| :transit | `Hash` | true |                                   || The transit options to use |

## Services

Services are built by sublcassing the `Polyn::Service` class. An example email service
would look like:

```ruby
class EmailService < Polyn::Service
  event "user.added", :send_welcome_email
  event "user.updated", :send_update_email
  
  
  def send_update_email(context)
    user = User.where(context.params.user_id)
    UserMailer.with(user: user).update_email.deliver_now
  end
  
  def send_welcome_email(context)
    user = User.where(context.params.user_id)
    UserMailer.with(user: user).welcome_email.deliver_now
  end
end
```

Now lets look at what happens when a user is added:

```ruby
class User < ApplicationRecord
  after_create :publish_user_created
  after_update :publish_user_updated
  
  
  private
  
  def publish_user_created
    Polyn.publish("user.created", user.as_json)
  end
  
  def publish_user_updated
    Polyn.publish("user.updated", user.as_json)
  end
end
```

### Events
Services are made up of one or more events. An event is defined by a name and a method to call when that event is triggered.
When an event is published, it is validated against the configured validator. If the event is valid, the the event message
is serialized and published to the configured transporter.

When an event is received, it is validated against the configured validator, and if valid the method tied to the event within
the service is called.

### Validators
A validator is a class that implements the `Polyn::Validators::Base` interface. The default validator is 
`Polyn::Validators::JsonSchema`. Validators ensure that the event message is valid according to the configured schema.

#### `Polyn::Validators::JsonSchema`
The JsonSchema validator is the default validator. It uses the [json-schema](https://json-schema.org/) to validate against,
and may validate using either a local file or a remote schema url. The `Polyn::Validators::JsonSchema`. The validator expects
each event schema to be defined in its own file, where the name of the file is `<event_name>.json`.

##### Configuration
| Key | Type | Required | Default                           | Description                             |
| -- | --- | --- |-----------------------------------|-----------------------------------------|
| `:prefix` | `String` | true | | The prefix of the schem a location, this may be a file, or a qualified url  |

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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/polyn. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/polyn/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Polyn project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/polyn/blob/master/CODE_OF_CONDUCT.md).
