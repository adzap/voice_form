module VoiceForm

  class FormField
    attr_reader :name
    attr_accessor :prompts

    def initialize(name, options, component)
      @name, @options, @component = name, options, component
      @options.reverse_merge!(:attempts => 5, :call_context => 'call_context')
      @callbacks = {}
      @prompts = []
    end

    def prompt(options)
      add_prompts(options.reverse_merge(:timeout => 5))
    end

    def reprompt(options)
      raise 'A reprompt can only be used after a prompt' if @prompts.empty?
      add_prompts(options.reverse_merge(:timeout => 5))
    end

    def setup(&block)
      @callbacks[:setup] = block
    end

    def validate(&block)
      @callbacks[:validate] = block
    end

    def invalid(&block)
      @callbacks[:invalid] = block
    end

    def timeout(&block)
      @callbacks[:timeout] = block
    end

    def success(&block)
      @callbacks[:success] = block
    end

    def failure(&block)
      @callbacks[:failure] = block
    end

    def confirm(options={}, &block)
      options.reverse_merge!(
        :attempts => 3,
        :accept   => 1,
        :reject   => 2,
        :timeout  => 3
      )
      @confirmation_options = options.merge(:block => block)
    end

    def run(component=nil)
      @component = component if component

      set_component_value('')

      run_callback(:setup)

      result = 1.upto(@options[:attempts]) do |attempt|
        if get_input(attempt).empty?
          run_callback(:timeout)
          next
        end

        set_component_value @value

        if input_valid?
          if value_confirmed?
            break 0
          else
            next
          end
        else
          run_callback(:invalid)
        end
      end
      if result == 0
        run_callback(:success)
      else
        run_callback(:failure)
      end
    end

    private

    def prompt_for_attempt(attempt)
      prompt = if attempt == 1 || @prompts.size == 1 then
        @prompts.first
      else
        @prompts[attempt-1] || @prompts.last
      end
      evaluate_prompt(prompt)
    end

    def get_input(attempt)
      input_options = @options.dup
      input_options.merge!(prompt_for_attempt(attempt))
      args = [ input_options ]
      length = input_options.delete(:length) || input_options.delete(:max_length)
      args.unshift(length) if length
      @value = call_context.input(*args)
    end

    def input_valid?
      @value.size >= minimum_length &&
        @value.size <= maximum_length &&
        run_callback(:validate)
    end

    def value_confirmed?
      return true unless @confirmation_options
      options = @confirmation_options.dup

      if block = options.delete(:block)
        message = @component.instance_eval(&block)
        prompt = case message
        when Array:  {:play  => message}
        when String: {:speak => message}
        end
        prompt.merge!(options.slice(:timeout))
      end
      1.upto(options[:attempts]) do |attempt|
        value = call_context.input(1, prompt)
        case value
        when options[:accept].to_s
          return true
        when options[:reject].to_s
          return false
        else
          next
        end
      end
      false
    end

    def run_callback(callback)
      if block = @callbacks[callback]
        result = @component.instance_eval(&block)
        @value = get_component_value
        result
      else
        true
      end
    end

    def set_component_value(value)
      @component.send("#{@name}=", @value)
    end

    def get_component_value
      @component.send("#{@name}")
    end

    def minimum_length
      @options[:min_length] || @options[:length] || 1
    end

    def maximum_length
      @options[:max_length] || @options[:length] || @value.size
    end

    def call_context
      @call_context ||= @component.send(@options[:call_context])
    end

    def add_prompts(options)
      repeats = options[:repeats] || 1
      @prompts += ([options] * repeats)
    end

    def evaluate_prompt(prompt)
      key = prompt.has_key?(:play) ? :play : :speak
      message = prompt[key]
      message = @component.instance_eval(&message) if message.is_a?(Proc)
      prompt.merge(key => message)
    end
  end

end
