methods_for :dialplan do
  def simon_game_voice_form
    SimonGameVoiceForm.start_voice_form(self)
  end
end

class SimonGameVoiceForm
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
