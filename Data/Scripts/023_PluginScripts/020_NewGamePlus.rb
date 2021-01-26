NEW_GAME_PLUS_SWITCH = 400

# What New Game Plus does
=begin
Exp Gain +25%
Money Gain +50%
Wild Levels +2
Trainer Levels +3
Shiny Chance +5%
Hidden Ability Chance +10%
Wild Pokemon IVs +4
Max IV Wild Pokemon Chance +20%
=end

module NewGamePlusData
  def self.expGain
    return 1 if !$Trainer
    ret = 1
    ret += (0.25 * $Trainer.newGamePlusCount)
    return ret
  end

  def self.moneyGain
    return 1 if !$Trainer
    ret = 1
    ret += (0.5 * $Trainer.newGamePlusCount)
    return ret
  end

  def self.trainerLevels
#    return 0
    return 0 if !$Trainer
    ret = 0
    ret += (1 * $Trainer.newGamePlusCount)
    return ret
  end

  def self.wildLevels
#    return 0
    return 0 if !$Trainer
    ret = 0
    ret += (2 * $Trainer.newGamePlusCount)
    return ret
  end

  def self.shinyChance
    return SHINY_POKEMON_CHANCE if !$Trainer
    ret = SHINY_POKEMON_CHANCE
    ret *= (1 - (0.05 * $Trainer.newGamePlusCount))
    ret = ret.floor.to_i
    return ret
  end

  def self.hiddenAbilChance
    return 0 if !$Trainer
    ret = 0
    ret += (0.1 * $Trainer.newGamePlusCount)
    ret = ret.floor.to_i
    return ret
  end

  def self.maxIVChance
    return 0 if !$Trainer
    ret = 200
    ret *= (1 - (0.2 * $Trainer.newGamePlusCount))
    ret = ret.floor.to_i
    return ret
  end

  def self.pkmnIVOffset
    return 0 if !$Trainer
    ret = 0
    ret += (5 * $Trainer.newGamePlusCount)
    return ret
  end
end

# Method to return Trainer's Old Pokemon and Storage, and also give the Player a free Big Nugget
# MAKE SURE TO DO THIS BEFORE GETTING ARENAY ELSE IT WILL BE WIPED FROM THE PARTY
def pbNewGamePlusGoodies
  return if !$PokemonTemp.begunNewGamePlus
  $Trainer.party = $PokemonTemp.oldParty
  $PokemonStorage = $PokemonTemp.oldStorage
  $PokemonBag.pbStoreItem(:BIGNUGGET,1)
end

