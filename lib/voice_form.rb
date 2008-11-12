require 'voice_form/form_methods'
require 'voice_form/form'
require 'voice_form/form_field'

Adhearsion::Components::Behavior.module_eval do
  include VoiceForm::FormMethods
end

Adhearsion::Components::Behavior::ClassMethods.module_eval do
  include VoiceForm::MacroMethods
end
