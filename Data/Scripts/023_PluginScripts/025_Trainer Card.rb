# Overhauls the classic Trainer Card from Pokémon Essentials
class PokeBattle_Trainer

  def tclass
    return "Quantech Researcher" if $game_switches[62]
    return "Biogress Field Agent" if $game_switches[62]
    return "PKMN Trainer"
  end

  def publicID(id=nil)   # Portion of the ID which is visible on the Trainer Card
    return id ? id&0xFFFF : @id&0xFFFF
  end

  def fullname2
    return _INTL("{1} {2}",$Trainer.tclass,$Trainer.name)
  end

  def getForeignID(number=nil)   # Random ID other than this Trainer's ID
    fid=0
    fid=number if number!=nil
    loop do
      fid=rand(256)
      fid|=rand(256)<<8
      fid|=rand(256)<<16
      fid|=rand(256)<<24
      break if fid!=@id
    end
    return fid
  end

  def setForeignID(other,number=nil)
    @id=other.getForeignID(number)
  end
end

class HallOfFame_Scene # Minimal change to store HoF time into a variable

  def writeTrainerData
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
  #  # Store time of first Hall of Fame in $Trainer.halloffame if not array is empty
  #  if $Trainer.halloffame=[]
  #    $Trainer.halloffame.push(pbGetTimeNow)
  #    $Trainer.halloffame.push(totalsec)
  #  end
    pubid=sprintf("%05d",$Trainer.publicID($Trainer.id))
    lefttext= _INTL("Name<r>{1}<br>",$Trainer.name)
    lefttext+=_INTL("IDNo.<r>{1}<br>",pubid)
    lefttext+=_ISPRINTF("Time<r>{1:02d}:{2:02d}<br>",hour,min)
    lefttext+=_INTL("Pokédex<r>{1}/{2}<br>",
        $Trainer.pokedexOwned,$Trainer.pokedexSeen)
    @sprites["messagebox"]=Window_AdvancedTextPokemon.new(lefttext)
    @sprites["messagebox"].viewport=@viewport
    @sprites["messagebox"].width=192 if @sprites["messagebox"].width<192
    @sprites["msgwindow"]=Kernel.pbCreateMessageWindow(@viewport)
    Kernel.pbMessageDisplay(@sprites["msgwindow"],
        _INTL("League champion!\nCongratulations!\\^"))
  end

end