#Editing the Load Screen to show the New Game Plus option
class PokemonLoadScreen
  def pbStartLoadScreen
    $PokemonTemp   = PokemonTemp.new
    $game_temp     = Game_Temp.new
    $game_system   = Game_System.new
    $PokemonSystem = PokemonSystem.new if !$PokemonSystem
    savefile = RTP.getSaveFileName("Game.rxdata")
    FontInstaller.install if !mkxp?
    data_system = pbLoadRxData("Data/System")
    mapfile = sprintf("Data/Map%03d.rxdata",data_system.start_map_id)
    if data_system.start_map_id==0 || !pbRgssExists?(mapfile)
      pbMessage(_INTL("No starting position was set in the map editor.\1"))
      pbMessage(_INTL("The game cannot continue."))
      @scene.pbEndScene
      $scene = nil
      return
    end
    commands = []
    cmdContinue    = -1
    cmdNewGame     = -1
    cmdOption      = -1
    cmdLanguage    = -1
    cmdMysteryGift = -1
    cmdNGPlus      = -1
    cmdDebug       = -1
    cmdQuit        = -1
    if safeExists?(savefile)
      trainer      = nil
      framecount   = 0
      mapid        = 0
      haveBackup   = false
      showContinue = false
      begin
        trainer, framecount, $game_system, $PokemonSystem, mapid = pbTryLoadFile(savefile)
        showContinue = true
      rescue
        if safeExists?(savefile+".bak")
          begin
            trainer, framecount, $game_system, $PokemonSystem, mapid = pbTryLoadFile(savefile+".bak")
            haveBackup   = true
            showContinue = true
          rescue
          end
        end
        if haveBackup
          pbMessage(_INTL("The save file is corrupt. The previous save file will be loaded."))
        else
          pbMessage(_INTL("The save file is corrupt, or is incompatible with this game."))
          if !pbConfirmMessageSerious(_INTL("Do you want to delete the save file and start anew?"))
            $scene = nil
            return
          end
          begin; File.delete(savefile); rescue; end
          begin; File.delete(savefile+".bak"); rescue; end
          $game_system   = Game_System.new
          $PokemonSystem = PokemonSystem.new if !$PokemonSystem
          pbMessage(_INTL("The save file was deleted."))
        end
      end
      if showContinue
        if !haveBackup
          begin; File.delete(savefile+".bak"); rescue; end
        end
      end
      commands[cmdContinue = commands.length]    = _INTL("Continue") if showContinue
      commands[cmdNewGame = commands.length]     = _INTL("New Game")
      commands[cmdNGPlus = commands.length]      = _INTL("New Game +") if (trainer.newGamePlus) && (trainer.newGamePlusCount <= 5)
      commands[cmdMysteryGift = commands.length] = _INTL("Mystery Gift") if (trainer.mysterygiftaccess rescue false)
    else
      commands[cmdNewGame = commands.length]     = _INTL("New Game")
    end
    commands[cmdOption = commands.length]        = _INTL("Options")
    commands[cmdLanguage = commands.length]      = _INTL("Language") if LANGUAGES.length>=2
    commands[cmdDebug = commands.length]         = _INTL("Debug") if $DEBUG
    commands[cmdQuit = commands.length]          = _INTL("Quit Game")
    @scene.pbStartScene(commands,showContinue,trainer,framecount,mapid)
    @scene.pbSetParty(trainer) if showContinue
    @scene.pbStartScene2
    pbLoadBattleAnimations
    loop do
      command = @scene.pbChoose(commands)
      if cmdContinue>=0 && command==cmdContinue
        unless safeExists?(savefile)
          pbPlayBuzzerSE
          next
        end
        pbPlayDecisionSE
        @scene.pbEndScene
        metadata = nil
        File.open(savefile) { |f|
          Marshal.load(f)   # Trainer already loaded
          $Trainer             = trainer
          Graphics.frame_count = Marshal.load(f)
          $game_system         = Marshal.load(f)
          Marshal.load(f)   # PokemonSystem already loaded
          Marshal.load(f)   # Current map id no longer needed
          $game_switches       = Marshal.load(f)
          $game_variables      = Marshal.load(f)
          $game_self_switches  = Marshal.load(f)
          $game_screen         = Marshal.load(f)
          $MapFactory          = Marshal.load(f)
          $game_map            = $MapFactory.map
          $game_player         = Marshal.load(f)
          $PokemonGlobal       = Marshal.load(f)
          metadata             = Marshal.load(f)
          $PokemonBag          = Marshal.load(f)
          $PokemonStorage      = Marshal.load(f)
          $SaveVersion         = Marshal.load(f) unless f.eof?
          pbRefreshResizeFactor if !mkxp?  # To fix Game_Screen pictures
          magicNumberMatches = false
          if $data_system.respond_to?("magic_number")
            magicNumberMatches = ($game_system.magic_number==$data_system.magic_number)
          else
            magicNumberMatches = ($game_system.magic_number==$data_system.version_id)
          end
          if !magicNumberMatches || $PokemonGlobal.safesave
            if pbMapInterpreterRunning?
              pbMapInterpreter.setup(nil,0)
            end
            begin
              $MapFactory.setup($game_map.map_id)   # calls setMapChanged
            rescue Errno::ENOENT
              if $DEBUG
                pbMessage(_INTL("Map {1} was not found.",$game_map.map_id))
                map = pbWarpToMap
                if map
                  $MapFactory.setup(map[0])
                  $game_player.moveto(map[1],map[2])
                else
                  $game_map = nil
                  $scene = nil
                  return
                end
              else
                $game_map = nil
                $scene = nil
                pbMessage(_INTL("The map was not found. The game cannot continue."))
              end
            end
            $game_player.center($game_player.x, $game_player.y)
          else
            $MapFactory.setMapChanged($game_map.map_id)
          end
        }
        if !$game_map.events   # Map wasn't set up
          $game_map = nil
          $scene = nil
          pbMessage(_INTL("The map is corrupt. The game cannot continue."))
          return
        end
        $PokemonMap = metadata
        $PokemonEncounters = PokemonEncounters.new
        $PokemonEncounters.setup($game_map.map_id)
        pbAutoplayOnSave
        $game_map.update
        $PokemonMap.updateMap
        $scene = Scene_Map.new
        # Force Unlock Outfit if needed
        if !$game_variables[56].is_a?(Array)
          pbUnlockOutfit(1,"Quantech Uniform")  if $game_switches[62]
          pbUnlockOutfit(2,"Biogress Uniform")  if $game_switches[61]
        end
        return
      elsif cmdNewGame>=0 && command==cmdNewGame
        pbPlayDecisionSE
        @scene.pbEndScene
        if $game_map && $game_map.events
          for event in $game_map.events.values
            event.clear_starting
          end
        end
        $game_temp.common_event_id = 0 if $game_temp
        $scene               = Scene_Map.new
        Graphics.frame_count = 0
        $game_system         = Game_System.new
        $game_switches       = Game_Switches.new
        $game_variables      = Game_Variables.new
        $game_self_switches  = Game_SelfSwitches.new
        $game_screen         = Game_Screen.new
        $game_player         = Game_Player.new
        $PokemonMap          = PokemonMapMetadata.new
        $PokemonGlobal       = PokemonGlobalMetadata.new
        $PokemonStorage      = PokemonStorage.new
        $PokemonEncounters   = PokemonEncounters.new
        $PokemonTemp.begunNewGame = true
        pbRefreshResizeFactor if !mkxp?  # To fix Game_Screen pictures
        $data_system         = pbLoadRxData("Data/System")
        $MapFactory          = PokemonMapFactory.new($data_system.start_map_id)   # calls setMapChanged
        $game_player.moveto($data_system.start_x, $data_system.start_y)
        $game_player.refresh
        $game_map.autoplay
        $game_map.update
        return
      elsif cmdNGPlus >=0 && command==cmdNGPlus
        unless safeExists?(savefile)
          pbPlayBuzzerSE
          next
        end
        pbPlayDecisionSE
        @scene.pbEndScene
        metadata = nil
        File.open(savefile) { |f|
          Marshal.load(f)   # Trainer already loaded
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)   # PokemonSystem already loaded
          Marshal.load(f)   # Current map id no longer needed
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          Marshal.load(f)
          $PokemonStorage      = Marshal.load(f)
          Marshal.load(f)
        }
        @scene.pbEndScene
        if $game_map && $game_map.events
          for event in $game_map.events.values
            event.clear_starting
          end
        end
        $PokemonTemp.oldParty = trainer.party
        $PokemonTemp.oldStorage = $PokemonStorage
        $PokemonTemp.oldNewGamePlusCount = trainer.newGamePlusCount
        $PokemonTemp.oldParty.each_with_index do |pkmn,i|
          if pkmn && pkmn.isSpecies?(:ARENAY)
            $PokemonTemp.oldParty[i] = nil
          elsif pkmn
            revertToBaby(pkmn)
          end
        end
        $PokemonTemp.oldParty.compact!
        for i in 0...$PokemonTemp.oldStorage.maxBoxes
          for j in 0...$PokemonTemp.oldStorage.maxPokemon(i)
            pkmn = $PokemonTemp.oldStorage[i,j]
            if pkmn && pkmn.isSpecies?(:ARENAY)
              $PokemonTemp.oldStorage[i,j] = nil
            elsif pkmn
              revertToBaby(pkmn)
            end
          end
        end
        $game_temp.common_event_id = 0 if $game_temp
        $scene               = Scene_Map.new
        Graphics.frame_count = 0
        $game_system         = Game_System.new
        $game_switches       = Game_Switches.new
        $game_variables      = Game_Variables.new
        $game_self_switches  = Game_SelfSwitches.new
        $game_screen         = Game_Screen.new
        $game_player         = Game_Player.new
        $PokemonMap          = PokemonMapMetadata.new
        $PokemonGlobal       = PokemonGlobalMetadata.new
        $PokemonEncounters   = PokemonEncounters.new
        $PokemonStorage      = PokemonStorage.new
        $PokemonTemp.begunNewGame = true
        $PokemonTemp.begunNewGamePlus = true
        pbRefreshResizeFactor if !mkxp?  # To fix Game_Screen pictures
        $data_system         = pbLoadRxData("Data/System")
        $MapFactory          = PokemonMapFactory.new($data_system.start_map_id)   # calls setMapChanged
        $game_player.moveto($data_system.start_x, $data_system.start_y)
        $game_player.refresh
        $game_map.autoplay
        $game_map.update
        return
      elsif cmdMysteryGift>=0 && command==cmdMysteryGift
        pbPlayDecisionSE
        pbFadeOutIn {
          trainer = pbDownloadMysteryGift(trainer)
        }
      elsif cmdOption>=0 && command==cmdOption
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        }
      elsif cmdLanguage>=0 && command==cmdLanguage
        pbPlayDecisionSE
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        pbLoadMessages("Data/"+LANGUAGES[$PokemonSystem.language][1])
        savedata = []
        if safeExists?(savefile)
          File.open(savefile,"rb") { |f|
            16.times { savedata.push(Marshal.load(f)) }
          }
          savedata[3]=$PokemonSystem
          begin
            File.open(RTP.getSaveFileName("Game.rxdata"),"wb") { |f|
              16.times { |i| Marshal.dump(savedata[i],f) }
            }
          rescue
          end
        end
        $scene = pbCallTitle
        return
      elsif cmdDebug>=0 && command==cmdDebug
        pbPlayDecisionSE
        pbFadeOutIn { pbDebugMenu(false) }
      elsif cmdQuit>=0 && command==cmdQuit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      end
    end
  end
