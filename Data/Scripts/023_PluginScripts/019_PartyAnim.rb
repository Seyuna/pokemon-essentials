

class PokemonParty_Scene
  def pbAnimForme(pkmn,form=0,nform=-1)
    partynum = -1
    for i in 0...$Trainer.party.length
      partynum = i if pkmn.personalID == $Trainer.party[i].personalID
      break if partynum !=  -1
    end
    return false if partynum == -1
    frm = pkmn.isSpecies?(:ARENAY)? nform : form
    if pbResolveBitmap("Graphics/Pictures/Party/animform#{pkmn.species}_#{frm}")
      tempSpr = Bitmap.new("Graphics/Pictures/Party/animform#{pkmn.species}_#{frm}")
      frames = (tempSpr.width)/tempSpr.height
      size = tempSpr.height
      @sprites["formeanim"]=AnimatedSprite.new("Graphics/Pictures/Party/animform#{pkmn.species}_#{frm}",frames,size,size,0,@viewport)
      pbSEPlay("animform")
    elsif pbResolveBitmap("Graphics/Pictures/Party/animform#{pkmn.species}")
      tempSpr = Bitmap.new("Graphics/Pictures/Party/animform#{pkmn.species}")
      frames = (tempSpr.width)/tempSpr.height
      size = tempSpr.height
      @sprites["formeanim"]=AnimatedSprite.new("Graphics/Pictures/Party/animform#{pkmn.species}",frames,size,size,0,@viewport)
      pbSEPlay("animform")
    else
      frames = 18
      size = 125
      @sprites["formeanim"]=AnimatedSprite.new("Graphics/Pictures/Party/animform",frames,size,size,0,@viewport)
      pbSEPlay("animform")
    end
    valX = (size>125) ? -15 : 5
    valY = (size>125) ? -40 : -20
    @sprites["formeanim"].z = 99999
    @sprites["formeanim"].x = @sprites["pokemon#{partynum}"].x+valX
    @sprites["formeanim"].y = @sprites["pokemon#{partynum}"].y+valY
    @sprites["formeanim"].play
    changed=false if nform!=-1
    for i in 0...(frames*3)
      Graphics.update
      Input.update
      update
      if nform!=-1 && !changed
        if i==(frames*3)/2 && pkmn.fused==nil
          pkmn.setForm(nform) if nform!=-1
          pbRefresh
          changed=true
        elsif i==(frames*3)-24 && pkmn.fused!=nil
          pkmn.setForm(nform) if nform!=-1 && pkmn.fused!=nil
          $Trainer.party[$Trainer.party.length] = pkmn.fused
          pkmn.fused = nil
          changed=true
          pbHardRefresh
        end
      end
    end
    @sprites["formeanim"].dispose
    pbPlayCry(pkmn)
  end

  def pbAnimFormeFusion(pkmn1,pkmn2,nform=-1,nform2=-1)
    partynum = -1
    partynum2 = -1
    for i in 0...$Trainer.party.length
      partynum = i if pkmn1.personalID == $Trainer.party[i].personalID
      partynum2 = i if pkmn2.personalID == $Trainer.party[i].personalID
      break if partynum !=  -1 && partynum2 !=  -1
    end
    return false if partynum == -1 || partynum == -1
    @sprite = {}
    if pbResolveBitmap("Graphics/Pictures/Party/animform#{pkmn1.species}")
      tempSpr = Sprite.new(@viewport)
      tempSpr.bitmap = Bitmap.new("Graphics/Pictures/Party/animform#{pkmn1.species}")
      tempSpr.visible = false
      frames = (tempSpr.width)/tempSpr.height
      size = tempSpr.height
      @sprite["formeanim"]=AnimatedSprite.new("Graphics/Pictures/Party/animform#{pkmn1.species}",frames,size,size,0,@viewport)
      tempSpr.dispose
    else
      frames = 18
      size = 125
      @sprites["formeanim"]=AnimatedSprite.new("Graphics/Pictures/Party/animform",frames,size,size,0,@viewport)
    end
    if pbResolveBitmap("Graphics/Pictures/Party/animform#{pkmn2.species}")
      tempSpr = Sprite.new(@viewport)
      tempSpr.bitmap = Bitmap.new("Graphics/Pictures/Party/animform#{pkmn2.species}")
      tempSpr.visible = false
      frames2 = (tempSpr.width)/tempSpr.height
      size2 = tempSpr.height
      @sprite["formeanim2"]=AnimatedSprite.new("Graphics/Pictures/Party/animform#{pkmn2.species}",frames2,size2,size2,0,@viewport)
      tempSpr.dispose
    else
      frames2 = 18
      size2 = 125
      @sprites["formeanim"]=AnimatedSprite.new("Graphics/Pictures/Party/animform",frames,size,size,0,@viewport)
    end
    @sprite["formeanim"].x = @sprites["pokemon#{partynum}"].x-15
    @sprite["formeanim"].y = @sprites["pokemon#{partynum}"].y-40
    @sprite["formeanim"].play
    @sprite["formeanim2"].x = @sprites["pokemon#{partynum2}"].x-15
    @sprite["formeanim2"].y = @sprites["pokemon#{partynum2}"].y-40
    @sprite["formeanim"].z = 99999
    @sprite["formeanim2"].z = 99999
    @sprite["formeanim"].play
    @sprite["formeanim2"].play
    changed=false if nform!=-1
    value = (frames2>frames)? frames2 : frames
    for i in 0...(value*3)
      Graphics.update
      Input.update
      @sprite["formeanim"].update if i<=(frames*3)
      @sprite["formeanim2"].update if i<=(frames2*3)
      update
      if nform!=-1 && !changed
        if i==(value*3)-24
          pkmn1.setForm(nform2) if nform!=-1
          pkmn1.fused = pkmn2
          pbRemovePokemonAt(partynum2)
          pbHardRefresh
          changed=true
        end
      end
    end
    @sprite["formeanim"].dispose
    @sprite["formeanim2"].dispose
    @sprite = {}
  end
