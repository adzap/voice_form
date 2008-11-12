# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{voice_form}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Meehan"]
  s.autorequire = %q{voice_form}
  s.date = %q{2008-11-11}
  s.description = %q{A DSL for Adhearsion to create forms in the style of the VoiceXML form element.}
  s.email = %q{adam.meehan@gmail.com}
  s.extra_rdoc_files = ["History.txt"]
  s.files = ["MIT-LICENSE", "README.markdown", "Rakefile", "lib/voice_form.rb", "lib/voice_form", "lib/voice_form/form.rb", "lib/voice_form/form_field.rb", "lib/voice_form/form_methods.rb", "spec/form_field_spec.rb", "spec/spec_helper.rb", "spec/form_spec.rb", "examples/my_component.rb", "History.txt"]
  s.homepage = %q{http://github.com/adzap/voice_form}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A DSL for Adhearsion to create forms in the style of the VoiceXML form element.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
