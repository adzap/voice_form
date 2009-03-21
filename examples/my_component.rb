class MyComponent
  include VoiceForm

  delegate :play, :speak, :to => :call

  voice_form do      
    field(:age, :max_length => 3, :attempts => 3) do
      prompt :speak => "Please enter your age", :timeout => 2, :repeats => 2
      reprompt :speak => "Enter your age in years", :timeout => 2
      
      setup { @max_age = 110 }
              
      validate { @age.to_i < @max_age }
      
      invalid do
        speak "Your age must be less than #{@max_age}. Try again."
      end
      
      success do
        speak "You are #{@age} years old."
      end
      
      failure do
        speak "You could not enter your age. Thats a bad sign."
      end
    end
    
    do_block do
      speak "Get ready for the next question."
    end
    
    field(:postcode, :length => 4, :attempts => 5) do
      prompt :speak => "Please enter your 4 digit post code", :timeout => 3
      
      validate { @postcode[0..0] != '0' }
      
      invalid do
        if @postcode.size < 4
          speak "Your postcode must 4 digits."
        else
          speak "Your postcode cannot start with a 0."
        end
      end
      
      success do
        speak "Your postcode is #{@postcode.scan(/\d/).join(', ')}."
      end
      
      failure do
        if @age.empty?
          speak "Lets start over shall we."
          form.restart
        end
      end
    end
    
  end
end