end

# Adding a few temporary variables to store New Game Plus Data
class PokemonTemp
  attr_accessor :oldParty
  attr_accessor :oldStorage
  attr_accessor :begunNewGamePlus
  attr_accessor :oldNewGamePlusCount

  def oldParty
    @oldParty = [] if !@oldParty
    return @oldParty
  end

  def oldStorage
    @oldStorage = PokemonStorage.new if !@oldStorage
    return @oldStorage
  end

  def oldNewGamePlusCount
    @oldNewGamePlusCount = 1 if !@oldNewGamePlusCount
    return @oldNewGamePlusCount
  end

  def begunNewGamePlus
    @begunNewGamePlus = false if !@begunNewGamePlus
    return @begunNewGamePlus
  end
end

# Adding a few temporary variables to store Trainer's New Game Plus Progress
class PokeBattle_Trainer
  attr_accessor :newGamePlusCount
  attr_accessor :newGamePlus

  def newGamePlus
    @newGamePlus = false if !@newGamePlus
    return @newGamePlus
  end

  def newGamePlusCount
    @newGamePlusCount = 0 if !@newGamePlusCount
    return @newGamePlusCount
  end
end

class PokeBattle_Battle

# Added Multiplied EXP
  def pbGainExpOne(idxParty,defeatedBattler,numPartic,expShare,expAll,showMessages=true)
    pkmn = pbParty(0)[idxParty]   # The Pokémon gaining EVs from defeatedBattler
    growthRate = pkmn.growthrate
    # Don't bother calculating if gainer is already at max Exp
    if pkmn.exp>=PBExperience.pbGetMaxExperience(growthRate)
      pkmn.calcStats   # To ensure new EVs still have an effect
      return
    end
    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level = defeatedBattler.level
    # Main Exp calculation
    exp = 0
    a = level*defeatedBattler.pokemon.baseExp
    if expShare.length>0 && (isPartic || hasExpShare)
      if numPartic==0   # No participants, all Exp goes to Exp Share holders
        exp = a/(SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif SPLIT_EXP_BETWEEN_GAINERS   # Gain from participating and/or Exp Share
        exp = a/(2*numPartic) if isPartic
        exp += a/(2*expShare.length) if hasExpShare
      else   # Gain from participating and/or Exp Share (Exp not split)
        exp = (isPartic) ? a : a/2
      end
    elsif isPartic   # Participated in battle, no Exp Shares held by anyone
      exp = a/(SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll   # Didn't participate in battle, gaining Exp due to Exp All
      # NOTE: Exp All works like the Exp Share from Gen 6+, not like the Exp All
      #       from Gen 1, i.e. Exp isn't split between all Pokémon gaining it.
      exp = a/2
    end
    return if exp<=0
    # Pokémon gain more Exp from trainer battles
    exp = (exp*1.5).floor if trainerBattle?
    # Scale the gained Exp based on the gainer's level (or not)
    if SCALED_EXP_FORMULA
      exp /= 5
      levelAdjust = (2*level+10.0)/(pkmn.level+level+10.0)
      levelAdjust = levelAdjust**5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
    else
      exp /= 7
    end
    # Foreign Pokémon gain more Exp
    isOutsider = (pkmn.trainerID!=pbPlayer.id ||
                 (pkmn.language!=0 && pkmn.language!=pbPlayer.language))
    if isOutsider
      if pkmn.language!=0 && pkmn.language!=pbPlayer.language
        exp = (exp*1.7).floor
      else
        exp = (exp*1.5).floor
      end
    end
    exp = (exp * NewGamePlusData.expGain).floor
    # Modify Exp gain based on pkmn's held item
    i = BattleHandlers.triggerExpGainModifierItem(pkmn.item,pkmn,exp)
    if i<0
      i = BattleHandlers.triggerExpGainModifierItem(@initialItems[0][idxParty],pkmn,exp)
    end
    exp = i if i>=0
    # Make sure Exp doesn't exceed the maximum
    expFinal = PBExperience.pbAddExperience(pkmn.exp,exp,growthRate)
    expGained = expFinal-pkmn.exp
    return if expGained<=0
    # "Exp gained" message
    if showMessages
      if isOutsider
        pbDisplayPaused(_INTL("{1} got a boosted {2} Exp. Points!",pkmn.name,expGained))
      else
        pbDisplayPaused(_INTL("{1} got {2} Exp. Points!",pkmn.name,expGained))
      end
    end
    curLevel = pkmn.level
    newLevel = PBExperience.pbGetLevelFromExperience(expFinal,growthRate)
    if newLevel<curLevel
      debugInfo = "Levels: #{curLevel}->#{newLevel} | Exp: #{pkmn.exp}->#{expFinal} | gain: #{expGained}"
      raise RuntimeError.new(
         _INTL("{1}'s new level is less than its\r\ncurrent level, which shouldn't happen.\r\n[Debug: {2}]",
         pkmn.name,debugInfo))
    end
    # Give Exp
    if pkmn.shadowPokemon?
      pkmn.exp += expGained
      return
    end
    tempExp1 = pkmn.exp
    battler = pbFindBattler(idxParty)
    loop do   # For each level gained in turn...
      # EXP Bar animation
      levelMinExp = PBExperience.pbGetStartExperience(curLevel,growthRate)
      levelMaxExp = PBExperience.pbGetStartExperience(curLevel+1,growthRate)
      tempExp2 = (levelMaxExp<expFinal) ? levelMaxExp : expFinal
      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler,levelMinExp,levelMaxExp,tempExp1,tempExp2)
      tempExp1 = tempExp2
      curLevel += 1
      if curLevel>newLevel
        # Gained all the Exp now, end the animation
        pkmn.calcStats
        battler.pbUpdate(false) if battler
        @scene.pbRefreshOne(battler.index) if battler
        break
      end
      # Levelled up
      pbCommonAnimation("LevelUp",battler) if battler
      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed
      if battler && battler.pokemon
        battler.pokemon.changeHappiness("levelup")
      end
      pkmn.calcStats
      battler.pbUpdate(false) if battler
      @scene.pbRefreshOne(battler.index) if battler
      pbDisplayPaused(_INTL("{1} grew to Lv. {2}!",pkmn.name,curLevel))
      @scene.pbLevelUp(pkmn,battler,oldTotalHP,oldAttack,oldDefense,
                                    oldSpAtk,oldSpDef,oldSpeed)
      # Learn all moves learned at this level
      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty,m[1]) if m[0]==curLevel }
    end
  end

