module VoiceForm
 
  def self.included(base)
    base.extend MacroMethods
    base.class_eval do
      include InstanceMethods
      include FormMethods
  
      cattr_accessor :form
    end  
  end
  
  module InstanceMethods
  
    def start_voice_form
      raise "No voice form defined" unless self.form
      self.form.run(self)
    end

    def form
      self.class.form
    end
    
  end
  
  module MacroMethods
    
    def voice_form(options={}, &block)
      raise "Voice form requires block" unless block_given?
      self.form = VoiceForm::Form.new(options)
      self.form.instance_eval(&block)
    end
    
  end
  
  module FormMethods
  
    def field(field_name, options={}, &block)
      raise unless block_given?
      
      form_field = VoiceForm::FormField.new(field_name, options, self)
      
      form_field.instance_eval(&block)
      raise 'At least one prompt is required' if form_field.prompts.empty?
      
      if self.class == VoiceForm::Form
        self.form_stack << [field_name, form_field]
      else
        self.class_eval do
          attr_accessor field_name
        end
        form_field.run
      end
    end
    
  end

end
