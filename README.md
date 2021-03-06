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

Rather than defining its own event schema, Polyn uses [Cloud Events](https://github.com/cloudevents/spec) and strictly
enforces the event format. This means that you can use Polyn to build services that can be used by other services,
or natively interact with things such as GCP Cloud Functions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'polyn'
```

If using pubsub as your transporter, you will also need to add the following to your application's Gemfile:

 ```ruby
 gem 'google-cloud-pubsub'
 ```

To use the JSON serializer, you will also need to add the following to your application's Gemfile:

 ```ruby
 gem 'json_schemer'
 ```

And then execute:

    $ bundle install

## Configuration

| Key              | Type     | Required | Default | Description                                                                                                                                                                                                                                |
|------------------|----------|----------|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:name`          | `String` | true     |         | The name of the application                                                                                                                                                                                                                |
 | `:source_prefix` | `String` | true     |         | The prefix for the source of the event. For example if the prefix is `com.test` and the service name is `calc` the source would be `com.test.calc`. To comply with Cloudevents spec, the `source_prefix` must be in reverse domain syntax. | 
|                  |          |          |         |                                                                                                                                                                                                                                            |
 | `:transit`       | `Hash`   | true     |         | The transit configuration                                                                                                                                                                                                                  |
 | `:serializer`    | `Hash`   | true     |         | The serializer configuration                                                                                                                                                                                                               |

### Transit

The Transit is responsible for publishing and receiving events from the transport bus. It accepts the following

| Key            | Type   | Required | Default               | Description                 |
|----------------|--------|----------|-----------------------|-----------------------------|
| `:transporter` | `Hash` | true     | `{ type: :internal }` | The name of the application |


#### Transporters

Transporters define how a service communicates with other services. They are responsible for translating events into
a consumable format for the specified transport bus. Polyn currently supports the following transporters:

* Internal (in-process, can be used for local development).
* [Google Pub/Sub](https://cloud.google.com/pubsub).

Transporters are designed to be used interchangeably, which means a developer can expect a service developed locally on
one transporter, can reliably utilize the same service on another transporter in production.


##### Internal

The internal transporter is used for local development. It is the default. It doesn't need any additional configuraiton
to operate, but should not be used in production.

##### Google Pub/Sub

The Google Pub/Sub transporter utilizes the [Google Cloud Pub/Sub](https://cloud.google.com/pubsub) service. Polyn does
not explicitly set up any topics or subscriptions, but instead relies on the developer to define the schema of the
message bus. This descision was made explicitly, as it is the only way to ensure that services develeoped by multiple
development teams don't accidentally alter the Pub/Sub schema thereby causing possible outages for other services.

For Google Pub/Sub, it is suggested to use [Terraform](https://www.terraform.io/) to create the necessary resources
within GCP.

The Google Pub/Sub transporter is built on top of the [google-cloud-pubsub](https://github.com/googleapis/google-cloud-ruby/tree/main/google-cloud-pubsub)
library, and the `:transporter` configuration options are passed directly into the Google Pub/Sub client, as such it
supports all the options available in described in the [documention](https://googleapis.dev/ruby/google-cloud-pubsub/latest/Google/Cloud/PubSub.html).

#### Serializers

Serializers are responsible for serializing and deserializing events. They are designed to be used interchangeably,
and will validate the event format before dispatching the event and before processing an incoming event. Polyn currently
supports the following serializers:

* JSON

##### JSON

The JSON serializer is the default. It wil serialize and deserialize events into valid JSON, and will validate the
events against the JSON schema defined in the application's configuration. Schema validation is not optional, as it
ensures consistency across all services.

The JSON serializer accepts the following configuration options:

| Key              | Type     | Required | Default           | Description                                         |
|------------------|----------|----------|-------------------|-----------------------------------------------------|
| `:type`          | `Symbol` | true     | `{ type: :json }` | The type of serializer (this will always be `:json` |
| `:schema_prefix` | `String` | true     |                   | The prefix to use for the schema files.             |

###### Validation

Validation is performed by the JSON schema validator. The validator will validate the event against the schema as defined
in the application's configuration. For example, if the `:schema_prefix` is set to `"files://schemas"`, and the event
is `calc.mult`, the validator will look for a file named `calc.mult.json` in the `schemas` directory. The validator
supports both local files and remote prefixes.

Example Schema:

```json
{
  "type": "object",
  "required": ["a", "b"],
  "properties": {
    "a": {
      "type": "integer"
    },
    "age": {
      "a": "integer"
    }
  }
}
```

Event validation occurs on both the event being dispatched and the event being received. This ensures that services
publishing events to the bus will always be consistent with the schema.

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

    context.acknowledge
  end
  
  def send_welcome_email(context)
    user = User.where(context.params.user_id)
    UserMailer.with(user: user).welcome_email.deliver_now
    
    context.acknowledge
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
