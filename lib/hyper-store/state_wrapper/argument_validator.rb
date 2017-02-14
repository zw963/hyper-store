module HyperStore
  class StateWrapper
    module ArgumentValidator
      class InvalidOptionError < StandardError; end

      def validate_args!(klass, *args, &block)
        name, initial_value, opts = parse_arguments(*args, &block)

        opts[:scope]    ||= default_scope(klass)
        opts[:initialize] = validate_initialize(initial_value, klass, opts)
        opts[:block]      = block if block

        if opts[:reader]
          opts[:reader] = opts[:reader] == true ? name : opts[:reader]
        end

        [name, opts]
      end

      private

      def invalid_option(message)
        raise InvalidOptionError, message
      end

      # Parses the arguments given to get the name, initial_value (if any), and options
      def parse_arguments(*args)
        # If the only argument is a hash, the first key => value is name => inital_value
        if args.first.is_a?(Hash)
          # If the first key passed in is not the name, raise an error
          if [:reader, :initialize, :scope].include?(args.first.keys.first.to_sym)
            message = 'The name of the state must be specified first as '\
                      "either 'state :name' or 'state name: nil'"
            invalid_option(message)
          end

          name, initial_value = args[0].shift
        # Otherwise just the name is passed in by itself first
        else
          name = args.shift
        end

        # [name, initial_value (can be nil), args (if nil then return an empty hash)]
        [name, initial_value, args[0] || {}]
      end

      # Converts the initialize option to a Proc
      def validate_initialize(initial_value, klass, opts) # rubocop:disable Metrics/MethodLength
        # If we pass in the name as a hash with a value ex: state foo: :bar,
        # we just put that value inside a Proc and return that
        if initial_value
          ->(_instance) { initial_value }
        # If we pass in the initialize option
        elsif opts[:initialize]
          # If it's a Symbol we convert to to a Proc that calls the method on the instance
          if [Symbol, String].include?(opts[:initialize].class)
            method_name = opts[:initialize]
            ->(instance) { instance.send(:"#{method_name}") }
          # If it is already a Proc we do nothing and just return what was given
          elsif opts[:initialize].is_a?(Proc)
            opts[:initialize]
          # If it's not a Proc or a String we raise an error and return an empty Proc
          else
            invalid_option("'state' option 'initialize' must either be a Symbol or a Proc")
            ->(_instance) {}
          end
        # Otherwise if it's not specified we just return an empty Proc
        else
          ->(_instance) {}
        end
      end
    end
  end
end