#VoiceForm

A plugin for Adhearsion to add form functionality and flow, similar to VoiceXML style forms.

By Adam Meehan (adam.meehan@gmail.com, {http://duckpunching.com/}[http://duckpunching.com/])

Released under the MIT license.

##Introduction

After developing VoiceXML (VXML) apps for quite a while and then trying Adhearsion, I found I missed 
the form element work flow when writing components. Given that most interactions with an IVR system
are simply prompt, input, validate and, reprompt or go the next field. This flow has been nicely 
distilled into the VXML form element and its child elements. The problem with VXML is that you are 
using XML in a programmatic way, yuck! Also you are not using Ruby, so you miss out on its awesomeness.

The plugin attempts to emulate some of the VXML form flow for use in your Adhearsion components.


##Install

As Adhearsion doesn't have a plugin architecture that I know of, you have to do a little bit of setup.

Steps are:
- Make directory call 'vendor' in the root of your project 
- Put this plugin in a folder called 'voice_form'
- At the bottom of your startup.rb file put these lines

    $LOAD_PATH.unshift AHN_ROOT + '/vendor/voice_form/lib'
    require 'voice_form'


##Example

I use the **speak** command in this example to give better context. The speak command is for TTS 
and is currently disabled in Adhearsion. In your own application you can just use the **play**
command to play your sound files.

    class MyComponent
      include VoiceForm
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

All blocks (setup, validate, do_block etc.) are evaluated in the component scope so you can use 
component methods and instance variables in them and they will work.

For a more complete example see the examples folder.

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


TODO: Add specific info for callback and option.


TODO: More docs


##Credits

Adam Meehan (adam.meehan@gmail.com, [http://duckpunching.com/](http://duckpunching.com/))

Also thanks to Jay Phillips for his brilliant work on Adhearsion ([http://adhearsion.com](http://adhearsion.com)).