# Added Multiplied Money Gain
  def pbGainMoney
    return if !@internalBattle || !@moneyGain
    # Money rewarded from opposing trainers
    if trainerBattle?
      tMoney = 0
      @opponent.each_with_index do |t,i|
        tMoney += pbMaxLevelInTeam(1,i)*t.moneyEarned
      end
      tMoney *= 2 if @field.effects[PBEffects::AmuletCoin]
      tMoney *= 2 if @field.effects[PBEffects::HappyHour]
      tMoney = (tMoney * NewGamePlusData.moneyGain).floor.to_i
      oldMoney = pbPlayer.money
      pbPlayer.money += tMoney
      moneyGained = pbPlayer.money-oldMoney
      if moneyGained>0
        pbDisplayPaused(_INTL("You got ${1} for winning!",moneyGained.to_s_formatted))
      end
    end
    # Pick up money scattered by Pay Day
    if @field.effects[PBEffects::PayDay]>0
      @field.effects[PBEffects::PayDay] *= 2 if @field.effects[PBEffects::AmuletCoin]
      @field.effects[PBEffects::PayDay] *= 2 if @field.effects[PBEffects::HappyHour]
      oldMoney = pbPlayer.money
      pbPlayer.money += @field.effects[PBEffects::PayDay]
      moneyGained = pbPlayer.money-oldMoney
      if moneyGained>0
        pbDisplayPaused(_INTL("You picked up ${1}!",moneyGained.to_s_formatted))
      end
    end
  end

