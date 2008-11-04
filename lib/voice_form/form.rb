module VoiceForm

  class Form
    include VoiceForm::FormMethods

    attr_accessor :form_stack
    
    def initialize(options={})
      @options = options
      
      @form_stack = []
      @stack_index = 0
    end
    
    def run(component)
      @component = component
      
      # hack to avoid setting the call_context in each field for different context name
      if context_name = @options[:call_context]
        @component.class_eval do
          alias_method :call_context, context_name
        end
      end
      
      add_field_accessors    
      
      run_setup
      
      while @stack_index < form_stack.size do
        break if @exit_form
        
        slot = form_stack[@stack_index]
        @stack_index += 1
        
        if slot.is_a?(Proc)
          @component.instance_eval(&slot)
        else
          slot[1].run(@component)
        end
      end
      @stack_index = 0
    end
    
    def setup(&block)
      @setup = block
    end
    
    def do_block(&block)
      form_stack << block
    end
    
    def goto(name)
      index = nil
      form_stack.each_with_index {|slot, i| 
        index = i and break if slot.is_a?(Array) && slot[0] == name
      }
      raise "goto failed: No form field found with name '#{name}'." unless index
      @stack_index = index
    end
    
    def restart
      @stack_index = 0
    end
    
    def exit
      @exit_form = true
    end
    
    private 
    
    def run_setup
      @component.instance_eval(&@setup) if @setup
    end
    
    def add_field_accessors
      form_stack.each do |(name, field)|
        next if name.is_a?(Proc)
        @component.class_eval do
          attr_accessor name
        end
      end
    end
  end
  
end
