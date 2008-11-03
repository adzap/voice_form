require File.dirname(__FILE__) + '/spec_helper'

describe VoiceForm::Form do
  include VoiceForm

  attr_accessor :call_context, :my_field
  
  before do
    new_voice_form
    @call_context = mock('CallContext', :play => nil, :speak => nil)
    @call_context.stub!(:input).with(any_args).and_return('')
  end

  it "should call setup block" do
    form.setup &i_should_be_called
    
    start_voice_form
  end
  
  it "should run single form field" do
    call_me = i_should_be_called
    
    form.field(:my_field) do
      prompt :speak => 'enter value'
      setup { call_me.call }
    end
    
    start_voice_form
  end
  
  it "should run all form fields" do
    first_call_me = i_should_be_called
    second_call_me = i_should_be_called
    
    form.field(:first_field) do
      prompt :speak => 'enter value'
      setup { first_call_me.call }
    end
    form.field(:second_field) do
      prompt :speak => 'enter value'
      setup { second_call_me.call }
    end
    
    start_voice_form
  end
  
  it "should run do_blocks" do
    do_block_call_me = i_should_be_called

    form.do_block { do_block_call_me.call }
    
    start_voice_form
  end
  
  it "should run all fields and do_blocks" do
    field_call_me = i_should_be_called
    do_block_call_me = i_should_be_called
    
    form.field(:first_field) do
      prompt :speak => 'enter value'
      setup { field_call_me.call }
    end
    form.do_block { do_block_call_me.call }
    
    start_voice_form
  end
  
  it "should jump forward in form stack to field in goto" do
    first_call_me    = i_should_be_called
    do_block_call_me = i_should_not_be_called
    second_call_me   = i_should_be_called
    
    form.field(:first_field, :attempts => 1) do
      prompt :speak => 'enter value'
      setup { first_call_me.call }
      failure { form.goto :second_field }
    end
    
    form.do_block { do_block_call_me.call }

    form.field(:second_field) do
      prompt :speak => 'enter value'
      setup { second_call_me.call }
    end
    
    start_voice_form
  end
  
  it "should jump back in form stack to goto field and repeat form stack items" do
    first_call_me    = i_should_be_called(2)
    do_block_call_me = i_should_be_called(2)
    second_call_me   = i_should_be_called(2)
    
    form.field(:first_field, :attempts => 1) do
      prompt :speak => 'enter value'
      setup { first_call_me.call }
    end
    
    form.do_block { do_block_call_me.call }

    form.field(:second_field) do
      prompt :speak => 'enter value'
      setup { second_call_me.call }
      failure { 
        unless @once
          @once = true
          form.goto :first_field 
        end
      }
    end
    
    start_voice_form
  end

  it "should restart form repeat all form stack items" do
    first_call_me    = i_should_be_called(2)
    do_block_call_me = i_should_be_called(2)
    second_call_me   = i_should_be_called(2)
    
    form.field(:first_field, :attempts => 1) do
      prompt :speak => 'enter value'
      setup { first_call_me.call }
    end
    
    form.do_block { do_block_call_me.call }

    form.field(:second_field) do
      prompt :speak => 'enter value'
      setup { second_call_me.call }
      failure { 
        unless @once
          @once = true
          form.restart
        end
      }
    end
    
    start_voice_form
  end

  def new_voice_form
    self.class.voice_form { }
  end
end
