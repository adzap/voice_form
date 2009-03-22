module VoiceForm

  class FormField
    cattr_accessor :default_prompt_options
    attr_reader :name

    self.default_prompt_options = { :bargein => true, :timeout => 5 }

    def initialize(name, options, component, &block)
      @name, @options, @component = name, options, component
      @options.reverse_merge!(:attempts => 5, :call => 'call')
      @callbacks = {}
      @prompt_queue = []

      instance_eval(&block)
      raise 'A field requires a prompt to be defined' if @prompt_queue.empty?
    end

    def prompt(options)
      add_prompt(options.reverse_merge(self.class.default_prompt_options))
    end

    def reprompt(options)
      raise 'A reprompt can only be used after a prompt' if @prompt_queue.empty?
      add_prompt(options.reverse_merge(self.class.default_prompt_options))
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
        self.class.default_prompt_options.merge(
          :attempts => 3,
          :accept   => 1,
          :reject   => 2
        )
      )
      @confirmation_options = options.merge(:message => block)
    end

    def run(component=nil)
      @component = component if component

      run_callback(:setup)

      result = 1.upto(@options[:attempts]) do |attempt|
        @value = get_input(prompt_for_attempt(attempt))

        unless valid_length?
          run_callback(:timeout)
          next
        end

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
      set_component_value @value
    end

    private

    def get_input(prompt)
      method  = prompt[:method]
      message = prompt[:message]

      if prompt[:bargein]
        prompt[method] = message
      else
        call.send(method, message)
      end

      args = [ prompt.slice(method, :timeout, :accept_key) ]
      args.unshift(prompt[:length]) if prompt[:length]
      call.input(*args)
    end

    def input_valid?
      run_callback(:validate)
    end

    def valid_length?
      !@value.empty? &&
        @value.size >= minimum_length &&
        @value.size <= maximum_length
    end

    def value_confirmed?
      return true unless @confirmation_options

      prompt = evaluate_prompt(@confirmation_options)
      prompt[:method] = prompt[:message].is_a?(Array) ? :play : :speak
      prompt[:length] = [ prompt[:accept].to_s.size, prompt[:reject].to_s.size ].max

      1.upto(prompt[:attempts]) do |attempt|
        case get_input(prompt)
        when prompt[:accept].to_s
          return true
        when prompt[:reject].to_s
          return false
        else
          next
        end
      end
      false
    end

    def run_callback(callback)
      if block = @callbacks[callback]
        set_component_value @value
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
      @component.send(@name)
    end

    def minimum_length
      @options[:min_length] || @options[:length] || 1
    end

    def maximum_length
      @options[:max_length] || @options[:length] || @value.size
    end

    def call
      @call ||= @component.send(@options[:call])
    end

    def add_prompt(options)
      method = options.has_key?(:play) ? :play : :speak
      options[:message] = options.delete(method)
      options[:method]  = method
      options[:length]  = @options[:length] || @options[:max_length]

      repeats = options[:repeats] || 1
      @prompt_queue += ([options] * repeats)
    end

    def prompt_for_attempt(attempt)
      prompt = if attempt == 1 || @prompt_queue.size == 1 then
        @prompt_queue.first
      else
        @prompt_queue[attempt-1] || @prompt_queue.last
      end
      evaluate_prompt(prompt)
    end

    def evaluate_prompt(prompt)
      options = prompt.dup
      message = options[:message]

      message = case message
      when String, Array
        message
      when Symbol
        @component.send(message)
      when Proc
        @component.instance_eval(&message)
      end
     
      options[:message] = message
      options
    end
  end

end
