module VoiceForm

  class Form
    include VoiceForm::FormMethods

    attr_accessor :form_stack
    attr_reader :current_field
    
    def initialize(options={}, &block)
      @options = options
      @form_stack = []
      @stack_index = 0
      self.instance_eval(&block)
    end
    
    def run(component)
      @component = component
      
      add_field_accessors
      run_setup
      run_form_stack
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
        index = i and break if form_field?(slot) && slot.name == name
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
    
    def run_form_stack
      while @stack_index < form_stack.size do
        slot = form_stack[@stack_index]
        @stack_index += 1
        
        if form_field?(slot)
          @current_field = slot.name
          slot.run(@component)
        else
          @current_field = nil
          @component.instance_eval(&slot)
        end
        
        break if @exit_form
      end
      @stack_index = 0
      @current_field = nil
    end
    
    def add_field_accessors
      return if @accessors_added
      
      form_stack.each do |field|
        next unless form_field?(field)
        @component.class.class_eval do
          attr_accessor field.name
        end
      end
      
      @accessors_added = true
    end
    
    def form_field?(slot)
      slot.is_a?(VoiceForm::FormField)
    end
    
  end
  
end
