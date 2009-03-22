# VoiceForm

A plugin for Adhearsion to add form functionality and flow, similar to VoiceXML style forms.

By Adam Meehan (adam.meehan@gmail.com, [http://duckpunching.com/](http://duckpunching.com/))

Released under the MIT license.

## Introduction

The plugin adds form features to Adhearsion components to quickly and semantically setup data
input for your voice application. You define a form and form fields in which to collect data and
setup callbacks to instruct the caller, give feedback, confirm input and validate input.


## Install

    sudo gem install adzap-voice_form --source=http://gems.github.com/
    
At the bottom your projects startup.rb file put

    require 'voice_form'

## Example

Here is the Adhearsion example Simon game redone using voice_form:

    class SimonGame
      include VoiceForm

      voice_form do
        setup do
          @number = ''
        end

        field(:attempt, :attempts => 1) do
          prompt :play => :current_number, :bargein => false, :timeout => 2

          setup do
            @number << random_number
          end

          validate do
            @attempt == @number
          end

          success do
            call.play 'good'
            form.restart
          end

          failure do
            call.play %W[#{@number.length-1} times wrong-try-again-smarty]
            @number = ''
            form.restart
          end
        end

      end

      def random_number
        rand(10).to_s
      end

      def current_number
        as_digits(@number)
      end
    end

That covers most of the functionality, and hopefully it makes sense pretty much straight 
away.

To start the form, in your dialplan:

For Adhearsion 0.7.999

    general {
      simon_game = new_simon_game
      simon_game.start_voice_form(self)
    }

For Adhearsion 0.8.x

    general {
      SimonGame.start_voice_form(self)
    }

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


### field

This defines the field the with name given to collect on the form. The field method can be used
in a `voice_form` or on its own inside a component method.

The options available are:

- :length     - the number of digits to accept
- :min_length - minimum number of digits to accept
- :max_length - maximum number of digits to accept
- :attempts   - number of tries to get a valid input
- :call       - the method name for the call context if other than 'call'. Used for standalone fields not is a form.

All fields defined get an accessor method defined of the same name in the component class.
This means you can access its value using the instance variable or the accessor method inside any of
the field callbacks and in other fields on a form.

The `prompt` and `reprompt` methods are a wrapper around the input command. And as such is always 
interruptable or you can _bargein_ when you want to starting keying numbers. You pass in a 
hash of options to control the prompt such as:

- :play    - play one or more sound files
- :speak   - play TTS text (needs my Adhearsion hack for speak in input command)
- :timeout - number of seconds to wait for input. Default is 5.
- :repeats - number of attempts to use this prompt until the next one is used
- :bargein - whether to allow caller to interrupt prompt. Default is true.

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

#### setup

This is run once only for a field if defined before any prompts

#### timeout

This is run if no input is received or input is not of a valid length as defined by length or min_length
field options.

#### validate

This is run after input of a valid length. The validate block is where you put validation logic of the
value just input by the user. The block should return `true` if the value is valid or `false` otherwise.
If the validate callback returns false then the invalid callback will be called next.

#### invalid

The invalid callback is called if validate block returns false.

#### confirm

The confirm callback is called after the input has been validated. The confirm callback is a little different
from the others. Idea is that you return either an array or string of the audio files or TTS text, respectively,
you want to play as the prompt for confirming the value entered. The confirm block also takes a few options:

- :accept   - the number to press to accept the field value entered. Default is 1. 
- :reject   - the number to press the reject the field value entered and try again. Default is 2.
- :attempts - the number of attempts to try to get a confirmation response. Default is 3
- :timeout  - the number of seconds to wait for input after the confirmation response. Default is 3.

The value returned from the block should form the complete list of audio files or TTS text to prompt the user
including the values to accept of reject the value.

For example, in a field called my_field:

    confirm(:accept => 1, :reject => 2, :attempts => 3) do
      ['you-entered', as_digits(@my_field), 'is-this-correct', 'press-1-accept-2-try-again'].flatten
    end

The above will `play` the array of audio files as the prompt for confirmation. 
   
    confirm(:accept => 1, :reject => 2, :attempts => 3) do
      "You entered #{@my_field}. Is this correct? Press 1 to accept or 2 try again."
    end

The above will `speak` the string as the prompt for confirmation. 

If no valid input is entered for the confirmation then another you will be reprompted to enter the field value. 


### Form methods

Inside a callback you have the `form` method available. The returns the instance of the current form. The form
has some methods to allow you to perform form actions which manipulate the form stack. These actions are as follows:

#### form.goto

Inside any callback you can use the `goto` command to designate which field the form should run after the
current field. Normally the form will progress through the fields in the order defined, but a goto with shift
the current form position to the field name pass to it like so:

    failure do
      form.goto :other_field_name
    end

The form continues from the field in the goto run each subsequent field in order. If the goto field is above the
current field then the current field will be executed again when it is reached in the stack. If the goto field
is below the current field then form will continue there, skipping whatever fields may lie between the current
and the goto field.


#### form.restart

The form may be restarted from the start at any point with `form.restart`. This will go back to the top of the
form and proceed through each field again. The form setup will not be run again however.


#### form.exit

To exit the form after the current field is complete just execute `form.exit`. The application will then be 
returned to where the form was started, be it a dialplan or another form.


## Credits

Adam Meehan (adam.meehan@gmail.com, [http://duckpunching.com/](http://duckpunching.com/))

Also thanks to Jay Phillips et al. for the brilliant work on Adhearsion ([http://adhearsion.com](http://adhearsion.com)).
