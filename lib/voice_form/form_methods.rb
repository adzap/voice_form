module VoiceForm
 
  def self.included(base)
    base.extend MacroMethods
    base.class_eval do
      include InstanceMethods
      include FormMethods
  
      cattr_accessor :voice_form_options
      attr_accessor :form
    end  
  end
  
  module InstanceMethods
  
    def start_voice_form
      raise "No voice form defined" unless self.voice_form_options
      self.form = VoiceForm::Form.new(self.class.voice_form_options[0])
      self.form.instance_eval(&self.class.voice_form_options[1])
      self.form.run(self)
    end

  end
  
  module MacroMethods
    
    def voice_form(options={}, &block)
      raise "Voice form requires block" unless block_given?
      self.voice_form_options = [options, block]
    end
    
  end
  
  module FormMethods
    
    # Can be used in a form or stand-alone in a component method
    def field(field_name, options={}, &block)
      raise unless block_given?
      
      form_field = VoiceForm::FormField.new(field_name, options, self)
      
      form_field.instance_eval(&block)
      raise 'At least one prompt is required' if form_field.prompts.empty?
      
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
