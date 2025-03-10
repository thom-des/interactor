
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/class/attribute"
require "active_support/concern"

module Interactor
  # Internal: Methods relating to declaring what we receive and what will be stored in the context.
  module Declaration
    extend ActiveSupport::Concern

    included do
      class_attribute :context_class, instance_writer: false, default: Context
    end

    class_methods do
      def receive(*required_arguments, **optional_arguments)
        @required_arguments ||= []
        new_required_arguments = required_arguments - @required_arguments
        @required_arguments += new_required_arguments

        delegate(*new_required_arguments, to: :context) unless new_required_arguments.empty?
        delegate(*optional_arguments.keys, to: :context) unless optional_arguments.empty?

        attributes = [*new_required_arguments, *optional_arguments.keys]

        self.context_class = Class.new(context_class) do
          attr_accessor *new_required_arguments
          attr_writer *optional_arguments.keys

          optional_arguments.each do |k, v|
            define_method(k) do
              ivar = "@#{k}"
              return instance_variable_get(ivar) if instance_variable_defined?(ivar)

              instance_variable_set(ivar, v.is_a?(Proc) ? instance_eval(&v) : v)
            end
          end

          class_eval %Q<
            def self.build(
              #{new_required_arguments.map { |a| "#{a}:" }.join(', ')}#{new_required_arguments.empty? ? '' : ', '}
              **rest
            )
              super(**rest).tap do |instance|
                #{new_required_arguments.map { |a| "instance.#{a} = #{a}" }.join(';')}

                #{
                  optional_arguments.keys.map do |k|
                    "instance.instance_variable_set('@#{k}', rest[:#{k}]) if rest.key?(:#{k})"
                  end.join("\n")
                }
              end
            end
          >

          class_eval %Q<
            def to_h
              super.merge(
                #{attributes.map { |a| "#{a}: self.#{a}"}.join(', ')}
              )
            end
          >
        end
      end

      def hold(*held_fields)
        @held_fields ||= []
        @held_fields += held_fields

        delegate(*@held_fields, to: :context)

        self.context_class = Class.new(context_class) do
          attr_accessor *held_fields

          class_eval %Q<
            def to_h
              super.merge(#{held_fields.map { |f| "#{f}: self.#{f}"}.join(', ')})
            end
          >
        end

      end
    end
  end
end
