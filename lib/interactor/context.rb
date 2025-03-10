require "active_support/core_ext/module/delegation"

module Interactor
  # Public: The object for tracking state of an Interactor's invocation. The
  # context is used to initialize the interactor with the information required
  # for invocation. The interactor manipulates the context to produce the result
  # of invocation.
  #
  # The context is the mechanism by which success and failure are determined and
  # the context is responsible for tracking individual interactor invocations
  # for the purpose of rollback.
  #
  # The context may be manipulated using arbitrary getter and setter methods.
  #
  # Examples
  #
  #   context = Interactor::Context.new
  #   # => #<Interactor::Context>
  #   context.foo = "bar"
  #   # => "bar"
  #   context
  #   # => #<Interactor::Context foo="bar">
  #   context.hello = "world"
  #   # => "world"
  #   context
  #   # => #<Interactor::Context foo="bar" hello="world">
  #   context.foo = "baz"
  #   # => "baz"
  #   context
  #   # => #<Interactor::Context foo="baz" hello="world">
  class Context
    # Internal: Initialize an Interactor::Context or preserve an existing one.
    # If the argument given is an Interactor::Context, the argument is returned.
    # Otherwise, a new Interactor::Context is initialized from the provided
    # hash.
    #
    # The "build" method is used during interactor initialization.
    #
    # context - A Hash whose key/value pairs are used in initializing a new
    #           Interactor::Context object. If an existing Interactor::Context
    #           is given, it is simply returned. (default: {})
    #
    # Examples
    #
    #   context = Interactor::Context.build(foo: "bar")
    #   # => #<Interactor::Context foo="bar">
    #   context.object_id
    #   # => 2170969340
    #   context = Interactor::Context.build(context)
    #   # => #<Interactor::Context foo="bar">
    #   context.object_id
    #   # => 2170969340
    #
    # Returns the Interactor::Context.
    def self.build(context = {})
      new.tap do |instance|
        instance.assign_attributes(context.to_h)
      end
    end

    attr_accessor :error, :error_cause
    delegate :to_s, to: :to_h

    # Public: Whether the Interactor::Context is successful. By default, a new
    # context is successful and only changes when explicitly failed.
    #
    # The "success?" method is the inverse of the "failure?" method.
    #
    # Examples
    #
    #   context = Interactor::Context.new
    #   # => #<Interactor::Context>
    #   context.success?
    #   # => true
    #   context.fail!
    #   # => Interactor::Failure: #<Interactor::Context>
    #   context.success?
    #   # => false
    #
    # Returns true by default or false if failed.
    def success?
      !failure?
    end

    # Public: Whether the Interactor::Context has failed. By default, a new
    # context is successful and only changes when explicitly failed.
    #
    # The "failure?" method is the inverse of the "success?" method.
    #
    # Examples
    #
    #   context = Interactor::Context.new
    #   # => #<Interactor::Context>
    #   context.failure?
    #   # => false
    #   context.fail!
    #   # => Interactor::Failure: #<Interactor::Context>
    #   context.failure?
    #   # => true
    #
    # Returns false by default or true if failed.
    def failure?
      @failure || false
    end

    # Public: Fail the Interactor::Context. Failing a context raises an error
    # that may be rescued by the calling interactor. The context is also flagged
    # as having failed.
    #
    # Optionally the caller may provide a hash of key/value pairs to be merged
    # into the context before failure.
    #
    # context - A Hash whose key/value pairs are merged into the existing
    #           Interactor::Context instance. (default: {})
    #
    # Examples
    #
    #   context = Interactor::Context.new
    #   # => #<Interactor::Context>
    #   context.fail!
    #   # => Interactor::Failure: #<Interactor::Context>
    #   context.fail! rescue false
    #   # => false
    #   context.fail!(foo: "baz")
    #   # => Interactor::Failure: #<Interactor::Context foo="baz">
    #
    # Raises Interactor::Failure initialized with the Interactor::Context.
    def fail!(params = {})
      assign_attributes(params)
      @failure = true
      raise Failure, self
    end

    def assign_attributes(params)
      params.each do |attribute, value|
        self.send("#{attribute}=", value) if respond_to?(attribute)
      end
    end

    def to_h
      { error: error }
    end
  end
end
