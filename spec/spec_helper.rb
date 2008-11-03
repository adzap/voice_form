$: << File.dirname(__FILE__) + '/../lib'
$: << File.dirname(__FILE__)

require 'rubygems'
require 'spec'
require 'active_support'

require 'voice_form'

module SpecHelpers
  def i_should_be_called(times=1, &block)
    proc = mock('Proc should be called')
    proc.should_receive(:call).exactly(times).times.instance_eval(&(block || Proc.new {}))
    Proc.new { |*args| proc.call(*args) }
  end
  
  def i_should_not_be_called(&block)
    proc = mock('Proc should be called')
    proc.should_not_receive(:call).instance_eval(&(block || Proc.new {}))
    Proc.new { |*args| proc.call(*args) }
  end
end

Spec::Runner.configure do |config|
  config.include SpecHelpers
end
