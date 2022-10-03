# frozen_string_literal: true

module Polyn
  ##
  # Methods to enable distributed tracing across services
  # Attempts to follow OpenTelemetry conventions
  # https://opentelemetry.io/docs/reference/specification/trace/semantic_conventions/messaging/
  class Tracing
    ##
    # Tracer object to use to start a trace
    def self.tracer
      ::OpenTelemetry.tracer_provider.tracer("polyn", Polyn::VERSION)
    end

    ##
    # Common attributes to add to a span involving an individual message
    # https://opentelemetry.io/docs/reference/specification/trace/semantic_conventions/messaging/#messaging-attributes
    def self.span_attributes(span, nats:, type:, event:, payload:)
      span.add_attributes({
        "messaging.system"                     => "NATS",
        "messaging.destination"                => type,
        "messaging.protocol"                   => "Polyn",
        "messaging.url"                        => nats.uri.to_s,
        "messaging.message_id"                 => event.id,
        "messaging.message_payload_size_bytes" => payload.bytesize,
      })
    end

    ##
    # Uses the message header to extract trace information from the
    # published message so the subscription handler can use it as
    # the parent span. This will allow us to create a distributed
    # trace between publications and subscriptions. It's expecting a
    # `traceparent` header to be set on the message
    # https://www.w3.org/TR/trace-context/#traceparent-header
    def self.connect_span_with_received_message(msg, &block)
      context = OpenTelemetry.propagation.extract(msg.header)
      ::OpenTelemetry::Context.with_current(context, &block)
    end

    ##
    # Add a `traceparent` header to the headers for a message so that the
    # subscribers can be connected with it
    # https://www.w3.org/TR/trace-context/#traceparent-header
    def self.trace_header(headers = {})
      ::OpenTelemetry.propagation.inject(headers)
    end

    ##
    # Start a span for publishing an event
    def self.publish_span(type, &block)
      tracer.in_span("#{type} send", kind: "PRODUCER", &block)
    end

    ##
    # Start a span for handling a received event
    def self.subscribe_span(type, msg, links: nil, &block)
      connect_span_with_received_message(msg) do
        tracer.in_span("#{type} receive", kind: "CONSUMER", links: convert_links(links), &block)
      end
    end

    ##
    # Start a span to handle processing of batch messages
    def self.processing_span(type, &block)
      tracer.in_span("#{type} process", kind: "CONSUMER", &block)
    end

    class << self
      private

      def convert_links(links)
        links.map { |link| create_span_link(link) } if links
      end

      def create_span_link(span)
        ::OpenTelemetry::Trace::Link.new(span.context)
      end
    end
  end
end