class PokemonTrainerCard_Scene

  # Waits x frames
  def wait(frames)
    frames.times do
    Graphics.update
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    if @sprites["bg"]
      @sprites["bg"].ox-=2
      @sprites["bg"].oy-=2
    end
  end

  def pbStartScene
    @front=true
    @flip=false
    @ngPlusVal = $PokemonTemp.begunNewGamePlus ? ($PokemonTemp.oldNewGamePlusCount + 1) : $Trainer.newGamePlusCount
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    addBackgroundPlane(@sprites,"bg","Trainer Card/bg",@viewport)
    @sprites["card"] = IconSprite.new(128*2,96*2,@viewport)
    @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_#{@ngPlusVal}")

    @sprites["card"].ox=@sprites["card"].bitmap.width/2
    @sprites["card"].oy=@sprites["card"].bitmap.height/2

    @sprites["bg"].zoom_x=2 ; @sprites["bg"].zoom_y=2
    @sprites["bg"].ox+=6
    @sprites["bg"].oy-=26
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)

    @sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay2"].bitmap)

    @sprites["overlay"].x=128*2
    @sprites["overlay"].y=96*2
    @sprites["overlay"].ox=@sprites["overlay"].bitmap.width/2
    @sprites["overlay"].oy=@sprites["overlay"].bitmap.height/2

    @sprites["help_overlay"] = IconSprite.new(0,Graphics.height-48,@viewport)
    @sprites["help_overlay"].setBitmap("Graphics/Pictures/Trainer Card/overlay_0")
    @sprites["help_overlay"].zoom_x=2 ; @sprites["help_overlay"].zoom_y=2
    @sprites["help_overlay"].visible = false if @ngPlusVal < 1
    pbDrawTrainerCardFront
    pbFadeInAndShow(@sprites) { pbUpdate }
  end


  def flip1
    # "Flip"
    15.times do
      @sprites["overlay"].zoom_x-=0.07
      @sprites["card"].zoom_x-=0.07
      pbUpdate
      wait(1)
    end
      pbUpdate
  end

  def flip2
    # UNDO "Flip"
    15.times do
      @sprites["overlay"].zoom_x+=0.07
      @sprites["card"].zoom_x+=0.07
      pbUpdate
      wait(1)
    end
      pbUpdate
  end

  def pbDrawTrainerCardFront
    flip1 if @flip==true
    @front=true
    @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_#{@ngPlusVal}")
    @overlay  = @sprites["overlay"].bitmap
    @overlay2 = @sprites["overlay2"].bitmap
    @overlay.clear
    @overlay2.clear
    baseColor   = Color.new(72,72,72)
    shadowColor = Color.new(160,160,160)
    baseGold = Color.new(255,198,74)
    shadowGold = Color.new(123,107,74)
    if @ngPlusVal==5
      baseColor   = baseGold
      shadowColor = shadowGold
    end
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = _ISPRINTF("{1:02d}:{2:02d}",hour,min)
    $PokemonGlobal.startTime = pbGetTimeNow if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
       pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
       $PokemonGlobal.startTime.day,
       $PokemonGlobal.startTime.year)
    textPositions = [
       [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
       [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
       [_INTL("ID No."),32,64-16,0,baseColor,shadowColor],
       [sprintf("%05d",$Trainer.publicID($Trainer.id)),468-122*2,64-16,1,baseColor,shadowColor],
       [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
       [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
       [_INTL("CELLULOSE"),32,112+32,0,baseColor,shadowColor],
       [sprintf("%d",$Trainer.cells),302+2,112+32,1,baseColor,shadowColor],
       [_INTL("TIME"),32,208+48,0,baseColor,shadowColor],
       [time,302+88*2,208+48,1,baseColor,shadowColor],
       [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
       [starttime,302+89*2,256+32,1,baseColor,shadowColor]
    ]
    @sprites["overlay"].z+=10
    if $game_switches[62] || $game_switches[61]
      team = $game_switches[62] ? "Quantech Co." : "Biogress Inc."
      textPositions.push([_INTL("Org:."),32,208,0,baseColor,shadowColor])
      textPositions.push(["#{team}",302+2,208,1,baseColor,shadowColor])
    else
      textPositions.push(["Research Assistant",32,208,0,baseColor,shadowColor])
    end
    pbDrawTextPositions(@overlay,textPositions)
    textPositions = [
      [_INTL("Press C to flip the card."),16,64+280,0,Color.new(216,216,216),Color.new(80,80,80)]
    ]
    bmp = pbBitmap(pbPlayerSpriteFile($Trainer.trainertype))
    x = 350 + (($Trainer.gender==0)? 0 : -10)
    y = 100 + (($Trainer.gender==0)? 5 : -5)
    @sprites["overlay"].bitmap.blt(x,y,bmp,Rect.new(0,0,bmp.width,bmp.height))
    @sprites["overlay2"].z+=20
    pbDrawTextPositions(@overlay2,textPositions) if @ngPlusVal > 0
    flip2 if @flip==true
  end

  def pbDrawTrainerCardBack
    pbUpdate
    @flip=true
    flip1
    @front=false
    @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_#{@ngPlusVal}b")
    @overlay  = @sprites["overlay"].bitmap
    @overlay2 = @sprites["overlay2"].bitmap
    @overlay.clear
    @overlay2.clear
    baseColor   = Color.new(72,72,72)
    shadowColor = Color.new(160,160,160)
    baseGold = Color.new(255,198,74)
    shadowGold = Color.new(123,107,74)
    if @ngPlusVal==5
      baseColor   = baseGold
      shadowColor = shadowGold
    end
    hof=[]
  #  if $Trainer.halloffame!=[]
  #    hof.push(_INTL("{1} {2}, {3}",
  #    pbGetAbbrevMonthName($Trainer.halloffame[0].mon),
  #    $Trainer.halloffame[0].day,
  #    $Trainer.halloffame[0].year))
  #    hour = $Trainer.halloffame[1] / 60 / 60
  #    min = $Trainer.halloffame[1] / 60 % 60
  #    time=_ISPRINTF("{1:02d}:{2:02d}",hour,min)
  #    hof.push(time)
  #  else
      hof.push("--- --, ----")
      hof.push("--:--")
  #  end
    value = $PokemonBag.pbHasItem?(:ABILITYCHARM) ? 80 : 120
    value = (value * (1 - NewGamePlusData.hiddenAbilChance)).floor
    textPositions = [
      [_INTL($Trainer.fullname2),32,64-48,0,baseColor,shadowColor],
      [_INTL("Shiny Chance:"),32,112-16,0,baseColor,shadowColor],
      [_INTL("{1}x",(1 + (0.05 * @ngPlusVal))),302+2+50-2,112-16,1,baseColor,shadowColor],
      [_INTL("1/{1}",NewGamePlusData.shinyChance),302+2+50+63*2,112-16,1,baseColor,shadowColor],

      [_INTL("Hidden Abil. Chance:"),32,112+32-16,0,baseColor,shadowColor],
      [_INTL("{1}x",(1 + NewGamePlusData.hiddenAbilChance)),302+2+50-2,112+32-16,1,baseColor,shadowColor],
      [_INTL("1/{1}",value),302+2+50+63*2,112+32-16,1,baseColor,shadowColor],

      [_INTL("Multipliers:"),32,112+32-16+32,0,baseColor,shadowColor],
      [_INTL("Money: {1}x",NewGamePlusData.moneyGain),302+2+50-2,112+32-16+32,1,baseColor,shadowColor],
      [_INTL("EXP: {1}x",NewGamePlusData.expGain),302+2+50+63*2,112+32-16+32,1,baseColor,shadowColor],

      [_INTL("Lv. Increase"),32,112+32-16+64,0,baseColor,shadowColor],
      [_INTL("Trainer: +{1}",NewGamePlusData.trainerLevels),302+2+50-2,112+32-16+64,1,baseColor,shadowColor],
      [_INTL("Wild: +{1}",NewGamePlusData.wildLevels),302+2+50+63*2,112+32-16+64,1,baseColor,shadowColor],
    ]
    @sprites["overlay"].z+=20
    pbDrawTextPositions(@overlay,textPositions)
    textPositions = [
      [_INTL("Press C to flip the card."),16,64+280,0,Color.new(216,216,216),Color.new(80,80,80)]
    ]
    @sprites["overlay2"].z+=20
    pbDrawTextPositions(@overlay2,textPositions) if @ngPlusVal > 0
=begin
    # Draw Badges on overlay (doesn't support animations, might support .gif)
    imagepos=[]
    # Draw Region 0 badges
    x = 64-28
    for i in 0...8
      if $Trainer.badges[i+0*8]
        imagepos.push(["Graphics/Pictures/Trainer Card/badges0",x,104*2,i*48,0*48,48,48])
      end
      x += 48+8
    end
    # Draw Region 1 badges
    x = 64-28
    for i in 0...8
      if $Trainer.badges[i+1*8]
        imagepos.push(["Graphics/Pictures/Trainer Card/badges1",x,104*2+52,i*48,0*48,48,48])
      end
      x += 48+8
    end
    #print(@sprites["overlay"].ox,@sprites["overlay"].oy,x)
    pbDrawImagePositions(@overlay,imagepos)
=end
    flip2
  end

  def pbTrainerCard
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::C) && @ngPlusVal > 0
        if @front==true
          pbDrawTrainerCardBack
          wait(3)
        else
          pbDrawTrainerCardFront if @front==false
          wait(3)
        end
      end
      if Input.trigger?(Input::B)
        break
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonTrainerCardScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end
