PluginManager.register({
   :name => "FRLG Summary Screen",
   :version => "1.0",
   :credits => "Seyuna",
   :link => "https://reliccastle.com/resources/411/"
})

class MoveSelectionSprite < SpriteWrapper
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport=nil,fifthmove=false)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/summarymovesel")
    @frame = 0
    @index = 0
    @fifthmove = fifthmove
    @preselected = false
    @updating = false
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def preselected=(value)
    @preselected = value
    refresh
  end

  def refresh
    w = @movesel.width
    h = @movesel.height/2
    self.x = 240
    self.y = 36+(self.index*60)
    self.y -= 0 if @fifthmove
    self.y += 20 if @fifthmove && self.index==4
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating = true
    super
    @movesel.update
    @updating = false
    refresh
  end
end


class PokemonSummary_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party,partyindex,inbattle=false)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = 1
    @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @markingbitmap = AnimatedBitmap.new("Graphics/Pictures/Summary/markings")
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::Center)
    @sprites["pokemon"].x = 110
    @sprites["pokemon"].y = 153
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x       = 42
    @sprites["pokeicon"].y       = 65
    @sprites["pokeicon"].visible = false
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSmallFont(@sprites["overlay"].bitmap)
#    @sprites["overlay"].bitmap.font.size-=5
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 56
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 260
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["markingbg"] = IconSprite.new(260,88,@viewport)
    @sprites["markingbg"].setBitmap("Graphics/Pictures/Summary/overlay_marking")
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["markingsel"] = IconSprite.new(0,0,@viewport)
    @sprites["markingsel"].setBitmap("Graphics/Pictures/Summary/cursor_marking")
    @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height/2
    @sprites["markingsel"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    @basecolor = Color.new(96,96,96)
    @shadowcolor = Color.new(208,208,208)

    showIv = SHOW_IV_EV_IN_SUMMARY || $game_switches[SHOW_IV_EV_IN_SUMMARY_SWITCH]
    @pagecount = showIv ? 4 : 3

    pbBottomLeftLines(@sprites["messagebox"],2)
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party,partyindex,moveToLearn)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page = 4
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay"].bitmap.font.size-=5
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x       = 42
    @sprites["pokeicon"].y       = 65
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport,moveToLearn>0)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    @basecolor = Color.new(12*8,12*8,12*8)
    @shadowcolor = Color.new(26*8,26*8,25*8)
    drawSelectedMove(moveToLearn,@pokemon.moves[0].id)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @markingbitmap.dispose if @markingbitmap
    @viewport.dispose
  end

  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE() if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
        break
      end
    end
    @sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Yes"),_INTL("No")])) {
      cmdwindow.z       = @viewport.z+1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::B)
            ret = false
            break
          elsif Input.trigger?(Input::C) && @sprites["messagebox"].resume
            ret = (cmdwindow.index==0)
            break
          end
        end
      end
    }
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands,index=0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) {
       cmdwindow.z = @viewport.z+1
       cmdwindow.index = index
       pbBottomRight(cmdwindow)
       loop do
         Graphics.update
         Input.update
         cmdwindow.update
         pbUpdate
         if Input.trigger?(Input::B)
           pbPlayCancelSE
           ret = -1
           break
         elsif Input.trigger?(Input::C)
           pbPlayDecisionSE
           ret = cmdwindow.index
           break
         end
       end
    }
    return ret
  end

  def drawMarkings(bitmap,x,y)
    markings = @pokemon.markings
    markrect = Rect.new(0,0,16,16)
    for i in 0...6
      markrect.x = i*16
      markrect.y = (markings&(1<<i)!=0) ? 16 : 0
      bitmap.blt(x+i*16,y,@markingbitmap.bitmap,markrect)
    end
  end

  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg; return
    end
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(104,104,104)

    showIv = SHOW_IV_EV_IN_SUMMARY || $game_switches[SHOW_IV_EV_IN_SUMMARY_SWITCH]
    graphicfolder = showIv ? 'With IVs' : 'Without IVs'
    # Set background image
    graphic = @pokemon.isShiny? ? "Graphics/Pictures/Summary/" + graphicfolder + "/bg_#{page}s" : "Graphics/Pictures/Summary/" + graphicfolder + "/bg_#{page}"
    @sprites["background"].setBitmap(graphic)
    imagepos=[]
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/Pictures/Summary/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,201,227,0,0,-1,-1])
    # Show status/fainted/Pokérus infected icon
    status = -1
    status = 6 if @pokemon.pokerusStage==1
    status = @pokemon.status-1 if @pokemon.status>0
    status = 5 if @pokemon.hp==0
    if status>=0
      imagepos.push(["Graphics/Pictures/statuses",10,69,0,16*status,44,16])
    end
    # Show Pokérus cured icon
    if @pokemon.pokerusStage==2
      imagepos.push([sprintf("Graphics/Pictures/Summary/icon_pokerus"),199,68,0,0,-1,-1])
    end
    # Show shininess star
    if @pokemon.shiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),216,68,0,0,-1,-1])
    end
    # Draw all images
    pbDrawImagePositions(overlay,imagepos)
    textpos = []
    # Write various bits of text
    pagename = [
        _INTL("POKéMON INFO"),
        _INTL("POKéMON SKILLS"),
        _INTL("POKèMON MOVES"),
        _INTL("POKèMON STATS"),
    ][page-1]
    textpos = [
        [pagename,10,3,0,base,shadow],
        [@pokemon.name,72,37,0,base,shadow],
        [_INTL("Lv") + @pokemon.level.to_s,10,37,0,base,shadow]
    ]

    genderinfo = getGenderInformation(217,37)
    if genderinfo
      textpos.push(genderinfo)
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Draw the Pokémon's markings
    drawMarkings(overlay,12,240)
    # Draw page-specific information
    case page
    when 1; drawPageOne
    when 2; drawPageTwo
    when 3; drawPageThree
    when 4; drawPageFour
    end
  end

  def drawPageOne
    if @pokemon.isShadow?
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_1_shadow")
    end
    overlay = @sprites["overlay"].bitmap

    # Write various bits of text
    textpos = [
        [sprintf("%s", PBSpecies.getName(@pokemon.species)), 335,70,0,@basecolor,@shadowcolor]
    ]

    # Write the held item's name
    drawItemInformation(overlay, 335, 190, 0)

    # Write the Regional/National Dex number
    drawPokemonDexNum(overlay, 335, 40, 0)

    # Draw Pokémon type(s)
    drawPokemonTypes(overlay,335, 100, 335, 100, 403, 100)

    # Write Original Trainer's name and ID number
    drawOwnerInformation(overlay, 335, 130, 0, 335, 160, 0)

    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heartgauge*1.0/PokeBattle_Pokemon::HEARTGAUGESIZE
      imagepos = [
          ["Graphics/Pictures/Summary/overlay_shadowbar",252,234,0,0,(shadowfract*253).floor,-1]
      ]
      pbDrawImagePositions(overlay,imagepos)
    end

    if @pokemon.shadowPokemon?
      drawShadowInformationText(overlay)
    else
      # Write nature
      textpos.push([sprintf("%s nature.", PBNatures.getName(@pokemon.nature)),20,298,0,@basecolor,@shadowcolor])

      # Write characteristicc
      characteristic = getPokemonCharacteristic
      textpos.push([sprintf("%s", characteristic),250,298,0,@basecolor,@shadowcolor])

      # Met text
      textpos.push([getMetText, 20, 326, 0, @basecolor, @shadowcolor])
      textpos.push([getMetDate, 20, 355, 0, @basecolor, @shadowcolor])
    end

    pbDrawTextPositions(overlay, textpos)



  end

  def drawPageOneEgg
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248,248,248)
    shadow = Color.new(104,104,104)
    # Set background image
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_egg")
    # Write various bits of text
    textpos = [
        [_INTL("POKéMON INFO"),10,3,0,base,shadow],
        [@pokemon.name,332,68,0,@basecolor,@shadowcolor]
    ]

    # Draw all text
    pbDrawTextPositions(overlay,textpos)

    eggmettext = getEggMetText
    eggstate = getEggState

    # Draw all text
    drawFormattedTextEx(overlay,255,120,237,eggstate)
    drawFormattedTextEx(overlay,16,294,503,eggmettext)
  end

  def drawPageTwo
    overlay = @sprites["overlay"].bitmap

    drawStats(overlay)

    abilitydesc = pbGetMessage(MessageTypes::AbilityDescs, @pokemon.ability)
    drawTextEx(overlay, 14, 352, 493, 1, abilitydesc, @basecolor, @shadowcolor)

    drawHpBar(overlay, 376, 68)

    drawExpBar(overlay, 336, 328)
  end

  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    @sprites["pokemon"].visible = true
    @sprites["pokeicon"].visible = false
    moveTextPositions = getMoveTextPositions(0)

    pbDrawImagePositions(overlay, moveTextPositions[0])
    pbDrawTextPositions(overlay, moveTextPositions[1])
  end

  def drawPageFour
    overlay = @sprites["overlay"].bitmap
    drawEvIvStats(overlay)
  end

  def drawSelectedMove(moveToLearn,moveid)
    # Draw all of page four, except selected move's details
    drawMoveSelection(moveToLearn)
    # Set various values
    overlay = @sprites["overlay"].bitmap

    @sprites["pokemon"].visible = false if @sprites["pokemon"]

    # Show Pokemon Icon
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true

    movedata = pbGetMoveData(moveid)
    basedamage = movedata[MOVE_BASE_DAMAGE]
    if basedamage == 0
      basedamage = '---'
    elsif basedamage == 1
      basedamage = '???'
    end
    accuracy = movedata[MOVE_ACCURACY]> 0 ? movedata[MOVE_ACCURACY] : '---'
    category = movedata[MOVE_CATEGORY]

    # Draw text
    textPos = [
        [basedamage.to_s, 101, 114, 0, @basecolor, @shadowcolor],
        [accuracy.to_s, 101, 142, 0, @basecolor, @shadowcolor]
    ]

    imgPos = [
        ["Graphics/Pictures/summary/category",167,114,0,category*28,64,28]
    ]
    pbDrawTextPositions(overlay,textPos)
    pbDrawImagePositions(overlay,imgPos)
    drawTextEx(overlay,12,195,212,5,pbGetMessage(MessageTypes::MoveDescriptions,moveid),@basecolor,@shadowcolor)
  end

  def drawMoveSelection(moveToLearn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    graphic = getMoveSelectionGraphic(moveToLearn != 0)
    showIv = SHOW_IV_EV_IN_SUMMARY || $game_switches[SHOW_IV_EV_IN_SUMMARY_SWITCH]
    grapicfolder = showIv ? 'With IVs' : 'Without IVs'
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/" + grapicfolder + "/" + graphic)

    movePos = getMoveTextPositions(moveToLearn)

    textPos = [
        [sprintf("%s", @pokemon.name), 89,39,0,@basecolor,@shadowcolor],
        ["KNOWN MOVES", 10, 3, 0, Color.new(248,248,248), Color.new(104,104,104)],
    ];

    # Get Gender Information
    genderInfo = getGenderInformation(217,39)
    if genderInfo
      textPos.push(genderInfo)
    end

    # Draw all text and images
    pbDrawImagePositions(overlay,movePos[0])
    pbDrawTextPositions(overlay,movePos[1])
    pbDrawTextPositions(overlay,textPos)

    # Draw Pokémon's type icon(s)
    drawPokemonTypes(overlay,88,71,92,71,164,71)
  end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex>0
      newindex -= 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex<@party.length-1
      newindex += 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
    @pokemon = @party[@partyindex]
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    pbSEStop
    pbPlayCry(@pokemon)
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching = false
    drawSelectedMove(0,@pokemon.moves[selmove].id)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z = @sprites["movesel"].z+1
      else
        @sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["movepresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible = false
          switching = false
        else
          if !@pokemon.shadowPokemon?
            if !switching
              @sprites["movepresel"].index   = selmove
              @sprites["movepresel"].visible = true
              oldselmove = selmove
              switching = true
            else
              tmpmove                    = @pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
              @pokemon.moves[selmove]    = tmpmove
              @sprites["movepresel"].visible = false
              switching = false
              drawSelectedMove(0,@pokemon.moves[selmove].id)
            end
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        selmove = 0 if selmove>=4
        selmove = @pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index = selmove
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove = 0 if selmove>=4
        selmove = 4 if selmove<0
        @sprites["movesel"].index = selmove
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      end
    end
    @sprites["movesel"].visible=false
  end

  def pbMarking(pokemon)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    @sprites["markingsel"].visible     = true
    base   = Color.new(248,248,248)
    shadow = Color.new(104,104,104)
    ret = pokemon.markings
    markings = pokemon.markings
    index = 0
    redraw = true
    markrect = Rect.new(0,0,16,16)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        for i in 0...6
          markrect.x = i*16
          markrect.y = (markings&(1<<i)!=0) ? 16 : 0
          @sprites["markingoverlay"].bitmap.blt(300+58*(i%3),154+50*(i/3),@markingbitmap.bitmap,markrect)
        end
        textpos = [
           [_INTL("Mark {1}",pokemon.name),366,96,2,base,shadow],
           [_INTL("OK"),366,248,2,base,shadow],
           [_INTL("Cancel"),366,298,2,base,shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap,textpos)
        redraw = false
      end
      # Reposition the cursor
      @sprites["markingsel"].x = 284+58*(index%3)
      @sprites["markingsel"].y = 144+50*(index/3)
      if index==6   # OK
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 244
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height/2
      elsif index==7   # Cancel
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 294
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height/2
      else
        @sprites["markingsel"].src_rect.y = 0
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        if index==6   # OK
          ret = markings
          break
        elsif index==7   # Cancel
          break
        else
          mask = (1<<index)
          if (markings&mask)==0
            markings |= mask
          else
            markings &= ~mask
          end
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index==7;    index = 6
        elsif index==6; index = 4
        elsif index<3;  index = 7
        else;           index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index==7;    index = 1
        elsif index==6; index = 7
        elsif index>=3; index = 6
        else;           index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index<6
          index -= 1
          index += 3 if index%3==2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index<6
          index += 1
          index -= 3 if index%3==0
          pbPlayCursorSE
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    @sprites["markingsel"].visible     = false
    if pokemon.markings!=ret
      pokemon.markings = ret
      return true
    end
    return false
  end

  def pbOptions
    dorefresh = false
    commands   = []
    cmdGiveItem = -1
    cmdTakeItem = -1
    cmdPokedex  = -1
    cmdMark     = -1
    if !@pokemon.egg?
      commands[cmdGiveItem = commands.length] = _INTL("Give item")
      commands[cmdTakeItem = commands.length] = _INTL("Take item") if @pokemon.hasItem?
      commands[cmdPokedex = commands.length]  = _INTL("View Pokédex") if $Trainer.pokedex
    end
    commands[cmdMark = commands.length]       = _INTL("Mark")
    commands[commands.length]                 = _INTL("Cancel")
    command = pbShowCommands(commands)
    if cmdGiveItem>=0 && command==cmdGiveItem
      item = 0
      pbFadeOutIn {
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene,$PokemonBag)
        item = screen.pbChooseItemScreen(Proc.new { |item| pbCanHoldItem?(item) })
      }
      if item>0
        dorefresh = pbGiveItemToPokemon(item,@pokemon,self,@partyindex)
      end
    elsif cmdTakeItem>=0 && command==cmdTakeItem
      dorefresh = pbTakeItemFromPokemon(@pokemon,self)
    elsif cmdPokedex>=0 && command==cmdPokedex
      pbUpdateLastSeenForm(@pokemon)
      pbFadeOutIn {
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbStartSceneSingle(@pokemon.species)
      }
      dorefresh = true
    elsif cmdMark>=0 && command==cmdMark
      dorefresh = pbMarking(@pokemon)
    end
    return dorefresh
  end

  def pbChooseMoveToForget(moveToLearn)
    selmove = 0
    maxmove = (moveToLearn>0) ? 4 : 3
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        selmove = 4
        pbPlayCloseMenuSE if moveToLearn>0
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove<0
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(moveToLearn,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove>maxmove
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = (moveToLearn>0) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(moveToLearn,newmove)
      end
    end
    return (selmove==4) ? -1 : selmove
  end

  def pbScene
    pbPlayCry(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::A)
        pbSEStop
        pbPlayCry(@pokemon)
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        if @page==3
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        end
      elsif Input.trigger?(Input::UP) && @partyindex>0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          pbChangePokemon
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex!=oldindex
          pbChangePokemon
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 1 if @page<1
        @page = @pagecount if @page>@pagecount
        if @page!=oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 1 if @page<1
        @page = @pagecount if @page>@pagecount
        if @page!=oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          dorefresh = true
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @partyindex
  end

  def getGenderInformation(x, y)
    if @pokemon.isMale?
      # Write Male Symbol
      return [_INTL("♂"),x,y,0,Color.new(24,112,216),Color.new(136,168,208)]
    elsif @pokemon.isFemale?
      # Write Female Symbol
      return [_INTL("♀"),x,y,0,Color.new(248,56,32),Color.new(224,152,144)]
    end
  end

  # This method draws the type icons on the summary screen
  #
  # overlay = The screen where to draw on
  # oneX = The x coordinate when the pokemon only has 1 Type
  # oneY = The y coordinate when the pokemon only has 1 Type
  # firstX = The x coordinate for the first type
  # firstY = The y coordinate for the first type
  # secondX = The x coordinate for the second type
  # secondY = The y coordinate for the second type
  def drawPokemonTypes(overlay, oneX, oneY, firstX, firstY, secondX, secondY)
    type1rect = Rect.new(0, @pokemon.type1*28, 64, 28)
    type2rect = Rect.new(0, @pokemon.type2*28, 64, 28)
    if @pokemon.type1==@pokemon.type2
      overlay.blt(oneX,oneY,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(firstX,firstY,@typebitmap.bitmap,type1rect)
      overlay.blt(secondX,secondY,@typebitmap.bitmap,type2rect)
    end
  end

  def drawOwnerInformation(overlay, otNameX, otNameY, otNameOrientation, otIdX, otIdY, otIdOrientation)
    textpos = []
    if @pokemon.ot==""
      textpos.push([_INTL("RENTAL"),otNameX,otNameY,otNameOrientation,@basecolor,@shadowcolor])
      textpos.push(["?????",otIdX,otIdY,otIdOrientation,@basecolor,@shadowcolor])
    else
      ownerbase   = Color.new(64,64,64)
      ownershadow = Color.new(176,176,176)
      case @pokemon.otgender
      when 0; ownerbase = Color.new(24,112,216); ownershadow = Color.new(136,168,208)
      when 1; ownerbase = Color.new(248,56,32);  ownershadow = Color.new(224,152,144)
      end
      textpos.push([@pokemon.ot,otNameX,otNameY,otNameOrientation,ownerbase,ownershadow])
      textpos.push([sprintf("%05d",@pokemon.publicID),otIdX,otIdY,otIdOrientation,@basecolor,@shadowcolor])
    end
    pbDrawTextPositions(overlay,textpos)
  end

  def drawItemInformation(overlay, x, y, orientation)
    if @pokemon.hasItem?
      pbDrawTextPositions(overlay, [[PBItems.getName(@pokemon.item),x,y,orientation,@basecolor,@shadowcolor]])
    else
      pbDrawTextPositions(overlay, [[_INTL("None"),x,y,orientation,@basecolor,@shadowcolor]])
    end
  end

  def drawPokemonDexNum(overlay, x, y, orientation)
    dexnum = @pokemon.species
    dexnumshift = false
    if $PokemonGlobal.pokedexUnlocked[$PokemonGlobal.pokedexUnlocked.length-1]
      dexnumshift = true if DEXES_WITH_OFFSETS.include?(-1)
    else
      dexnum = 0
      for i in 0...$PokemonGlobal.pokedexUnlocked.length-1
        if $PokemonGlobal.pokedexUnlocked[i]
          num = pbGetRegionalNumber(i,@pokemon.species)
          if num>0
            dexnum = num
            dexnumshift = true if DEXES_WITH_OFFSETS.include?(i)
            break
          end
        end
      end
    end
    if dexnum<=0
      pbDrawTextPositions(overlay,[["???",x,y,orientation,@basecolor,@shadowcolor]])
    else
      dexnum -= 1 if dexnumshift
      pbDrawTextPositions(overlay,
                          [
                              [sprintf("%03d",dexnum),x,y,orientation,@basecolor,@shadowcolor]
                          ]
      )
    end
  end

  def getMetDate
    text = ""
    if @pokemon.timeReceived
      date = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year = @pokemon.timeReceived.year
      text += _INTL("on {1} {2}, {3}.",month,date,year)
    end
    return text
  end

  def getMetText
    text = ""
    mapname = pbGetMapNameFromId(@pokemon.obtainMap)
    if (@pokemon.obtainText rescue false) && @pokemon.obtainText != ""
      mapname = @pokemon.obtainText
    end
    mapname = _INTL("Faraway place") if !mapname && mapname == ""
    #text += sprintf("Met in %s at Lv %d",mapname, @pokemon.obtainLevel)
    if (@pokemon.obtainMode==1)
      text += sprintf("Hatched from an Egg given by %s",mapname)
    else
      text += sprintf("Met in %s at Lv %d",mapname, @pokemon.obtainLevel)
    end
    return text
  end

  def getPokemonCharacteristic
    bestiv     = 0
    tiebreaker = @pokemon.personalID%6
    for i in 0...6
      if @pokemon.iv[i]==@pokemon.iv[bestiv]
        bestiv = i if i>=tiebreaker && bestiv<tiebreaker
      elsif @pokemon.iv[i]>@pokemon.iv[bestiv]
        bestiv = i
      end
    end
    [
        _INTL("Loves to eat."),
        _INTL("Often dozes off."),
        _INTL("Often scatters things."),
        _INTL("Scatters things often."),
        _INTL("Likes to relax."),
        _INTL("Proud of its power."),
        _INTL("Likes to thrash about."),
        _INTL("A little quick tempered."),
        _INTL("Likes to fight."),
        _INTL("Quick tempered."),
        _INTL("Sturdy body."),
        _INTL("Capable of taking hits."),
        _INTL("Highly persistent."),
        _INTL("Good endurance."),
        _INTL("Good perseverance."),
        _INTL("Likes to run."),
        _INTL("Alert to sounds."),
        _INTL("Impetuous and silly."),
        _INTL("Somewhat of a clown."),
        _INTL("Quick to flee."),
        _INTL("Highly curious."),
        _INTL("Mischievous."),
        _INTL("Thoroughly cunning."),
        _INTL("Often lost in thought."),
        _INTL("Very finicky."),
        _INTL("Strong willed."),
        _INTL("Somewhat vain."),
        _INTL("Strongly defiant."),
        _INTL("Hates to lose."),
        _INTL("Somewhat stubborn.")
    ][bestiv*5+@pokemon.iv[bestiv]%5]
  end

  def drawShadowInformationText(overlay)
    heartmessage = [_INTL("The door to its heart is open! Undo the final lock!"),
                    _INTL("The door to its heart is almost fully open."),
                    _INTL("The door to its heart is nearly open."),
                    _INTL("The door to its heart is opening wider."),
                    _INTL("The door to its heart is opening up."),
                    _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
    drawFormattedTextEx(overlay, 20, 296, 486, heartmessage)
  end

  def getEggMetText
    text = "An odd POKèMON EGG received "

    mapname = pbGetMapNameFromId(@pokemon.obtainMap)
    if (@pokemon.obtainText rescue false) && @pokemon.obtainText!=""
      mapname=@pokemon.obtainText
    end
    if mapname && mapname!=""
      text+=_INTL(" from {1} ",mapname)
    end

    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      text += _INTL("on {1} {2}, {3}.",month,date,year)
    end
    text
  end

  def getEggState
    eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
    eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.") if @pokemon.eggsteps<102
    eggstate = _INTL("It appears to move occasionally. It may be close to hatching.") if @pokemon.eggsteps<255
    eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!") if @pokemon.eggsteps<1275

    eggstate
  end

  def drawStats(overlay)
    endexp = PBExperience.pbGetStartExperience(@pokemon.level + 1, @pokemon.growthrate)
    textpos = [
        [sprintf("%d/%d",@pokemon.hp,@pokemon.totalhp),505,40,1,@basecolor,@shadowcolor],
        [sprintf("%d",@pokemon.attack),505,76,1,@basecolor,@shadowcolor],
        [sprintf("%d",@pokemon.defense),505,102,1,@basecolor,@shadowcolor],
        [sprintf("%d",@pokemon.spatk),505,128,1,@basecolor,@shadowcolor],
        [sprintf("%d",@pokemon.spdef),505,154,1,@basecolor,@shadowcolor],
        [sprintf("%d",@pokemon.speed),505,180,1,@basecolor,@shadowcolor],
        [sprintf("%s",PBAbilities.getName(@pokemon.ability)),144,326,0,@basecolor,@shadowcolor],
        [sprintf(_INTL('EXP.POINTS')),144,276,0,@basecolor,@shadowcolor],
        [sprintf("%s",@pokemon.exp.to_s_formatted),502,276,1,@basecolor,@shadowcolor],
        [sprintf(_INTL('NEXT LV.')),144,300,0,@basecolor,@shadowcolor],
        [sprintf("%s",(endexp-@pokemon.exp).to_s_formatted),502,300,1,@basecolor,@shadowcolor],
    ]
    # Write all text
    pbDrawTextPositions(overlay,textpos)
  end

  def drawHpBar(overlay, x, y)
    # Draw HP bar
    if @pokemon.hp>0
      hpzone = 0
      hpzone = 1 if @pokemon.hp<=(@pokemon.totalhp/2).floor
      hpzone = 2 if @pokemon.hp<=(@pokemon.totalhp/4).floor
      imagepos = [
          ["Graphics/Pictures/Summary/overlay_hp",x,y,0,hpzone*6,@pokemon.hp*112/@pokemon.totalhp,6]
      ]
      pbDrawImagePositions(overlay,imagepos)
    end
  end

  def drawExpBar(overlay, x, y)
    startexp = PBExperience.pbGetStartExperience(@pokemon.level, @pokemon.growthrate)
    endexp = PBExperience.pbGetStartExperience(@pokemon.level + 1, @pokemon.growthrate)
    if @pokemon.level<PBExperience.maxLevel
      pbDrawImagePositions(overlay, [
          ["Graphics/Pictures/Summary/overlay_exp",x,y,0,0,(@pokemon.exp-startexp) * 128 / (endexp-startexp),6]
      ])
    end
  end

  def getMoveTextPositions(moveToLearn)
    imagepos = []
    textpos = []
    ypos = 40
    if moveToLearn == 0
      for moveIndex in 0...@pokemon.moves.length
        move = @pokemon.moves[moveIndex]
        if move.id > 0
          imagepos.push(["Graphics/Pictures/types",246,ypos,0,move.type*28,64,28])
          textpos.push([sprintf("%s", PBMoves.getName(move.id)),317,ypos + 6, 0, @basecolor,@shadowcolor])
          textpos.push([sprintf("PP: %d/%d", move.pp, move.totalpp),415,ypos+28,0,@basecolor,@shadowcolor])
        end
        ypos += 60
      end
    else
      for moveIndex in 0...5
        move = @pokemon.moves[moveIndex]
        if moveIndex == 4
          move = PBMove.new(moveToLearn)
          ypos += 20
        end
        if move.id > 0
          imagepos.push(["Graphics/Pictures/types",246,ypos,0,move.type*28,64,28])
          textpos.push([sprintf("%s", PBMoves.getName(move.id)),317,ypos + 6, 0, @basecolor,@shadowcolor])
          textpos.push([sprintf("PP: %d/%d", move.pp, move.totalpp),415,ypos+28,0,@basecolor,@shadowcolor])
        end
        ypos += 60
      end
    end
    [imagepos, textpos]
  end

  def drawEvIvStats(overlay)
    textpos = [
        [_INTL("{1}", @pokemon.iv[0]), 373,66,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.iv[1]), 373,92,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.iv[2]), 373,118,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.iv[4]), 373,144,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.iv[5]), 373,170,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.iv[3]), 373,196,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.ev[0]), 467,66,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.ev[1]), 467,92,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.ev[2]), 467,118,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.ev[4]), 467,144,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.ev[5]), 467,170,2,@basecolor,@shadowcolor],
        [_INTL("{1}", @pokemon.ev[3]), 467,196,2,@basecolor,@shadowcolor],
    ]

    pbDrawTextPositions(overlay, textpos)
  end

  def getMoveTextPositions(moveToLearn)
    imagepos = []
    textpos = []
    ypos = 40
    if moveToLearn == 0
      for moveIndex in 0...@pokemon.moves.length
        move = @pokemon.moves[moveIndex]
        if move.id > 0
          imagepos.push(["Graphics/Pictures/types",246,ypos,0,move.type*28,64,28])
          textpos.push([sprintf("%s", PBMoves.getName(move.id)),317,ypos + 6, 0, @basecolor,@shadowcolor])
          textpos.push([sprintf("PP %d/%d", move.pp, move.totalpp),415,ypos+28,0,@basecolor,@shadowcolor])
        end
        ypos += 60
      end
    else
      for moveIndex in 0...5
        move = @pokemon.moves[moveIndex]
        if moveIndex == 4
          move = PBMove.new(moveToLearn)
          ypos += 20
        end
        if move.id > 0
          imagepos.push(["Graphics/Pictures/types",246,ypos,0,move.type*28,64,28])
          textpos.push([sprintf("%s", PBMoves.getName(move.id)),317,ypos + 6, 0, @basecolor,@shadowcolor])
          textpos.push([sprintf("PP: %d/%d", move.pp, move.totalpp),415,ypos+28,0,@basecolor,@shadowcolor])
        end
        ypos += 60
      end
    end
    [imagepos, textpos]
  end

  def getMoveSelectionGraphic(newMove)
    if newMove
      @pokemon.isShiny? ? "bg_learnmove_s" : "bg_learnmove"
    else
      @pokemon.isShiny? ? "bg_moveselect_s" : "bg_moveselect"
    end
  end
end

class PokemonSummaryScreen
  def initialize(scene,inbattle=false)
    @scene = scene
    @inbattle = inbattle
  end

  def pbStartScreen(party,partyindex)
    @scene.pbStartScene(party,partyindex,@inbattle)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party,partyindex,moveToLearn)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,moveToLearn)
    loop do
      ret = @scene.pbChooseMoveToForget(moveToLearn)
      if ret>=0 && moveToLearn!=0 && pbIsHiddenMove?(party[partyindex].moves[ret].id) && !$DEBUG
        pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party,partyindex,message)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,0)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(0)
      if ret<0
        pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end
end