# Added Multiplied Money Lost
  def pbLoseMoney
    return if !@internalBattle || !@moneyGain
    return if $game_switches[NO_MONEY_LOSS]
    maxLevel = pbMaxLevelInTeam(0,0)   # Player's Pokémon only, not partner's
    multiplier = [8,16,24,36,48,64,80,100,120]
    idxMultiplier = [pbPlayer.numbadges,multiplier.length-1].min
    tMoney = maxLevel*multiplier[idxMultiplier]
    tMoney = (tMoney * NewGamePlusData.moneyGain).floor.to_i
    tMoney = pbPlayer.money if tMoney>pbPlayer.money
    oldMoney = pbPlayer.money
    pbPlayer.money -= tMoney
    moneyLost = oldMoney-pbPlayer.money
    if moneyLost>0
      if trainerBattle?
        pbDisplayPaused(_INTL("You gave ${1} to the winner...",moneyLost.to_s_formatted))
      else
        pbDisplayPaused(_INTL("You panicked and dropped ${1}...",moneyLost.to_s_formatted))
      end
    end
  end
end

# Added Increase of New Game Plus level in Save Screen
class PokemonSaveScreen
  def pbSaveScreen
    ret=false
    @scene.pbStartScreen
    if pbConfirmMessage(_INTL("Would you like to save the game?"))
      if safeExists?(RTP.getSaveFileName("Game.rxdata"))
        if $PokemonTemp.begunNewGamePlus
          pbMessage(_INTL("You are now about to start a New Game Plus..."))
          pbMessage(_INTL("If you save now, the older file's adventure, including items and Pokémon, will be entirely lost."))
          if !pbConfirmMessage(
             _INTL("Would you like to save the game and start this New Game Plus?"))
            pbSEPlay("GUI save choice")
            @scene.pbEndScreen
            return false
          end
        elsif $PokemonTemp.begunNewGame
          pbMessage(_INTL("WARNING!"))
          pbMessage(_INTL("There is a different game file that is already saved."))
          pbMessage(_INTL("If you save now, the other file's adventure, including items and Pokémon, will be entirely lost."))
          if !pbConfirmMessageSerious(
             _INTL("Are you sure you want to save now and overwrite the other save file?"))
            pbSEPlay("GUI save choice")
            @scene.pbEndScreen
            return false
          end
        end
      end
      $PokemonTemp.begunNewGame=false
      if $PokemonTemp.begunNewGamePlus
        $Trainer.newGamePlusCount = ($PokemonTemp.oldNewGamePlusCount + 1)
        $PokemonTemp.begunNewGamePlus = false
        $PokemonTemp.oldNewGamePlusCount = 0
      end
      pbSEPlay("GUI save choice")
      if pbSave
        pbMessage(_INTL("\\se[]{1} saved the game.\\me[GUI save game]\\wtnp[30]",$Trainer.name))
        ret=true
      else
        pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
        ret=false
      end
    else
      pbSEPlay("GUI save choice")
    end
    @scene.pbEndScreen
    return ret
  end
