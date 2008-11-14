#VoiceForm

A plugin for Adhearsion to add form functionality and flow, similar to VoiceXML style forms.

By Adam Meehan (adam.meehan@gmail.com, [http://duckpunching.com/](http://duckpunching.com/))

Released under the MIT license.

##Introduction

After developing VoiceXML (VXML) apps for quite a while and then trying Adhearsion, I found I missed 
the VXML form element flow when writing components. Given that most interactions with an IVR system
are simply prompt, input, validate and, reprompt or go the next field. This flow has been nicely 
distilled into the VXML form element and its child elements. The problem with VXML is that you are 
using XML in a programmatic way, yuck! Also you are not using Ruby, so you miss out on its awesomeness.

The plugin attempts to emulate some of the VXML form flow for use in your Adhearsion components.


##Install

    sudo gem install adzap-voice_form --source=http://gems.github.com/
    
At the bottom your projects startup.rb file put

    require 'voice_form'

##Example

I use the **speak** command in this example to give better context. The speak command is for TTS 
and is currently disabled in Adhearsion. In your own application you can just use the **play**
command to play your sound files.

    class MyComponent
      add_call_context :as => :call_context

      voice_form do      
      
        field(:age, :max_length => 3, :attempts => 3) do
          prompt :speak => "Please enter your age", :timeout => 2
          reprompt :speak => "Enter your age in years", :timeout => 2
          
          setup do
            @max_age = 110
          end
          
          timeout do
            call_context.speak "You did not enter anything. Try again."
          end
                  
          validate do
            @age.to_i <= @max_age
          end
          
          confirm(:accept => 1, :reject => 2, :timeout => 3, :attempts => 3) do
            "You entered #{@age}. Press 1 to continue or 2 to try again."
          end
          
          invalid do
            call_context.speak "Your age must be less than #{@max_age}. Try again."
          end
          
          success do
            call_context.speak "You are #{@age} years old."
          end
          
          failure do
            call_context.speak "You could not enter your age. Thats a bad sign."
          end      
        end
       
      end
    end

In your dialplan:

    general {
      my_component = new_my_component
      my_component.start_voice_form
    }

That covers most of the functionality, and hopefully it makes sense pretty much straight 
away.

You don't have to start the form from the dialplan, but it makes it simple. You could start it from 
within a component method.

All callback blocks (setup, validate, timeout etc.) are evaluated in the component scope so you can use 
component methods and instance variables in them and they will work. You don't have to define any 
callbacks if the field is straight forward and only depends on its length.

For a more complete example see the examples folder.

## Commands

### voice_form

The flow of the form works like a stack. So each field and do_block are executed in order until the 
end of the form is reached. You can jump around the stack by using `form.goto :field_name` which
will move the *stack pointer* to the field after the current field is completed and move forward
through the form stack from that point, regardless whether a field has already been completed.

You can also use `form.restart` to start the form over from the beginning.

The form setup block is only run once and is not executed again, even with a `form.restart`.

The `voice_form` method takes only one option

- :call_context - to nominate the call context method if other than call context
                                  

### field

This defines the field the with name given to collect on the form. The field method can be used
in a `voice_form` or on its own inside a component method.

The options available are:

- :length       - the number of digits to accept
- :min_length   - minimum number of digits to accept
- :max_length   - maximum number of digits to accept
- :attempts     - number of tries to get a valid input
- :call_context - the method name for the call context if other than 'call_context'

All fields defined get an accessor method defined of the same name in the component class.
This means you can access its value using the instance variable or the accessor method inside any of
the field callbacks and in other fields on a form.

The `prompt` and `reprompt` methods are a wrapper around the input command. And as such is always 
interruptable or you can _bargein_ when you want to starting keying numbers. You pass in a 
hash of options to control the prompt such as:

- :play    - play one or more sound files
- :speak   - play TTS text (needs my Adhearsion hack for speak in input command)
- :timeout - number of seconds to wait for input
- :repeats - number of attempts to use this prompt until the next one is used

The length expected for the input is taken from the options passed to the `field` method.

You can only use one of :play or :speak.

There can only be one `prompt` but you can have multiple `reprompt`s. When you add a reprompt it changes
what the prompt is if there is input the first time or the input is invalid.


### Callbacks 

The available callbacks that can be defined for a field are as follows

- setup
- timeout
- validate
- invalid
- confirm
- success
- failure

Each of them takes a block which is executed as a specific point in the process of getting form input.
All of them are optional. The block for a callback is evaluated in the scope of the component so any
instance variables and component methods are available to use including the call context.

The details of each callback are as follows

### setup

This is run once only for a field if defined before any prompts

### timeout

This is run if no input is received.

### validate

This is run after input of a valid length. The validate block is where you put validation logic of the
value just input by the user. The block should return `true` if the value is valid or `false` otherwise.
If the validate callback returns false then the invalid callback will be called next.

### invalid

The invalid callback is called if the input value is not of a valid length or the validate block returns
false.

### confirm

The confirm callback is called after the input has been validated. The confirm callback is a little different
from the others. Idea is that you return either an array or string of the audio files or TTS text, respectively,
you want to play as the prompt for confirming the value entered. The confirm block also takes a few options:

- :accept   - the number to press to accept the field value entered. Default is 1. 
- :reject   - the number to press the reject the field value entered and try again. Default is 2.
- :attempts - the number of attempts to try to get a confirmation response. Default is 3
- :timeout  - the number of seconds to wait for input after the confirmatio response. Default is 3.

The value returned from the block should form the complete list of audio files or TTS text to prompt the user
including the values to accept of reject the value.

For example, in a field called my_field:

    confirm(:accept => 1, :reject => 2, :attempts => 3) do
      ['you-entered', @my_field.scan(/\d/), 'is-this-correct', 'press-1-accept-2-try-again'].flatten
    end

The above will `play` the array of audo files as the prompt for confirmation. 
   
    confirm(:accept => 1, :reject => 2, :attempts => 3) do
      "You entered #{@my_field}. Is this correct? Press 1 to accept or 2 try again."
    end

The above will `speak` the string as the prompt for confirmation. 

If no valid input is entered for the confirmation 

TODO: More docs


##Credits

Adam Meehan (adam.meehan@gmail.com, [http://duckpunching.com/](http://duckpunching.com/))

Also thanks to Jay Phillips for his brilliant work on Adhearsion ([http://adhearsion.com](http://adhearsion.com)).
