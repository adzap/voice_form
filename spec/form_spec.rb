require File.dirname(__FILE__) + '/spec_helper'

describe VoiceForm::Form do
  include VoiceForm

  attr_accessor :call_context
  
  before do
    new_voice_form
    @call_context = mock('CallContext', :play => nil, :speak => nil)
    @call_context.stub!(:input).with(any_args).and_return('')
  end

  it "should define form and run it" do
    call_me = i_should_be_called
   
    self.class.voice_form &call_me
   
    start_voice_form
  end

  it "should call setup block" do
    form.setup &i_should_be_called
    
    run_form
  end
  
  it "should run single form field" do
    call_me = i_should_be_called
    
    form.field(:my_field) do
      prompt :speak => 'enter value'
      setup { call_me.call }
    end
    
    run_form
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
    
    run_form
  end
  
  it "should run do_blocks" do
    do_block_call_me = i_should_be_called

    form.do_block { do_block_call_me.call }
    
    run_form
  end
  
  it "should run all fields and do_blocks" do
    field_call_me = i_should_be_called
    do_block_call_me = i_should_be_called
    
    form.field(:first_field) do
      prompt :speak => 'enter value'
      setup { field_call_me.call }
    end
    form.do_block { do_block_call_me.call }
    
    run_form
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
    
    run_form
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
    
    run_form
  end

  it "should restart form and repeat all form stack items" do
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
    
    run_form
  end
  
  it "should exit form and not run subsequent fields" do
    first_call_me    = i_should_be_called
    do_block_call_me = i_should_not_be_called
    second_call_me   = i_should_not_be_called
    
    form.field(:first_field, :attempts => 1) do
      prompt :speak => 'enter value'
      setup   { first_call_me.call }
      failure { form.exit }
    end
    
    form.do_block { do_block_call_me.call }

    form.field(:second_field) do
      prompt :speak => 'enter value'
      setup { second_call_me.call }
    end
    
    run_form
  end
  
  describe "current_field" do
    before do
      @field = nil
    end
    
    it "should be name of current field being run" do
      form.field(:my_field) do
        prompt :speak => 'enter value'
        setup { @field = form.current_field }
      end
      run_form
      
      @field.should == :my_field
    end
    
    it "should be nil in do_block" do
      form.do_block do
        @field = form.current_field
      end
      run_form
      
      @field.should be_nil
    end
    
    it "should be nil after form is run" do
      form.field(:my_field) do
        prompt :speak => 'enter value'
      end
      run_form
      
      form.current_field.should be_nil
    end
  end

  def new_voice_form
    self.class.voice_form { }
    options, block = *self.class.voice_form_options
    self.form = VoiceForm::Form.new(options, &block)
  end
  
  def run_form
    form.run(self)
  end
end