end

class PokemonPartyScreen
  def pbAnimForme(pkmn,form,nform)
    @scene.pbAnimForme(pkmn,form,nform)
  end

  def pbAnimFormeFusion(pkmn,pkmn2,nform,nform2)
    @scene.pbAnimFormeFusion(pkmn,pkmn2,nform,nform2)
  end

  def pbPokemonGiveScreen(item)
    @scene.pbStartScene(@party,_INTL("Give to which Pokémon?"))
    pkmnid = @scene.pbChoosePokemon
    ret = false
    pkmn = @party[pkmnid]
    oldForm = pkmn.form
    if pkmnid>=0
      ret = pbGiveItemToPokemon(item,@party[pkmnid],self,pkmnid)
    end
    pbAnimForme(pkmn,oldForm,pkmn.form) if pkmn.form!=oldForm
    @scene.pbEndScene
    return ret
  end

  def pbPokemonScreen
    @scene.pbStartScene(@party,
       (@party.length>1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."),nil)
    loop do
      @scene.pbSetHelpText((@party.length>1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      pkmnid = @scene.pbChoosePokemon(false,-1,1)
      break if (pkmnid.is_a?(Numeric) && pkmnid<0) || (pkmnid.is_a?(Array) && pkmnid[1]<0)
      if pkmnid.is_a?(Array) && pkmnid[0]==1   # Switch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid[1]
        pkmnid = @scene.pbChoosePokemon(true,-1,2)
        if pkmnid>=0 && pkmnid!=oldpkmnid
          pbSwitch(oldpkmnid,pkmnid)
        end
        next
      end
      pkmn = @party[pkmnid]
      commands   = []
      cmdSummary = -1
      cmdDebug   = -1
      cmdMoves   = [-1,-1,-1,-1]
      cmdRename  = -1
      cmdSwitch  = -1
      cmdMail    = -1
      cmdItem    = -1
      # Build the commands
      commands[cmdSummary = commands.length]      = _INTL("Summary")
      commands[cmdDebug = commands.length]        = _INTL("Debug") if $DEBUG
      for i in 0...pkmn.moves.length
        move = pkmn.moves[i]
        # Check for hidden moves and add any that were found
        if !pkmn.egg? && (isConst?(move.id,PBMoves,:MILKDRINK) ||
                          isConst?(move.id,PBMoves,:SOFTBOILED))# ||
#                          HiddenMoveHandlers.hasHandler(move.id))
          commands[cmdMoves[i] = commands.length] = [PBMoves.getName(move.id),1]
        end
      end
      #Thundaga rename
      commands[cmdRename = commands.length]       = _INTL("Rename")
      commands[cmdSwitch = commands.length]       = _INTL("Switch") if @party.length>1
      if !pkmn.egg?
        if pkmn.mail
          commands[cmdMail = commands.length]     = _INTL("Mail")
        else
          commands[cmdItem = commands.length]     = _INTL("Item")
        end
      end
      commands[commands.length]                   = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?",pkmn.name),commands)
      havecommand = false
      for i in 0...4
        if cmdMoves[i]>=0 && command==cmdMoves[i]
          havecommand = true
          if isConst?(pkmn.moves[i].id,PBMoves,:SOFTBOILED) ||
             isConst?(pkmn.moves[i].id,PBMoves,:MILKDRINK)
            amt = [(pkmn.totalhp/5).floor,1].max
            if pkmn.hp<=amt
              pbDisplay(_INTL("Not enough HP..."))
              break
            end
            @scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
            oldpkmnid = pkmnid
            loop do
              @scene.pbPreSelect(oldpkmnid)
              pkmnid = @scene.pbChoosePokemon(true,pkmnid)
              break if pkmnid<0
              newpkmn = @party[pkmnid]
              movename = PBMoves.getName(pkmn.moves[i].id)
              if pkmnid==oldpkmnid
                pbDisplay(_INTL("{1} can't use {2} on itself!",pkmn.name,movename))
              elsif newpkmn.egg?
                pbDisplay(_INTL("{1} can't be used on an Egg!",movename))
              elsif newpkmn.hp==0 || newpkmn.hp==newpkmn.totalhp
                pbDisplay(_INTL("{1} can't be used on that Pokémon.",movename))
              else
                pkmn.hp -= amt
                hpgain = pbItemRestoreHP(newpkmn,amt)
                @scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.",newpkmn.name,hpgain))
                pbRefresh
              end
              break if pkmn.hp<=amt
            end
            @scene.pbSelect(oldpkmnid)
            pbRefresh
            break
          else
            break
          end
        end
      end
      next if havecommand
      if cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid) {
          @scene.pbSetHelpText((@party.length>1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
        }
      elsif cmdDebug>=0 && command==cmdDebug
        pbPokemonDebug(pkmn,pkmnid)
      elsif cmdSwitch>=0 && command==cmdSwitch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid
        pkmnid = @scene.pbChoosePokemon(true)
        if pkmnid>=0 && pkmnid!=oldpkmnid
          pbSwitch(oldpkmnid,pkmnid)
        end
      elsif cmdRename>=0 && command==cmdRename
        @scene.pbDisplay(_INTL("Choose the Nickname that you want."))
        speciesname = PBSpecies.getName(pkmn.species)
        oldname = (pkmn.name && pkmn.name!=speciesname) ? pkmn.name : ""
        newname = pbEnterPokemonName(_INTL("{1}'s nickname?",speciesname),
            0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,oldname,pkmn)
        if newname && newname!=""
          pkmn.name = newname
          pbRefreshSingle(pkmnid)
        elsif newname="" #if the name is null, will...
          pkmn.name = speciesname #...change its name from the species name
          pbRefreshSingle(pkmnid)
        end
      elsif cmdMail>=0 && command==cmdMail
        command = @scene.pbShowCommands(_INTL("Do what with the mail?"),
           [_INTL("Read"),_INTL("Take"),_INTL("Cancel")])
        case command
        when 0   # Read
          pbFadeOutIn {
            pbDisplayMail(pkmn.mail,pkmn)
            @scene.pbSetHelpText((@party.length>1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
          }
        when 1   # Take
          oldForm = pkmn.form
          if pbTakeItemFromPokemon(pkmn,self)
            pbAnimForme(pkmn,oldForm,pkmn.form) if pkmn.form!=oldForm
          end
        end
      elsif cmdItem>=0 && command==cmdItem
        itemcommands = []
        cmdUseItem   = -1
        cmdGiveItem  = -1
        cmdTakeItem  = -1
        cmdMoveItem  = -1
        # Build the commands
        itemcommands[cmdUseItem=itemcommands.length]  = _INTL("Use")
        itemcommands[cmdGiveItem=itemcommands.length] = _INTL("Give")
        itemcommands[cmdTakeItem=itemcommands.length] = _INTL("Take") if pkmn.hasItem?
        itemcommands[cmdMoveItem=itemcommands.length] = _INTL("Move") if pkmn.hasItem? && !pbIsMail?(pkmn.item)
        itemcommands[itemcommands.length]             = _INTL("Cancel")
        command = @scene.pbShowCommands(_INTL("Do what with an item?"),itemcommands)
        if cmdUseItem>=0 && command==cmdUseItem   # Use
          item = @scene.pbUseItem($PokemonBag,pkmn) {
            @scene.pbSetHelpText((@party.length>1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
          }
          if item>0
            pbUseItemOnPokemon(item,pkmn,self)
            pbRefreshSingle(pkmnid)
          end
        elsif cmdGiveItem>=0 && command==cmdGiveItem   # Give
          item = @scene.pbChooseItem($PokemonBag) {
            @scene.pbSetHelpText((@party.length>1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
          }
          if item>0
            oldForm = pkmn.form
            if pbGiveItemToPokemon(item,pkmn,self,pkmnid)
              pbAnimForme(pkmn,oldForm,pkmn.form) if pkmn.form!=oldForm
            end
            pbRefreshSingle(pkmnid)
          end
        elsif cmdTakeItem>=0 && command==cmdTakeItem   # Take
          oldForm = pkmn.form
          if pbTakeItemFromPokemon(pkmn,self)
            pbAnimForme(pkmn,oldForm,pkmn.form) if pkmn.form!=oldForm
          end
          pbRefreshSingle(pkmnid)
        elsif cmdMoveItem>=0 && command==cmdMoveItem   # Move
          item = pkmn.item
          itemname = PBItems.getName(item)
          @scene.pbSetHelpText(_INTL("Move {1} to where?",itemname))
          oldpkmnid = pkmnid
          loop do
            @scene.pbPreSelect(oldpkmnid)
            pkmnid = @scene.pbChoosePokemon(true,pkmnid)
            break if pkmnid<0
            newpkmn = @party[pkmnid]
            if pkmnid==oldpkmnid
              break
            elsif newpkmn.egg?
              pbDisplay(_INTL("Eggs can't hold items."))
            elsif !newpkmn.hasItem?
              oldForm = newpkmn.form
              newpkmn.setItem(item)
              pkmn.setItem(0)
              @scene.pbClearSwitching
              pbAnimForme(newpkmn,oldForm,newpkmn.form) if newpkmn.form!=oldForm
              pbRefresh
              pbDisplay(_INTL("{1} was given the {2} to hold.",newpkmn.name,itemname))
              break
            elsif pbIsMail?(newpkmn.item)
              pbDisplay(_INTL("{1}'s mail must be removed before giving it an item.",newpkmn.name))
            else
              newitem = newpkmn.item
              newitemname = PBItems.getName(newitem)
              if isConst?(newitem,PBItems,:LEFTOVERS)
                pbDisplay(_INTL("{1} is already holding some {2}.\1",newpkmn.name,newitemname))
              elsif newitemname.starts_with_vowel?
                pbDisplay(_INTL("{1} is already holding an {2}.\1",newpkmn.name,newitemname))
              else
                pbDisplay(_INTL("{1} is already holding a {2}.\1",newpkmn.name,newitemname))
              end
              if pbConfirm(_INTL("Would you like to switch the two items?"))
                oldForm1 = newpkmn.form
                oldForm2 = pkmn.form
                newpkmn.setItem(item)
                pkmn.setItem(newitem)
                @scene.pbClearSwitching
                pbDisplay(_INTL("{1} was given the {2} to hold.",newpkmn.name,itemname))
                pbDisplay(_INTL("{1} was given the {2} to hold.",pkmn.name,newitemname))
                pbAnimForme(newpkmn,oldForm1,newpkmn.form) if newpkmn.form!=oldForm1
                pbAnimForme(pkmn,oldForm2,pkmn.form) if pkmn.form!=oldForm2
                break
              end
            end
          end
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end

ItemHandlers::UseOnPokemon.add(:GRACIDEA,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:SHAYMIN) || pkmn.form!=0 ||
     pkmn.status==PBStatuses::FROZEN || PBDayNight.isNight?
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
    next false
  end
  scene.pbAnimForme(pkmn,0,1)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:REDNECTAR,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form==0
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
  end
  scene.pbAnimForme(pkmn,pkmn.form,0)
  scene.pbDisplay(_INTL("{1} changed form!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:YELLOWNECTAR,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form==1
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
  end
  scene.pbAnimForme(pkmn,pkmn.form,1)
  scene.pbDisplay(_INTL("{1} changed form!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:PINKNECTAR,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form==2
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
  end
  scene.pbAnimForme(pkmn,pkmn.form,2)
  scene.pbDisplay(_INTL("{1} changed form!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:PURPLENECTAR,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:ORICORIO) || pkmn.form==3
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
  end
  scene.pbAnimForme(pkmn,pkmn.form,3)
  scene.pbDisplay(_INTL("{1} changed form!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:REVEALGLASS,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:TORNADUS) &&
     !pkmn.isSpecies?(:THUNDURUS) &&
     !pkmn.isSpecies?(:LANDORUS)
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
    next false
  end
  newForm = (pkmn.form==0) ? 1 : 0
  scene.pbAnimForme(pkmn,pkmn.form,newForm)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:PRISONBOTTLE,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:HOOPA)
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
  end
  newForm = (pkmn.form==0) ? 1 : 0
  scene.pbAnimForme(pkmn,pkmn.form,newForm)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:DNASPLICERS,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:KYUREM)
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
    next false
  end
  # Fusing
  if pkmn.fused==nil
    chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
    next false if chosen<0
    poke2 = $Trainer.party[chosen]
    if pkmn==poke2
      scene.pbDisplay(_INTL("It cannot be fused with itself."))
      next false
    elsif poke2.egg?
      scene.pbDisplay(_INTL("It cannot be fused with an Egg."))
      next false
    elsif poke2.fainted?
      scene.pbDisplay(_INTL("It cannot be fused with that fainted Pokémon."))
      next false
    elsif !poke2.isSpecies?(:RESHIRAM) &&
          !poke2.isSpecies?(:ZEKROM)
      scene.pbDisplay(_INTL("It cannot be fused with that Pokémon."))
      next false
    end
    newForm = 0
    newForm = 1 if poke2.isSpecies?(:RESHIRAM)
    newForm = 2 if poke2.isSpecies?(:ZEKROM)
    scene.pbAnimFormeFusion(pkmn,poke2,0,newForm)
    scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
    next true
  end
  # Unfusing
  if $Trainer.party.length>=6
    scene.pbDisplay(_INTL("You have no room to separate the Pokémon."))
    next false
  end
  scene.pbAnimForme(pkmn,pkmn.form,0)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:NSOLARIZER,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:NECROZMA) || pkmn.form == 2
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
    next false
  end
  # Fusing
  if pkmn.fused==nil
    chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
    next false if chosen<0
    poke2 = $Trainer.party[chosen]
    if pkmn==poke2
      scene.pbDisplay(_INTL("It cannot be fused with itself."))
      next false
    elsif poke2.egg?
      scene.pbDisplay(_INTL("It cannot be fused with an Egg."))
      next false
    elsif poke2.fainted?
      scene.pbDisplay(_INTL("It cannot be fused with that fainted Pokémon."))
      next false
    elsif !poke2.isSpecies?(:SOLGALEO)
      scene.pbDisplay(_INTL("It cannot be fused with that Pokémon."))
      next false
    end
    scene.pbAnimFormeFusion(pkmn,poke2,0,1)
    scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
    next true
  end
  # Unfusing
  if $Trainer.party.length>=6
    scene.pbDisplay(_INTL("You have no room to separate the Pokémon."))
    next false
  end
  scene.pbAnimForme(pkmn,pkmn.form,0)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:NLUNARIZER,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:NECROZMA) || pkmn.form == 1
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
    next false
  end
  # Fusing
  if pkmn.fused==nil
    chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
    next false if chosen<0
    poke2 = $Trainer.party[chosen]
    if pkmn==poke2
      scene.pbDisplay(_INTL("It cannot be fused with itself."))
      next false
    elsif poke2.egg?
      scene.pbDisplay(_INTL("It cannot be fused with an Egg."))
      next false
    elsif poke2.fainted?
      scene.pbDisplay(_INTL("It cannot be fused with that fainted Pokémon."))
      next false
    elsif !poke2.isSpecies?(:LUNALA)
      scene.pbDisplay(_INTL("It cannot be fused with that Pokémon."))
      next false
    end
    scene.pbAnimFormeFusion(pkmn,poke2,0,2)
    scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
    next true
  end
  # Unfusing
  if $Trainer.party.length>=6
    scene.pbDisplay(_INTL("You have no room to separate the Pokémon."))
    next false
  end
  scene.pbAnimForme(pkmn,pkmn.form,0)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:REINSOFUNITY,proc { |item,pkmn,scene|
  if !pkmn.isSpecies?(:CALYREX)
    scene.pbDisplay(_INTL("It had no effect."))
    next false
  end
  if pkmn.fainted?
    scene.pbDisplay(_INTL("This can't be used on the fainted Pokémon."))
    next false
  end
  # Fusing
  if pkmn.fused==nil
    chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
    next false if chosen<0
    poke2 = $Trainer.party[chosen]
    if pkmn==poke2
      scene.pbDisplay(_INTL("It cannot be fused with itself."))
      next false
    elsif poke2.egg?
      scene.pbDisplay(_INTL("It cannot be fused with an Egg."))
      next false
    elsif poke2.fainted?
      scene.pbDisplay(_INTL("It cannot be fused with that fainted Pokémon."))
      next false
    elsif !poke2.isSpecies?(:GLASTRIER) &&
          !poke2.isSpecies?(:SPECTRIER)
      scene.pbDisplay(_INTL("It cannot be fused with that Pokémon."))
      next false
    end
    newForm = 0
    newForm = 1 if poke2.isSpecies?(:GLASTRIER)
    newForm = 2 if poke2.isSpecies?(:SPECTRIER)
    scene.pbAnimFormeFusion(pkmn,poke2,0,newForm)
    scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
    next true
  end
  # Unfusing
  if $Trainer.party.length>=6
    scene.pbDisplay(_INTL("You have no room to separate the Pokémon."))
    next false
  end
  scene.pbAnimForme(pkmn,pkmn.form,0)
  scene.pbDisplay(_INTL("{1} changed Forme!",pkmn.name))
  next true
})
