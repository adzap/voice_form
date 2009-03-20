module VoiceForm
 
  def self.included(base)
    base.extend MacroMethods
    base.class_eval do
      include FormMethods
    end
  end
  
  module MacroMethods
    
    def voice_form(options={}, &block)
      raise "Voice form requires block" unless block_given?

      self.class_eval do
        include InstanceMethods
    
        cattr_accessor :voice_form_options
        attr_accessor :form, :call
      end

      self.voice_form_options = [options, block]
    end
    
  end

  module InstanceMethods
  
    def start_voice_form(call)
      raise "No voice form defined" unless self.voice_form_options
      options, block = *self.class.voice_form_options
      @call = call
      self.form = VoiceForm::Form.new(options, &block)
      self.form.run(self)
    end

  end

  module FormMethods
    
    # Can be used in a form or stand-alone in a component method
    def field(field_name, options={}, &block)
      raise "A field requires a block" unless block_given?
      
      form_field = VoiceForm::FormField.new(field_name, options, self, &block)
      
      raise 'A field requires a prompt to be defined' if form_field.prompts.empty?
      
      if self.class == VoiceForm::Form
        self.form_stack << form_field
      else
        unless self.respond_to?(field_name)
          self.class.class_eval do
            attr_accessor field_name
          end
        end
        form_field.run
      end
    end
    
  end

end