end

class PokeBattle_Pokemon
  # Added Shiny Chance to New Game Plus
  def shiny?
    return @shinyflag if @shinyflag!=nil
    a = @personalID^@trainerID
    b = a&0xFFFF
    c = (a>>16)&0xFFFF
    d = b^c
    return d < NewGamePlusData.shinyChance
  end
end

# Code to Increase Levels and IVs for Wild Pokemon
Events.onWildPokemonCreate+=proc {|sender,e|
  pokemon=e[0]
  if rand(NewGamePlusData.maxIVChance) < 1
    for j in 0...6
      pokemon.iv[i] = 31
    end
  else
    value = NewGamePlusData.pkmnIVOffset
    index = 0
    value.times do
      pokemon.iv[index] += 1
      pokemon.iv[index] = 31 if pokemon.iv[index] > 31
      index += 1
      index = 0 if index==6
    end
  end
  newlevel = pokemon.level
  newlevel += NewGamePlusData.wildLevels
  newlevel = newlevel.clamp(1,PBExperience.maxLevel)
  pokemon.level = newlevel
  pokemon.calcStats
}

# Code to Increase Levels and Maximize IVs for trainer Pokemon
Events.onTrainerPartyLoad+=proc {|sender,e|
  if e[0]
    trainer=e[0][0]
    items = e[0][1]
    party = e[0][2]
    for i in 0...party.length
      pokemon = party[i]
      if rand(NewGamePlusData.maxIVChance) < 1
        for j in 0...6
          pokemon.iv[i] = 31
        end
      else
        value = NewGamePlusData.pkmnIVOffset
        index = 0
        value.times do
          pokemon.iv[index] += 1
          pokemon.iv[index] = 31 if pokemon.iv[index] > 31
          index += 1
          index = 0 if index==6
        end
      end
      randlevel = pokemon.level
      randlevel += NewGamePlusData.trainerLevels
      randlevel = randlevel.clamp(1,PBExperience.maxLevel)
      pokemon.level = randlevel
      pokemon.calcStats
    end
  end
}
