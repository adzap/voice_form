class MyComponent
  include VoiceForm

  MAX_AGE = 110

  delegate :play, :speak, :to => :call

  voice_form do      
    field(:age, :max_length => 3, :attempts => 3) do
      prompt :speak => "Please enter your age", :timeout => 2, :repeats => 2
      reprompt :speak => "Enter your age in years", :timeout => 2

      confirm do
        "Are you sure you are #{@age} years old? Press 1 to confirm, or 2 to retry."
      end

      validate { @age.to_i < MAX_AGE }

      invalid do
        speak "You cannot be that old. Try again."
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
      prompt :speak => "Please enter your 4 digit postcode", :timeout => 3
      
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
