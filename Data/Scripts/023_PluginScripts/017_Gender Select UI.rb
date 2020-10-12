class GenderSel
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z=99999
    @sprites = {}
    @sel = 0
    @sprites["boy"] = Sprite.new(@viewport)
    @sprites["boy"].bitmap = Bitmap.new("Graphics/Pictures/introBoy")
    @sprites["boy"].x = 186
    @sprites["boy"].y = 144
    @sprites["boy"].ox = @sprites["boy"].bitmap.width/2
    @sprites["boy"].oy = @sprites["boy"].bitmap.height/2
    @sprites["boy"].zoom_x = 1.5
    @sprites["boy"].zoom_y = 1.5
    @sprites["girl"] = Sprite.new(@viewport)
    @sprites["girl"].bitmap = Bitmap.new("Graphics/Pictures/introGirl")
    @sprites["girl"].x = 316
    @sprites["girl"].y = 144
    @sprites["girl"].ox = @sprites["girl"].bitmap.width/2
    @sprites["girl"].oy = @sprites["girl"].bitmap.height/2
    @sprites["girl"].zoom_x = 1.5
    @sprites["girl"].zoom_y = 1.5
    @sprites["boy"].opacity = 0
    @sprites["girl"].opacity = 0
    @sel=0
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    @sprites["messagebox"].setSkin("Graphics/Windowskins/speech frlg")
    pbBottomLeftLines(@sprites["messagebox"],2)
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 173
    @sprites["downarrow"].y = 28
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
  end

  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE() if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
        break
      end
    end
#    @sprites["messagebox"].visible = false
  end

  def pbStartScene
    for i in 0...30
      @sprites["boy"].opacity += 7
      @sprites["girl"].opacity += 7
      pbWait(1)
    end
    @sprites["boy"].opacity = 255
    @sprites["girl"].opacity = 255
    pbDisplay("Are you a boy?\nOr are you a girl?")
    @sprites["downarrow"].visible = true
    @sprites["downarrow"].opacity = 5
    for i in 0...10
      @sprites["girl"].opacity -= 15
      @sprites["downarrow"].opacity += 25
      pbWait(1)
    end
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::LEFT)
        pbPlayCursorSE # && @sel == 0
        @sprites["downarrow"].stop
        if @sel==1
          @sel = 0
          for i in 0...8
            @sprites["boy"].opacity += 19
            @sprites["girl"].opacity -= 12
            @sprites["downarrow"].x -= (@sprites["downarrow"].x>173) ? 19 : 1
            pbWait(1)
          end
          @sprites["downarrow"].x = 173
          @sprites["boy"].opacity = 255
          @sprites["girl"].opacity = 100
        else
          @sel = 1
          for i in 0...8
            @sprites["girl"].opacity += 19
            @sprites["boy"].opacity -= 12
            @sprites["downarrow"].x += (@sprites["downarrow"].x<306) ? 19 : 1
            pbWait(1)
          end
          @sprites["downarrow"].x = 306
          @sprites["girl"].opacity = 255
          @sprites["boy"].opacity = 100
        end
        @sprites["downarrow"].play
      elsif Input.trigger?(Input::C)
        pbPlayCursorSE
      #  @sprites["downarrow"].visible = false
        if @sel == 0
          for i in 0...15
            @sprites["boy"].x += 4
            @sprites["girl"].opacity += -12
            @sprites["downarrow"].x += 4
            @sprites["downarrow"].opacity -= 35
            pbWait(1)
          end
        else
          for i in 0...15
            @sprites["girl"].x -= 4
            @sprites["boy"].opacity += -12
            @sprites["downarrow"].x -= 4
            @sprites["downarrow"].opacity -= 35
            pbWait(1)
          end
        end
        @sprites["downarrow"].opacity = 0
        @sprites["messagebox"].visible = false
        cmd = Kernel.pbConfirmMessage(_INTL("Are you sure you're a #{@sel == 0 ? "boy" : "girl"}?"))
        if cmd
          pbChangePlayer(@sel)
          pbMessage("Let's begin with your name.\\nWhat is it?")
          while 1<2
            pbTrainerName
            if pbConfirmMessage(_INTL("Right...\\nSo your name is \\PN."))
              break
            end
          end
          pbMessage("Well \\PN, I'm excited to start working with you!")
          pbMessage("I've been friends with your Mom for years, and she said you were interested in a Pokémon research job!")
          pbMessage("This is perfect timing too, because I need a new lab assistant!")
          for i in 0...15
            @sprites["boy"].opacity -= 17
            @sprites["girl"].opacity -= 17
            pbWait(1)
          end
          break
        else
          pbPlayCursorSE
          if @sel == 0
            for i in 0...15
              @sprites["boy"].x -= 4
              @sprites["girl"].opacity += 7
              @sprites["downarrow"].x -= 4
              @sprites["downarrow"].opacity += 15
              pbWait(1)
            end
            @sprites["girl"].opacity = 100
          else
            for i in 0...15
              @sprites["girl"].x += 4
              @sprites["boy"].opacity += 7
              @sprites["downarrow"].x += 4
              @sprites["downarrow"].opacity += 15
              pbWait(1)
            end
            @sprites["boy"].opacity = 100
          end
          @sprites["messagebox"].visible = true
          @sprites["downarrow"].opacity = 255
        end
      end
    end
    dispose
    return @sel
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

def pbSelectGender
  obj = GenderSel.new
  val = obj.pbStartScene
  return val
end
