module VoiceForm

  class Form
    include VoiceForm::FormMethods

    attr_accessor :form_stack
    attr_reader :current_field
    
    def initialize(options={}, &block)
      @options = options
      @form_stack = []
      @stack_index = 0

      instance_eval(&block)
      raise 'A form requires at least one field defined' if fields.empty?
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
      index = field_index(name)
      raise "goto failed: No form field found with name '#{name}'." unless index
      @stack_index = index
    end
    
    def restart
      @stack_index = 0
    end
    
    def exit
      @exit = true
    end
    
    private 
    
    def run_setup
      @component.instance_eval(&@setup) if @setup
    end
    
    def run_form_stack
      while @stack_index < form_stack.size && !@exit do
        slot = form_stack[@stack_index]
        @stack_index += 1
        
        if form_field?(slot)
          @current_field = slot.name
          slot.run(@component)
        else
          @current_field = nil
          @component.instance_eval(&slot)
        end
      end
      @stack_index = 0
      @current_field = nil
    end
    
    def add_field_accessors
      return if @accessors_added

      fields.keys.each do |field_name|
        @component.class.class_eval do
          attr_accessor field_name
        end
      end
      
      @accessors_added = true
    end
    
    def form_field?(slot)
      slot.is_a?(VoiceForm::FormField)
    end

    def fields
      @fields ||= form_stack.inject({}) do |flds,s|
        flds[s.name] = s if form_field?(s)
        flds
      end
    end

    def field_index(field)
      form_stack.each_with_index {|slot, i|
        return i if form_field?(slot) && slot.name == field.to_sym
      }
    end
  end
  
end
