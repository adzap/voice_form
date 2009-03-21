require File.dirname(__FILE__) + '/spec_helper'

describe VoiceForm::Form do
  include VoiceForm

  attr_accessor :call
  
  before do
    @call = mock('CallContext', :play => nil, :speak => nil)
    @call.stub!(:input).with(any_args).and_return('')
  end

  it "should define form and run it" do
    call_me = i_should_be_called
    voice_form do
      field(:my_field) { prompt :play => nil }
      setup { call_me.call }
    end
    start_voice_form(@call)
  end

  it "should call setup block" do
    call_me = i_should_be_called
    voice_form do
      setup { call_me.call }
      field(:my_field) { prompt :play => nil }
    end
    run_form
  end
  
  it "should run single form field" do
    call_me = i_should_be_called
    
    voice_form do
      field(:my_field) do
        prompt :play => nil
        setup { call_me.call }
      end
    end

    run_form
  end
  
  it "should run all form fields" do
    first_call_me = i_should_be_called
    second_call_me = i_should_be_called
    
    voice_form do
      field(:first_field) do
        prompt :play => nil
        setup { first_call_me.call }
      end
      field(:second_field) do
        prompt :play => nil
        setup { second_call_me.call }
      end
   end
    
    run_form
  end
  
  it "should run do_blocks" do
    do_block_call_me = i_should_be_called

    voice_form do
      do_block { do_block_call_me.call }
      field(:my_field) { prompt :play => nil }
    end
    
    run_form
  end
  
  it "should run all fields and do_blocks" do
    field_call_me = i_should_be_called
    do_block_call_me = i_should_be_called
    
    voice_form do
      field(:first_field) do
        prompt :play => nil
        setup { field_call_me.call }
      end
      do_block { do_block_call_me.call }
    end
    
    run_form
  end
  
  it "should jump forward in form stack to field in goto" do
    first_call_me    = i_should_be_called
    do_block_call_me = i_should_not_be_called
    second_call_me   = i_should_be_called
    
    voice_form do
      field(:first_field, :attempts => 1) do
        prompt :play => nil
        setup { first_call_me.call }
        failure { form.goto :second_field }
      end
      
      do_block { do_block_call_me.call }

      field(:second_field) do
        prompt :play => nil
        setup { second_call_me.call }
      end
    end
    
    run_form
  end
  
  it "should jump back in form stack to goto field and repeat form stack items" do
    first_call_me    = i_should_be_called(2)
    do_block_call_me = i_should_be_called(2)
    second_call_me   = i_should_be_called(2)
    
    voice_form do
      field(:first_field, :attempts => 1) do
        prompt :play => nil
        setup { first_call_me.call }
      end
    
      do_block { do_block_call_me.call }

      field(:second_field) do
        prompt :play => nil
        setup { second_call_me.call }
        failure {
          unless @once
            @once = true
            form.goto :first_field
          end
        }
      end
    end
    
    run_form
  end

  it "should restart form and repeat all form stack items" do
    first_call_me    = i_should_be_called(2)
    do_block_call_me = i_should_be_called(2)
    second_call_me   = i_should_be_called(2)
    
    voice_form do
      field(:first_field, :attempts => 1) do
        prompt :play => nil
        setup { first_call_me.call }
      end
      
      do_block { do_block_call_me.call }

      field(:second_field) do
        prompt :play => nil
        setup { second_call_me.call }
        failure {
          unless @once
            @once = true
            form.restart
          end
        }
      end
    end
    
    run_form
  end
  
  it "should exit form and not run subsequent fields" do
    first_call_me    = i_should_be_called
    do_block_call_me = i_should_not_be_called
    second_call_me   = i_should_not_be_called
    
    voice_form do
      field(:first_field, :attempts => 1) do
        prompt :play => nil
        setup   { first_call_me.call }
        failure { form.exit }
      end
      
      do_block { do_block_call_me.call }

      field(:second_field) do
        prompt :play => nil
        setup { second_call_me.call }
      end
    end
    
    run_form
  end
  
  describe "current_field" do
    it "should be name of current field being run" do
      voice_form do
        field(:my_field) do
          prompt :play => nil
          setup { @field = form.current_field }
        end
      end
      run_form
      
      @field.should == :my_field
    end
    
    it "should be nil in do_block" do
      voice_form do
        field(:my_field) { prompt :play => nil }
        do_block { @field = form.current_field }
      end
      run_form
      
      @field.should be_nil
    end
    
    it "should be nil after form is run" do
      voice_form do
        field(:my_field) { prompt :play => nil }
      end
      run_form
      
      form.current_field.should be_nil
    end
  end

  def voice_form(&block)
    self.class.voice_form &block
    options, block = *self.class.voice_form_options
    self.form = VoiceForm::Form.new(options, &block)
  end
  
  def run_form
    form.run(self)
  end
end
