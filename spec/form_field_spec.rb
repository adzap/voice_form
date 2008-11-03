require File.dirname(__FILE__) + '/spec_helper'

describe VoiceForm::FormField do
  include VoiceForm::FormMethods
  
  attr_accessor :call_context, :my_field
  
  before do
    @call_context = mock('CallContext', :play => nil, :speak => nil)
    @call_context.stub!(:input).with(any_args).and_return('')
  end
  
  it "should define accessor for field in component" do
    field(:my_field) do
      prompt :speak => 'test'
    end
    self.methods.include?(:my_field)
  end
  
  it "should raise error if no prompts defined" do
    item = form_field(:my_field) do
    end
    lambda { item.run }.should raise_error
  end
  
  it "should raise error if reprompt defined before prompt" do    
    lambda { 
      form_field(:my_field) do
        reprompt :speak => 'and again'
      end
     }.should raise_error
  end
  
  it "should return same prompt for for all attempts if single prompt" do
    item = form_field(:my_field) do 
      prompt :speak => "first"
    end
    item.send(:prompt_for_attempt, 1)[:speak].should == 'first'
    item.send(:prompt_for_attempt, 2)[:speak].should == 'first'
  end
  
  it "should return reprompt for subsequent prompts" do
    item = form_field(:my_field) do 
      prompt :speak => "first"
      reprompt :speak => 'next'
    end
    item.send(:prompt_for_attempt, 1)[:speak].should == 'first'
    item.send(:prompt_for_attempt, 2)[:speak].should == 'next'
    item.send(:prompt_for_attempt, 3)[:speak].should == 'next'
  end
  
  it "should return prompt for given number of repeats before subsequent prompts" do
    item = form_field(:my_field) do 
      prompt :speak => "first", :repeats => 2
      reprompt :speak => 'next'
    end
    item.send(:prompt_for_attempt, 1)[:speak].should == 'first'
    item.send(:prompt_for_attempt, 2)[:speak].should == 'first'
    item.send(:prompt_for_attempt, 3)[:speak].should == 'next'
  end
  
  it "should set input value in component" do
    item = form_field(:my_field, :length => 3) do 
      prompt :speak => "first"
    end
    call_context.stub!(:input).and_return('123')
    item.run
    
    my_field.should == '123'
  end
    
  it "should run setup callback once" do
    call_me = i_should_be_called
    item = form_field(:my_field, :attempts => 3) do 
      prompt :speak => "first"
      
      setup do
        call_me.call
      end
    end
    call_context.should_receive(:input).and_return('')
    
    item.run
  end  
    
  it "should run timeout callback if no input" do
    call_me = i_should_be_called
    item = form_field(:my_field, :attempts => 1) do 
      prompt :speak => "first"
      
      timeout do
        call_me.call
      end
    end
    call_context.should_receive(:input).and_return('')
    
    item.run
  end
  
  it "should make all attempts to get valid input" do
    item = form_field(:my_field) do
      prompt :speak => "first"
    end
    call_context.should_receive(:input).exactly(3).times
    
    item.run
  end
  
  it "should make one attempt if input is valid" do
    item = form_field(:my_field) do 
      prompt :speak => "first"
    end
    item.stub!(:validate_input).and_return(true)    
    call_context.should_receive(:input).once
    
    item.run
  end
  
  it "should run validate input" do
    item = form_field(:my_field, :length => 3) do 
      prompt :speak => "first"
      
    end
    call_context.should_receive(:input).and_return('123')
    item.should_receive(:validate_input)
        
    item.run
  end
  
  it "should run validation block if defined" do
    call_me = i_should_be_called
    item = form_field(:my_field, :length => 3, :attempts => 1) do
      prompt :speak => "first"
      
      validate do
        call_me.call
      end
    end
    call_context.stub!(:input).and_return('123')
    
    item.run
  end
  
  it "should run failure if no input" do
    call_me = i_should_be_called
    item = form_field(:my_field, :length => 3) do 
      prompt :speak => "first"
        
      failure do
        call_me.call
      end      
    end
    call_context.should_receive(:input).and_return('')
       
    item.run
  end
  
  it "should run success if input valid length" do
    call_me = i_should_be_called
    item = form_field(:my_field, :length => 3) do 
      prompt :speak => "first"
        
      success do
        call_me.call
      end      
    end
    call_context.should_receive(:input).and_return('123')
       
    item.run
  end
  
  it "should run success if input valid length and validates" do
    validate_me = i_should_be_called
    call_me = i_should_be_called
    item = form_field(:my_field, :length => 3) do 
      prompt :speak => "first"
      
      validate do
        validate_me.call
        my_field.to_i > 100
      end
        
      success do
        call_me.call
      end
    end
    call_context.should_receive(:input).and_return('123')
       
    item.run
  end
  
  def form_field(field, options={}, &block)
    self.class.class_eval { attr_accessor field }
    item = VoiceForm::FormField.new(field, {:attempts => 3}.merge(options), self )
    
    item.instance_eval(&block)
    item
  end
end
