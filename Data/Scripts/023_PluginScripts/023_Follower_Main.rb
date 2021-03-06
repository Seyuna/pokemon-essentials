#===============================================================================
# Credit to Help-14, zingzags, Rayd12smitty, venom12, mej71 for the original
# scripts and sprites
#
# Overhauled by Golisopod User
#===============================================================================

#-------------------------------------------------------------------------------
# Control the following Pokemon
# Example:
#     followingMoveRoute([
#         PBMoveRoute::TurnRight,
#         PBMoveRoute::Wait,4,
#         PBMoveRoute::Jump,0,0
#     ])
# The Pokemon turns Right, waits 4 frames, and then jumps
#-------------------------------------------------------------------------------
def followingMoveRoute(commands,waitComplete=true)
  return if !$Trainer.hasArenay? || !$PokemonGlobal.followerToggled
  $PokemonTemp.dependentEvents.setMoveRoute(commands,true)
end

#-------------------------------------------------------------------------------
# Script Command to toggle Following Pokemon
#-------------------------------------------------------------------------------
def pbToggleFollowingPokemon(forced = nil,anim = true)
  return if !pbGetDependency("FollowerPkmn")
  return if !$Trainer.hasArenay?
  if !nil_or_empty?(forced)
    $PokemonGlobal.followerToggled = false if forced.downcase == "on"
    $PokemonGlobal.followerToggled = true if forced.downcase ==  "off"
  end
  if $PokemonGlobal.followerToggled
    $PokemonGlobal.followerToggled = false
    ret = Events.FollowerRefresh.trigger($Trainer.arenayIndex(true))
    $PokemonTemp.dependentEvents.remove_sprite(ret)
    pbWait(1)
  else
    $PokemonGlobal.followerToggled = true
    $PokemonTemp.dependentEvents.come_back(anim)
    pbWait(1)
  end
end

#-------------------------------------------------------------------------------
# Script Command to start Pokemon Following. x is the Event ID that will be the follower
#-------------------------------------------------------------------------------
def pbPokemonFollow(x)
  return false if !$Trainer.hasArenay?
  $PokemonTemp.dependentEvents.removeEventByName("FollowerPkmn") if pbGetDependency("FollowerPkmn")
  pbAddDependency2(x,"FollowerPkmn",Follower_Common_Event)
  $PokemonGlobal.followerToggled = true
  event = pbGetDependency("FollowerPkmn")
  $PokemonTemp.dependentEvents.pbFollowEventAcrossMaps($game_player,event,true,false)
  $PokemonTemp.dependentEvents.come_back(true)
  if ALWAYS_ANIMATE
    $PokemonTemp.dependentEvents.update_stepping
  elsif $PokemonTemp.dependentEvents.refresh_sprite(false) == -1
    $PokemonTemp.dependentEvents.stop_stepping
  elsif !$PokemonTemp.dependentEvents.refresh_sprite(false)
    $PokemonTemp.dependentEvents.stop_stepping
  end
end

#-------------------------------------------------------------------------------
# Script Command to start Arenay Following. x is the Event ID that will be the follower
#-------------------------------------------------------------------------------
def pbArenayFollow(x)
  return false if !$Trainer.hasArenay?
  $PokemonTemp.dependentEvents.removeEventByName("FollowerPkmn") if pbGetDependency("FollowerPkmn")
  pbAddDependency2(x,"FollowerPkmn",Follower_Common_Event)
  $PokemonGlobal.followerToggled = true
  firstPkmn = $Trainer.arenayIndex(true)
  $PokemonTemp.dependentEvents.change_sprite([firstPkmn.species, firstPkmn.female?,
        firstPkmn.shiny?, firstPkmn.form,
        firstPkmn.shadowPokemon?])
  if ALWAYS_ANIMATE
    $PokemonTemp.dependentEvents.update_stepping
  elsif $PokemonTemp.dependentEvents.refresh_sprite(false) == -1
    $PokemonTemp.dependentEvents.stop_stepping
  elsif !$PokemonTemp.dependentEvents.refresh_sprite(false)
    $PokemonTemp.dependentEvents.stop_stepping
  end
end

#-------------------------------------------------------------------------------
# Script Command for Talking to Following Pokemon
#-------------------------------------------------------------------------------
def pbTalkToFollower
  return false if !$PokemonTemp.dependentEvents.refresh_sprite(false, true)
  if !($PokemonGlobal.surfing || pbGetMetadata($game_map.map_id,MetadataBicycleAlways) ||
     !PBTerrain.isSurfable?(pbFacingTerrainTag) ||
    !$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player))
    pbSurf
    return false
  end
  firstPkmn = $Trainer.arenayIndex(true)
  pbPlayCry(firstPkmn)
  event = pbGetDependency("FollowerPkmn")
  randomVal = rand(6)
  Events.OnTalkToFollower.trigger(firstPkmn,event.x,event.y-1,randomVal)
  pbTurnTowardEvent(event,$game_player)
end

#-------------------------------------------------------------------------------
# Script Command for removing every dependent event except Following Pokemon
#-------------------------------------------------------------------------------
def pbRemoveDependenciesExceptFollower
  events = $PokemonGlobal.dependentEvents
  for i in 0...events.length
    if events[i] && events[i][8] != "FollowerPkmn"
      events[i] = nil
      @realEvents[i] = nil
      @lastUpdate += 1
    end
    events.compact!
    $PokemonTemp.dependentEvents.realEvents.compact!
  end
end

#-------------------------------------------------------------------------------
# Script Command for  Pokémon finding an item in the field
#-------------------------------------------------------------------------------
def pbPokemonFound(item,quantity = 1,message = "")
  return false if !$PokemonGlobal.followerHoldItem
  pokename = $Trainer.arenayIndex(true).name
  message = "{1} seems to be holding something..." if nil_or_empty?(message)
  pbMessage(_INTL(message,pokename))
  item = getID(PBItems,item)
  if !item || item <= 0 || quantity<1
    item = getID(PBItems,:SITRUSBERRY)
    quantity = 1
  end
  itemname = (quantity>1) ? PBItems.getNamePlural(item) : PBItems.getName(item)
  pocket = pbGetPocket(item)
  if $PokemonBag.pbStoreItem(item,quantity)   # If item can be picked up
    scene = $game_player.addFoundItem(item)
    meName = (pbIsKeyItem?(item)) ? "Key item get" : "Item get"
    if isConst?(item, PBItems, :LEFTOVERS) || pbGetPocket(item) == 6
      pbMessage(_INTL("\\me[{1}]#{pokename} found  some "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
    elsif pbIsMachine?(item) # TM or HM
      pbMessage(_INTL("\\me[{1}]#{pokename} found "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2} {3}!\\wtnp[30]", meName, itemname,  PBMoves.getName(pbGetMachine(item))))
    elsif quantity > 1
      pbMessage(_INTL("\\me[{1}]#{pokename} found {2} "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{3}!\\wtnp[30]", meName, quantity ,itemname))
    elsif ["a", "e", "i", "o", "u"].include?(itemname[0, 1].downcase)
      pbMessage(_INTL("\\me[{1}]#{pokename} found an "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
    else
      pbMessage(_INTL("\\me[{1}]#{pokename} found a "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
    end
    pbMessage(_INTL("You put the {1} away in \\nthe <icon=bagPocket{2}>\\c[1]{3} Pocket\\c[0].",
       itemname,pocket,PokemonBag.pocketNames()[pocket]))
    scene.pbEndScene
    $PokemonGlobal.followerHoldItem = false
    $PokemonGlobal.timeTaken = 0
    return true
  end
  # Can't add the item
  if isConst?(item,PBItems,:LEFTOVERS)
    pbMessage(_INTL("#{pokename} found some \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  elsif pbIsMachine?(item)   # TM or HM
    pbMessage(_INTL("#{pokename} found \\c[1]{1} {2}\\c[0]!\\wtnp[30]",itemname,PBMoves.getName(pbGetMachine(item))))
  elsif quantity>1
    pbMessage(_INTL("#{pokename} found {1} \\c[1]{2}\\c[0]!\\wtnp[30]",quantity,itemname))
  elsif itemname.starts_with_vowel?
    pbMessage(_INTL("#{pokename} found an \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  else
    pbMessage(_INTL("#{pokename} found a \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  end
  pbMessage(_INTL("But your Bag is full..."))
  return false
end


#-------------------------------------------------------------------------------
# Main edits to dependent events for followers to function
#-------------------------------------------------------------------------------
class DependentEvents
  attr_accessor :realEvents
#-------------------------------------------------------------------------------
# Raises The Current Pokemon's Happiness level +1 per each time
# 5000 frames (2 min 5s) have passed
# followerHoldItem is the variable which decides when you are able
# to talk to your pokemon to recieve an item. It becomes true after 15000 frames
# (6mins and 15s) have passed
#-------------------------------------------------------------------------------
  def add_following_time
    $PokemonGlobal.timeTaken += 1
    $Trainer.arenayIndex(true).happiness += 1 if ($PokemonGlobal.timeTaken % 5000) == 0
    $PokemonGlobal.followerHoldItem = true if ($PokemonGlobal.timeTaken > 15000)
  end

# Updates the sprite sprite with an animation
  def refresh_sprite(anim = true,check = false)
    return false if !pbGetDependency("FollowerPkmn")
    return false if !$PokemonGlobal.followerToggled
    firstPkmn = $Trainer.arenayIndex(true)
    return false if !firstPkmn
    refresh = Events.FollowerRefresh.trigger(firstPkmn)
    refresh = true if refresh == -1 && check
    if refresh
      if anim
        events=$PokemonGlobal.dependentEvents
        for i in 0...events.length
          $scene.spriteset.addUserAnimation(Animation_Come_Out,@realEvents[i].x,@realEvents[i].y)
           pbWait(10)
        end
      else
        $PokemonTemp.dependentEvents.update_stepping if !check
      end
    end
    return refresh
  end

# Change the sprite to the correct species and data
  def change_sprite(params)
    factors = []
    factors.push([4,params[4],false]) if params[4] && params[4]!=false   # shadow
    factors.push([1,params[1],false]) if params[1] && params[1]!=false  # gender
    factors.push([2,params[2],false]) if params[2] && params[2]!=false   # shiny
    factors.push([3,params[3],0]) if params[3] && params[3]!=0           # form
    factors.push([0,params[0],0])                                        # species
    trySpecies = 0
    tryGender = false
    tryShiny  = false
    tryForm   = 0
    tryShadow = false
    for i in 0...2**factors.length
      factors.each_with_index do |factor,index|
        newVal = ((i/(2**index))%2==0) ? factor[1] : factor[2]
        case factor[0]
        when 0; trySpecies = newVal
        when 1; tryGender  = newVal
        when 2; tryShiny   = newVal
        when 3; tryForm    = newVal
        when 4; tryShadow  = newVal
        end
      end
      ret = [-1,""]
      for j in 0...2   # Try using the species' internal name and then its ID number
        next if trySpecies==0 && j==0
        trySpeciesText = (j==0) ? getConstantName(PBSpecies,trySpecies) : sprintf("%03d",trySpecies)
        bitmapFileName = sprintf("%s%s%s%s%s",
           trySpeciesText,
           (tryGender) ? "f" : "",
           (tryShiny) ? "s" : "",
           (tryForm!=0) ? "_"+tryForm.to_s : "",
           (tryShadow) ? "_shadow" : "") rescue nil
        ret = [0,bitmapFileName] if pbResolveBitmap("Graphics/Characters/"+bitmapFileName)
        ret = [1,bitmapFileName] if pbResolveBitmap("Graphics/Characters/Following/"+bitmapFileName)
      end
      if ret[0] > -1
        events = $PokemonGlobal.dependentEvents
        for k in 0...events.length
          if events[k] && events[k][8]=="FollowerPkmn"
            events[k][6] = ((ret[0] == 1)? "Following/" : "") + ret[1]
            @realEvents[k].character_name = ((ret[0] == 1)? "Following/" : "") + ret[1]
          end
          if defined?(pbShouldGetShadow?) && $scene.is_a?(Scene_Map) && $scene.spriteset
            $scene.spriteset.usersprites.select do |e|
              e.is_a?(DependentEventSprites)
            end.each do |des|
              des.sprites.each do |e|
                e.make_shadow if e.respond_to?(:make_shadow)
              end
            end
          end
          return
        end
      end
    end
  end

# Adds step animation for followers and update their speed
  def update_stepping
    if PBTerrain.isIce?(pbGetTerrainTag)
      followingMoveRoute([PBMoveRoute::StepAnimeOff])
      return
    end
    events = $PokemonGlobal.dependentEvents
    for i in 0...events.length
      @realEvents[i].move_speed = $game_player.move_speed
    end
    followingMoveRoute([PBMoveRoute::StepAnimeOn])
  end

# Stop the Stepping animation
  def stop_stepping
    followingMoveRoute([PBMoveRoute::StepAnimeOff])
  end

# Removes the sprite of the follower. DOESN'T DISABLE IT
  def remove_sprite(anim=nil)
    events=$PokemonGlobal.dependentEvents
    for i in 0...events.length
      if events[i] && events[i][8]== "FollowerPkmn"
        events[i][6]=sprintf("nil")
        @realEvents[i].character_name = sprintf("nil")
        if anim
          $scene.spriteset.addUserAnimation(Animation_Come_In,@realEvents[i].x,@realEvents[i].y)
          pbWait(10)
        end
        if defined?(pbShouldGetShadow?) && $scene.is_a?(Scene_Map) && $scene.spriteset
          $scene.spriteset.usersprites.select do |e|
            e.is_a?(DependentEventSprites)
          end.each do |des|
            des.sprites.each do |e|
              if e && e.shadow
                e.shadow.dispose
                e.shadow = nil
              end
            end
          end
        end
        $PokemonGlobal.timeTaken = 0
      end
    end
  end

# Command to update follower/ make it reappear
  def come_back(anim=nil)
    return if !$PokemonGlobal.followerToggled
    firstPkmn = $Trainer.arenayIndex(true)
    remove_sprite(false)
    return if !firstPkmn
    ret = refresh_sprite(anim)
    change_sprite([firstPkmn.species, firstPkmn.female?,
          firstPkmn.shiny?, firstPkmn.form,
          firstPkmn.shadowPokemon?]) if ret
    return ret
  end

# Command to update follower/ make it reappear
  def setMoveRoute(commands,waitComplete=true)
    events=$PokemonGlobal.dependentEvents
    for i in 0...events.length
      if events[i] && events[i][8]== "FollowerPkmn"
        pbMoveRoute(@realEvents[i],commands,true)
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Various edits to old functions to incorporate updating of Following Pokemon
#-------------------------------------------------------------------------------

# Update before surfing, also incorporate hiddden move animation
alias follow_surf pbSurf

def pbSurf
  return false if $game_player.pbFacingEvent
  return false if $game_player.pbHasDependentEvents?
  if $PokemonTemp.dependentEvents.refresh_sprite(false,true)
    pkmn = $Trainer.arenayIndex(true)
    if pkmn && pkmn.hasType?(:ROCK) || pkmn.hasType?(:GROUND) || pkmn.hasType?(:FIRE) || pkmn.hasType?(:ELECTRIC)
      pbMessage(_INTL("\\PN can't surf with {1} in its {2} form!",pkmn.name,PBTypes.getName(pkmn.type1)))
      return false
    end
  end
  if !$PokemonBag.pbHasItem?(:SURFITEM) && !$DEBUG
    return false
  end
  if pbConfirmMessage(_INTL("The water is a deep blue...\nWould you like to surf on it?"))
    pbMessage(_INTL("{1} used the {2}!", $Trainer.name, PBItems.getName(getConst(PBItems,SURF_ITEM))))
    pbCancelVehicles
    surfbgm = pbGetMetadata(0,MetadataSurfBGM)
    pbCueBGM(surfbgm,0.5) if surfbgm
    pbStartSurfing
    $PokemonTemp.dependentEvents.come_back(false)
    return true
  end
  return false
end

# Update after surfing
alias follow_pbEndSurf pbEndSurf
def pbEndSurf(xOffset,yOffset)
  ret = follow_pbEndSurf(xOffset,yOffset)
  if ret
    pkmn = $Trainer.arenayIndex(true)
    $PokemonGlobal.callRefresh = [true,false]
  end
end

# Update follower when mounting Bike
alias follow_pbDismountBike pbDismountBike
def pbDismountBike
  return if !$PokemonGlobal.bicycle
  ret=follow_pbDismountBike
  $PokemonTemp.dependentEvents.come_back(true)
  return ret
end

# Update follower when dismounting Bike
alias follow_pbMountBike pbMountBike
def pbMountBike
  ret=follow_pbMountBike
  $PokemonTemp.dependentEvents.come_back(!(pbGetMetadata($game_map.map_id,MetadataBicycleAlways)))
  return ret
end

# Update follower when any vehicle like Surf, Lava Surf etc are done
alias follow_pbCancelVehicles pbCancelVehicles
def pbCancelVehicles(destination=nil)
  $PokemonTemp.dependentEvents.come_back(false) if destination.nil?
  return follow_pbCancelVehicles(destination)
end

# Update follower after accessing TrainerPC
alias follow_pbTrainerPC pbTrainerPC
def pbTrainerPC
  follow_pbTrainerPC
  $PokemonTemp.dependentEvents.come_back(false)
end

# Update follower after accessing Poke Centre PC
alias follow_pbPokeCenterPC pbPokeCenterPC
def pbPokeCenterPC
  follow_pbPokeCenterPC
  $PokemonTemp.dependentEvents.come_back(false)
end


# Update follower after accessing Party Screen
class PokemonPartyScreen
  alias follow_pbEndScene pbEndScene
  def pbEndScene
    ret = follow_pbEndScene
    $PokemonTemp.dependentEvents.come_back(false)
    return ret
  end

  alias follow_pbPokemonScreen pbPokemonScreen
  def pbPokemonScreen
    ret = follow_pbPokemonScreen
    $PokemonTemp.dependentEvents.come_back(false)
    return ret
  end

  alias follow_pbSwitch pbSwitch
  def pbSwitch(oldid,newid)
    follow_pbSwitch(oldid,newid)
    $PokemonTemp.dependentEvents.come_back(false)
  end

  alias follow_pbRefresh pbRefresh
  def pbRefresh
    follow_pbRefresh
    $PokemonTemp.dependentEvents.come_back(false)
  end

  alias follow_pbRefreshSingle pbRefreshSingle
  def pbRefreshSingle(pkmnid)
    follow_pbRefreshSingle(pkmnid)
    $PokemonTemp.dependentEvents.come_back(false)
  end
end

# Update follower after any kind of Evolution
class PokemonEvolutionScene
  alias follow_pbEndScreen pbEndScreen
  def pbEndScreen
    follow_pbEndScreen
    $PokemonTemp.dependentEvents.come_back(false)
  end
end

class PokemonTrade_Scene
  alias follow_pbEndScreen pbEndScreen
  def pbEndScreen
    follow_pbEndScreen
    $PokemonTemp.dependentEvents.come_back(false)
  end
end

# Update follower after usage of Bag
class PokemonBagScreen
  alias follow_bagScene pbStartScreen
  def pbStartScreen
    ret = follow_bagScene
    $PokemonTemp.dependentEvents.come_back(false)
    return ret
  end
end

# Update follower after any Battle
class PokeBattle_Scene
  alias follow_pbEndBattle pbEndBattle
  def pbEndBattle(result)
    follow_pbEndBattle(result)
    $PokemonGlobal.callRefresh = [true,false]
  end
end

# Tiny fix for emote Animations not playing in v18
class SpriteAnimation
  def effect?
    return @_animation_duration > 0 if @_animation_duration
  end
end

#Fix for followers having animations (grass, etc) when toggled off
#Treats followers as if they are under a bridge when toggled
alias follow_pbGetTerrainTag pbGetTerrainTag
def pbGetTerrainTag(event=nil,countBridge=false)
  ret = follow_pbGetTerrainTag(event,countBridge)
  if event && event!=$game_player
    for devent in $PokemonGlobal.dependentEvents
      if event.id==devent[1] && !($PokemonGlobal.followerToggled &&
                                  $Trainer.hasArenay?)
        ret = PBTerrain::Bridge
        break
      end
    end
  end
  return ret
end


# Add a check for dependent events in the passablity method
#class Game_Map
#  alias follow_passable? passable?
#  def passable?(x, y, d, self_event=nil)
#    ret = follow_passable?(x,y,d,self_event)
#    if !$game_temp.player_transferring && pbGetDependency("FollowerPkmn") && self_event != $game_player
#      dependent=pbGetDependency("FollowerPkmn")
#      return false if self_event != dependent && dependent.x==x && dependent.y==y
#    end
#    return ret
#  end
#end

#===============================================================================
# Shows Arenay being sent out on the player's side (including by a partner).
#===============================================================================
class FollowerPlayerSendOutAnimation < PokeBattle_Animation

  def initialize(sprites,viewport,idxTrainer,battler,startBattle,idxOrder=0)
    @idxTrainer     = idxTrainer
    @battler        = battler
    @showingTrainer = startBattle
    @idxOrder       = idxOrder
    @trainer        = @battler.battle.pbGetOwnerFromBattlerIndex(@battler.index)
    @shadowVisible = sprites["shadow_#{battler.index}"].visible
    super(sprites,viewport)
  end

  def createProcesses
    delay = 0
    delay = 5 if @showingTrainer
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    traSprite = @sprites["player_#{@idxTrainer}"]
    # Calculate the Poké Ball graphic to use
    battlerStartX = (batSprite.x/8)*-3
    battlerEndX = batSprite.x
    battlerY = batSprite.y
    battler = addSprite(batSprite,PictureOrigin::Bottom)
    battler.setVisible(delay,true)
    battler.setZoomXY(delay,100,100)
    battler.setColor(delay,Color.new(0,0,0,0))
    battler.setXY(delay,battlerStartX,battlerY)
    battler.moveXY(delay,10,battlerEndX,battlerY)
    battler.setCallback(delay+10,[batSprite,:pbPlayIntroAnimation])
    if @shadowVisible
      # Set up shadow sprite
      shadowStartX=(shaSprite.x/8)*-2
      shadowEndX=shaSprite.x
      shadowY=shaSprite.y
      shadow = addSprite(shaSprite,PictureOrigin::Center)
      # Shadow animation
      shadow.setVisible(delay,@shadowVisible)
      shadow.setXY(delay,shadowStartX,shadowY)
      shadow.moveXY(delay,10,shadowEndX,shadowY)
    end
  end
end

#===============================================================================
# Shows Arenay being recalled on the player's side (including by a partner).
#===============================================================================
class FollowerRecallAnimation < PokeBattle_Animation

  def initialize(sprites,viewport,idxBattler)
    @idxBattler     = idxBattler
    super(sprites,viewport)
  end

  def createProcesses
    batSprite = @sprites["pokemon_#{@idxBattler}"]
    shaSprite = @sprites["shadow_#{@idxBattler}"]
    # Calculate the Poké Ball graphic to use
    battlerStartX = batSprite.x
    battlerEndX = (batSprite.x/8)*-3
    battlerY = batSprite.y
    battler = addSprite(batSprite,PictureOrigin::Bottom)
    battler.setXY(0,battlerStartX,battlerY)
    battler.moveXY(0,10,battlerEndX,battlerY)
    battler.setCallback(10,[batSprite,:pbPlayIntroAnimation])
    battler.setVisible(10,false)
  end
end

def pbStartOver(gameover=false)
  if pbInBugContest?
    pbBugContestStartOver
    return
  end
  pbHealAll
  if $PokemonGlobal.pokecenterMapId && $PokemonGlobal.pokecenterMapId>=0
    if gameover
      pbMessage(_INTL("\\w[""]\\wm\\l[3]After the unfortunate defeat, you scurry back to a Pokémon Center."))
    else
      pbMessage(_INTL("\\w[""]\\wm\\l[3]You scurry back to a Pokémon Center, protecting your exhausted Pokémon from any further harm..."))
    end
    pbCancelVehicles
    pbRemoveDependenciesExceptFollower
    $game_switches[STARTING_OVER_SWITCH] = true
    $game_temp.player_new_map_id    = $PokemonGlobal.pokecenterMapId
    $game_temp.player_new_x         = $PokemonGlobal.pokecenterX
    $game_temp.player_new_y         = $PokemonGlobal.pokecenterY
    $game_temp.player_new_direction = $PokemonGlobal.pokecenterDirection
    $scene.transfer_player if $scene.is_a?(Scene_Map)
    $game_map.refresh
  else
    homedata = pbGetMetadata(0,MetadataHome)
    if homedata && !pbRxdataExists?(sprintf("Data/Map%03d",homedata[0]))
      if $DEBUG
        pbMessage(_ISPRINTF("Can't find the map 'Map{1:03d}' in the Data folder. The game will resume at the player's position.",homedata[0]))
      end
      pbHealAll
      return
    end
    if gameover
      pbMessage(_INTL("\\w[""]\\wm\\l[3]After the unfortunate defeat, you scurry back home."))
    else
      pbMessage(_INTL("\\w[""]\\wm\\l[3]You scurry back home, protecting your exhausted Pokémon from any further harm..."))
    end
    if homedata
      pbCancelVehicles
      pbRemoveDependenciesExceptFollower
      $game_switches[STARTING_OVER_SWITCH] = true
      $game_temp.player_new_map_id    = homedata[0]
      $game_temp.player_new_x         = homedata[1]
      $game_temp.player_new_y         = homedata[2]
      $game_temp.player_new_direction = homedata[3]
      $scene.transfer_player if $scene.is_a?(Scene_Map)
      $game_map.refresh
    else
      pbHealAll
    end
  end
  pbEraseEscapePoint
end

class Game_Character
  def jump_speed_real
    return (2 ** (3 + 1)) * 0.8 * 40.0 / Graphics.frame_rate   # Walking speed
    self.jump_speed_real = (2 ** (3 + 1)) * 0.8 if !@jump_speed_real   # 3 is walking speed
    return @jump_speed_real
  end

  def jump_speed_real=(val)
    @jump_speed_real = val * 40.0 / Graphics.frame_rate
  end

  def jump(x_plus, y_plus)
    if x_plus != 0 or y_plus != 0
      if x_plus.abs > y_plus.abs
        (x_plus < 0) ? turn_left : turn_right
      else
        (y_plus < 0) ? turn_up : turn_down
      end
    end
    new_x = @x + x_plus
    new_y = @y + y_plus
    if (x_plus == 0 and y_plus == 0) || passable?(new_x, new_y, 0)
      @x = new_x
      @y = new_y
      real_distance = Math::sqrt(x_plus * x_plus + y_plus * y_plus)
      distance = [1, real_distance].max
      @jump_peak = distance * Game_Map::TILE_HEIGHT * 3 / 8   # 3/4 of tile for ledge jumping
      @jump_distance = [x_plus.abs * Game_Map::REAL_RES_X, y_plus.abs * Game_Map::REAL_RES_Y].max
      @jump_distance_left = 1   # Just needs to be non-zero
      if real_distance > 0   # Jumping to somewhere else
        @jump_count = 0
      else   # Jumping on the spot
        @jump_speed_real = nil   # Reset jump speed
        @jump_count = Game_Map::REAL_RES_X / jump_speed_real   # Number of frames to jump one tile
      end
      @stop_count = 0
      if self.is_a?(Game_Player)
        $PokemonTemp.dependentEvents.pbMoveDependentEvents
      end
      triggerLeaveTile
    end
  end
end

# Same map only
def jumpFancy(follower,direction,leader)
  deltaX=(direction == 6 ? 2 : (direction == 4 ? -2 : 0))
  deltaY=(direction == 2 ? 2 : (direction == 8 ? -2 : 0))
  halfDeltaX=(direction == 6 ? 1 : (direction == 4 ? -1 : 0))
  halfDeltaY=(direction == 2 ? 1 : (direction == 8 ? -1 : 0))
  middle=pbTestPass(follower,follower.x+halfDeltaX,follower.y+halfDeltaY,0)
  ending=pbTestPass(follower,follower.x+deltaX,    follower.y+deltaY,    0)
  if middle
    moveFancy(follower,direction)
    moveFancy(follower,direction)
  elsif ending
    if pbTestPass(follower,follower.x,follower.y,0)
      if leader.jumping?
        follower.jump_speed_real = leader.jump_speed_real * Graphics.frame_rate / 40.0
      else
        follower.jump_speed_real = leader.move_speed_real * Graphics.frame_rate / 20.0
      end
      follower.jump(deltaX,deltaY)
    else
      moveThrough(follower,direction)
      moveThrough(follower,direction)
    end
  end
end

def pbFancyMoveTo(follower,newX,newY,leader)
  if follower.x-newX==-1 && follower.y==newY
    moveFancy(follower,6)
  elsif follower.x-newX==1 && follower.y==newY
    moveFancy(follower,4)
  elsif follower.y-newY==-1 && follower.x==newX
    moveFancy(follower,2)
  elsif follower.y-newY==1 && follower.x==newX
    moveFancy(follower,8)
  elsif follower.x-newX==-2 && follower.y==newY
    jumpFancy(follower,6,leader)
  elsif follower.x-newX==2 && follower.y==newY
    jumpFancy(follower,4,leader)
  elsif follower.y-newY==-2 && follower.x==newX
    jumpFancy(follower,2,leader)
  elsif follower.y-newY==2 && follower.x==newX
    jumpFancy(follower,8,leader)
  elsif follower.x!=newX || follower.y!=newY
    follower.moveto(newX,newY)
  end
end

#-------------------------------------------------------------------------------
# Various updates to Player class to incorporate Followers
#-------------------------------------------------------------------------------
class Game_Player < Game_Character

# Edit the dependent event check to account for followers
  def pbHasDependentEvents?
    return false if pbGetDependency("FollowerPkmn")
    return $PokemonGlobal.dependentEvents.length>0
  end

#Update follower's timeTaken
  alias follow_update update
  def update
    follow_update
    $PokemonTemp.dependentEvents.add_following_time if $PokemonTemp.dependentEvents.refresh_sprite(false,true)
  end

# Always update follower if the player is moving
  alias follow_moveto moveto
  def moveto(x,y)
    ret = follow_moveto(x,y)
    events=$PokemonGlobal.dependentEvents
    leader=$game_player
    for i in 0...events.length
      event=$PokemonTemp.dependentEvents.realEvents[i]
      $PokemonTemp.dependentEvents.pbFollowEventAcrossMaps(leader,event,true,i==0)
    end
    return ret
  end
end

#-------------------------------------------------------------------------------
# Various updates to Character Sprites to incorporate Reflection and Shadow stuff
#-------------------------------------------------------------------------------

# New method to add reflection to followers
class Sprite_Character
  def setReflection(event, viewport)
    @reflection = Sprite_Reflection.new(self,event,viewport) if !@reflection
  end

  attr_accessor :shadow
  attr_accessor :steps
  attr_reader :follower

# Change the initialize method to add Shadow and Footprints
if defined?(pbShouldGetShadow?)
  alias follow_init ow_shadow_init
end

if defined?(footsteps_initialize)
  alias follow_inito footsteps_initialize
end

if !(defined?(pbShouldGetShadow?) && defined?(footsteps_initialize))
  alias follow_init initialize
end

  def initialize(viewport, character = nil, is_follower = false)
    @viewport = viewport
    @is_follower = is_follower
    follow_init(@viewport, character)
    if defined?(EVENTNAME_MAY_NOT_INCLUDE)
      @steps = []
      if $PokemonTemp && $PokemonTemp.respond_to?(:dependentEvents) &&
        $PokemonTemp.dependentEvents && $PokemonTemp.dependentEvents.respond_to?(:realEvents) &&
        $PokemonTemp.dependentEvents.realEvents.is_a?(Array) &&
        $PokemonTemp.dependentEvents.realEvents.include?(@character)
       @follower = true
      end
    end
    if defined?(pbShouldGetShadow?)
      return unless pbShouldGetShadow?(character)
      return if @is_follower && !$PokemonTemp.dependentEvents.refresh_sprite(false,true)
      @character = character
      if @character.is_a?(Game_Event)
        page = pbGetActiveEventPage(@character)
        return if !page || !page.graphic || page.graphic.character_name == ""
      end
      make_shadow
    end
  end

# Change the update method to add Shadow and Footprints
if defined?(ow_shadow_update)
  alias follow_update ow_shadow_update
end

if defined?(footsteps_update)
  alias follow_update footsteps_update
end

if !(defined?(ow_shadow_update) && defined?(footsteps_update))
  alias follow_update update
end

  def update
    follow_update
    if defined?(pbShouldGetShadow?)
      position_shadow
      if @shadow && !@character.jumping?
        @shadow.zoom_x = 1.0
        @shadow.zoom_y = 1.0
      end
      if @character.is_a?(Game_Event)
        page = pbGetActiveEventPage(@character)
        if page && page.graphic && page.graphic.character_name != "" &&
            pbShouldGetShadow?(@character)
          make_shadow
        end
      end
      bushdepth = @character.bush_depth
      if @shadow
        @shadow.opacity = self.opacity
        @shadow.visible = (bushdepth == 0)
        if !self.visible || (@is_follower || @character == $game_player) &&
          ($PokemonGlobal.surfing || $PokemonGlobal.diving)
         @shadow.visible = false
        end
      end
    end
    if defined?(EVENTNAME_MAY_NOT_INCLUDE)
      @old_x ||= @character.x
      @old_y ||= @character.y
      if (@character.x != @old_x || @character.y != @old_y) && !["", "nil"].include?(@character.character_name)
        if @character == $game_player && $PokemonTemp.dependentEvents &&
           $PokemonTemp.dependentEvents.respond_to?(:realEvents) &&
           $PokemonTemp.dependentEvents.realEvents.select { |e| !["", "nil"].include?(e.character_name) }.size > 0 &&
           !DUPLICATE_FOOTSTEPS_WITH_FOLLOWER
          if !EVENTNAME_MAY_NOT_INCLUDE.include?($PokemonTemp.dependentEvents.realEvents[0].name) &&
             !FILENAME_MAY_NOT_INCLUDE.include?($PokemonTemp.dependentEvents.realEvents[0].character_name)
            make_steps = false
          else
            make_steps = true
          end
        elsif @character.respond_to?(:name) && !(EVENTNAME_MAY_NOT_INCLUDE.include?(@character.name) &&
               FILENAME_MAY_NOT_INCLUDE.include?(@character.character_name))
          tilesetid = @character.map.instance_eval { @map.tileset_id }
          make_steps = [2,1,0].any? do |e|
            tile_id = @character.map.data[@old_x, @old_y, e]
            next false if tile_id.nil?
            next $data_tilesets[tilesetid].terrain_tags[tile_id] == PBTerrain::Sand
          end
        end
        if make_steps
          fstep = Sprite.new(self.viewport)
          fstep.z = 0
          dirs = [nil,"DownLeft","Down","DownRight","Left","Still","Right","UpLeft",
              "Up", "UpRight"]
          if @character == $game_player && $PokemonGlobal.bicycle
            fstep.bmp("Graphics/Characters/Footprints/steps#{dirs[@character.direction]}Bike")
          else
            fstep.bmp("Graphics/Characters/Footprints/steps#{dirs[@character.direction]}")
          end
          @steps ||= []
          if @character == $game_player && $PokemonGlobal.bicycle
            x = BIKE_X_OFFSET
            y = BIKE_Y_OFFSET
          else
            x = WALK_X_OFFSET
            y = WALK_Y_OFFSET
          end
          @steps << [fstep, @character.map, @old_x + x / Game_Map::TILE_WIDTH.to_f, @old_y + y / Game_Map::TILE_HEIGHT.to_f]
        end
      end
      @old_x = @character.x
      @old_y = @character.y
      update_footsteps
    end
  end
end

#-------------------------------------------------------------------------------
# Various updates to DependentEventSprites Sprites to incorporate Reflection and Shadow stuff
#-------------------------------------------------------------------------------
class DependentEventSprites

  attr_accessor :sprites
# Change the refresh method to add Shadow and Footprints
  def refresh
    for sprite in @sprites
      sprite.dispose
    end
    @sprites.clear
    $PokemonTemp.dependentEvents.eachEvent {|event,data|
      if data[2]==@map.map_id # Check current map
        spr = Sprite_Character.new(@viewport,event)
        spr.setReflection(event, @viewport)
        if $PokemonTemp.dependentEvents.refresh_sprite(false,true)
          spr.make_shadow if defined?(pbShouldGetShadow?)
          if defined?(EVENTNAME_MAY_NOT_INCLUDE) && spr.follower
            spr.steps = $FollowerSteps
            $FollowerSteps = nil
          end
        end
        @sprites.push(spr)
      end
    }
  end

# Change the update method to incorporate status tones and updating the follower
  def update
    if $PokemonTemp.dependentEvents.lastUpdate!=@lastUpdate
      refresh
      @lastUpdate=$PokemonTemp.dependentEvents.lastUpdate
    end
    for sprite in @sprites
      sprite.update
    end
    for i in 0...@sprites.length
      pbDayNightTint(@sprites[i])
      firstPkmn = $Trainer.arenayIndex(true)
      if $PokemonGlobal.followerToggled && APPLYSTATUSTONES && firstPkmn
        if MultipleForms.hasFunction?(firstPkmn,"getForm")
          $PokemonTemp.dependentEvents.come_back(false)
        end
        case firstPkmn.status
        when PBStatuses::BURN
          @sprites[i].tone.set(@sprites[i].tone.red+BURNTONE[0],@sprites[i].tone.green+BURNTONE[1],@sprites[i].tone.blue+BURNTONE[2],@sprites[i].tone.gray+BURNTONE[3])
        when PBStatuses::POISON
          @sprites[i].tone.set(@sprites[i].tone.red+POISONTONE[0],@sprites[i].tone.green+POISONTONE[1],@sprites[i].tone.blue+POISONTONE[2],@sprites[i].tone.gray+POISONTONE[3])
        when PBStatuses::PARALYSIS
          @sprites[i].tone.set(@sprites[i].tone.red+PARALYSISTONE[0],@sprites[i].tone.green+PARALYSISTONE[1],@sprites[i].tone.blue+PARALYSISTONE[2],@sprites[i].tone.gray+PARALYSISTONE[3])
        when PBStatuses::FROZEN
          @sprites[i].tone.set(@sprites[i].tone.red+FREEZETONE[0],@sprites[i].tone.green+FREEZETONE[1],@sprites[i].tone.blue+FREEZETONE[2],@sprites[i].tone.gray+FREEZETONE[3])
        when PBStatuses::SLEEP
          @sprites[i].tone.set(@sprites[i].tone.red+SLEEPTONE[0],@sprites[i].tone.green+SLEEPTONE[1],@sprites[i].tone.blue+SLEEPTONE[2],@sprites[i].tone.gray+SLEEPTONE[3])
        end
      end
    end
  end
end

# Update the Passage method for bridge and ice sliding
def pbTestPass(follower,x,y,direction=nil)
  ret = $MapFactory.isPassableStrict?(follower.map.map_id,x,y,follower)
  if defined?(PBTerrain::StairLeft) && ($MapFactory.getTerrainTag(follower.map.map_id,x,y)==PBTerrain::StairLeft ||$MapFactory.getTerrainTag(follower.map.map_id,x,y)==PBTerrain::StairRight)
    return true
  end
  if !ret && $PokemonGlobal.bridge>0 &&
          PBTerrain.isBridge?($MapFactory.getTerrainTag(follower.map.map_id,x,y))
    return true
  end
  if PBTerrain.isIce?($MapFactory.getTerrainTag(follower.map.map_id,x,y))
    return true
  end
  return ret
end

#-------------------------------------------------------------------------------
# Updating the method which controls dependent event positions
#-------------------------------------------------------------------------------
class DependentEvents
  def pbFollowEventAcrossMaps(leader,follower,instant=false,leaderIsTrueLeader=true)
    d=leader.direction
    areConnected=$MapFactory.areConnected?(leader.map.map_id,follower.map.map_id)
    # Get the rear facing tile of leader
    facingDirection=10-d
    if !leaderIsTrueLeader && areConnected
      relativePos=$MapFactory.getThisAndOtherEventRelativePos(leader,follower)
      if (relativePos[1]==0 && relativePos[0]==2) # 2 spaces to the right of leader
        facingDirection=6
      elsif (relativePos[1]==0 && relativePos[0]==-2) # 2 spaces to the left of leader
        facingDirection=4
      elsif relativePos[1]==-2 && relativePos[0]==0 # 2 spaces above leader
        facingDirection=8
      elsif relativePos[1]==2 && relativePos[0]==0 # 2 spaces below leader
        facingDirection=2
      end
    end
    facings=[facingDirection] # Get facing from behind
    facings.push([0,0,4,0,8,0,2,0,6][d]) # Get right facing
    facings.push([0,0,6,0,2,0,8,0,4][d]) # Get left facing
    if !leaderIsTrueLeader
      facings.push(d) # Get forward facing
    end
    mapTile=nil
    if areConnected
      bestRelativePos=-1
      oldthrough=follower.through
      follower.through=false
      for i in 0...facings.length
        facing=facings[i]
        tile=$MapFactory.getFacingTile(facing,leader)
        if defined?(PBTerrain::StairLeft)
          if tile[1] > $game_player.x
            tile[2] -= 1 if $MapFactory.getTerrainTag(tile[0],tile[1],tile[2]-1) == PBTerrain::StairLeft && $game_map.terrain_tag($game_player.x,$game_player.y) == PBTerrain::StairLeft
          elsif tile[1] < $game_player.x
            tile[2] += 1 if $MapFactory.getTerrainTag(tile[0],tile[1],tile[2]+1) == PBTerrain::StairLeft
          end
          if tile[1] > $game_player.x
            tile[2] += 1 if $MapFactory.getTerrainTag(tile[0],tile[1],tile[2]+1) == PBTerrain::StairRight
          elsif tile[1] < $game_player.x
            tile[2] -= 1 if $MapFactory.getTerrainTag(tile[0],tile[1],tile[2]-1) == PBTerrain::StairRight && $game_map.terrain_tag($game_player.x,$game_player.y) == PBTerrain::StairRight
          end
        end
        passable = tile && $MapFactory.isPassable?(tile[0],tile[1],tile[2],follower)
        if !passable && $PokemonGlobal.bridge>0
          passable = PBTerrain.isBridge?($MapFactory.getTerrainTag(tile[0],tile[1],tile[2]))
        elsif passable && !$PokemonGlobal.surfing && $PokemonGlobal.bridge==0
          passable=!PBTerrain.isWater?($MapFactory.getTerrainTag(tile[0],tile[1],tile[2]))
        end
        if i==0 && !passable && tile &&
           PBTerrain.isLedge?($MapFactory.getTerrainTag(tile[0],tile[1],tile[2]))
          # If the tile isn't passable and the tile is a ledge,
          # get tile from further behind
          tile=$MapFactory.getFacingTileFromPos(tile[0],tile[1],tile[2],facing)
          passable= tile && $MapFactory.isPassable?(tile[0],tile[1],tile[2],follower)
          if passable && !$PokemonGlobal.surfing
            passable=!PBTerrain.isWater?($MapFactory.getTerrainTag(tile[0],tile[1],tile[2]))
          end
        end
        if passable
          relativePos=$MapFactory.getThisAndOtherPosRelativePos(
             follower,tile[0],tile[1],tile[2])
          distance=Math.sqrt(relativePos[0]*relativePos[0]+relativePos[1]*relativePos[1])
          if bestRelativePos==-1 || bestRelativePos>distance
            bestRelativePos=distance
            mapTile=tile
          end
          if i==0 && distance<=1 # Prefer behind if tile can move up to 1 space
            break
          end
        end
      end
      follower.through=oldthrough
    else
      tile=$MapFactory.getFacingTile(facings[0],leader)
      passable= tile && $MapFactory.isPassable?(tile[0],tile[1],tile[2],follower)
      mapTile=passable ? mapTile : nil
    end
    if mapTile && follower.map.map_id==mapTile[0]
      # Follower is on same map
      newX=mapTile[1]
      newY=mapTile[2]
      deltaX=(d == 6 ? -1 : d == 4 ? 1 : 0)
      deltaY=(d == 2 ? -1 : d == 8 ? 1 : 0)
      posX = newX + deltaX
      posY = newY + deltaY
      follower.move_speed=leader.move_speed # sync movespeed
      if (follower.x-newX==-1 && follower.y==newY) ||
         (follower.x-newX==1 && follower.y==newY) ||
         (follower.y-newY==-1 && follower.x==newX) ||
         (follower.y-newY==1 && follower.x==newX)
        if instant
          follower.moveto(newX,newY)
        else
          pbFancyMoveTo(follower,newX,newY,leader)
        end
      elsif (follower.x-newX==-2 && follower.y==newY) ||
            (follower.x-newX==2 && follower.y==newY) ||
            (follower.y-newY==-2 && follower.x==newX) ||
            (follower.y-newY==2 && follower.x==newX)
        if instant
          follower.moveto(newX,newY)
        else
          pbFancyMoveTo(follower,newX,newY,leader)
        end
      elsif follower.x!=posX || follower.y!=posY
        if instant
          follower.moveto(newX,newY)
        else
          pbFancyMoveTo(follower,posX,posY,leader)
          pbFancyMoveTo(follower,newX,newY,leader)
        end
      end
    else
      if !mapTile
        # Make current position into leader's position
        mapTile=[leader.map.map_id,leader.x,leader.y]
      end
      if follower.map.map_id==mapTile[0]
        # Follower is on same map as leader
        follower.moveto(leader.x,leader.y)
  #      pbTurnTowardEvent(follower,leader) if !follower.move_route_forcing
      else
        # Follower will move to different map
        events=$PokemonGlobal.dependentEvents
        eventIndex=pbEnsureEvent(follower,mapTile[0])
        if eventIndex>=0
          newFollower=@realEvents[eventIndex]
          newEventData=events[eventIndex]
          newFollower.moveto(mapTile[1],mapTile[2])
          newEventData[3]=mapTile[1]
          newEventData[4]=mapTile[2]
          if mapTile[0]==leader.map.map_id
      #      pbTurnTowardEvent(follower,leader) if !follower.move_route_forcing
          end
        end
      end
    end
  end


  #Fix follower not being in the same spot upon save
  def pbMapChangeMoveDependentEvents
    return
  end
end

#-------------------------------------------------------------------------------
# Various updates to the Map scene for followers
#-------------------------------------------------------------------------------
class Scene_Map

# Check for Toggle input and update the stepping animation
  alias follow_update update
  def update
    follow_update
    for i in 0...$PokemonGlobal.dependentEvents.length
      event=$PokemonTemp.dependentEvents.realEvents[i]
      return if event.move_route_forcing
    end
    if Input.trigger?(getConst(Input,TOGGLEFOLLOWERKEY)) && !$PokemonGlobal.bicycle && ALLOWTOGGLEFOLLOW
      pbToggleFollowingPokemon
    end
    if $PokemonGlobal.followerToggled
      firstPkmn = $Trainer.arenayIndex
      # Pokemon always move if switch is on, have flying type, or are in a settings array
      if ALWAYS_ANIMATE || Input.dir4!=0
        $PokemonTemp.dependentEvents.update_stepping
      elsif $PokemonTemp.dependentEvents.refresh_sprite(false) == -1
        $PokemonTemp.dependentEvents.stop_stepping
      elsif !$PokemonTemp.dependentEvents.refresh_sprite(false)
        $PokemonTemp.dependentEvents.stop_stepping
      end
    end
  end

  alias follow_transfer transfer_player
  def transfer_player(cancelVehicles=true)
    follow_transfer(cancelVehicles)
    events=$PokemonGlobal.dependentEvents
    $PokemonTemp.dependentEvents.updateDependentEvents
    for i in 0...events.length
      event = $PokemonTemp.dependentEvents.realEvents[i]
      $PokemonTemp.dependentEvents.come_back(false)
      $PokemonTemp.dependentEvents.pbFollowEventAcrossMaps($game_player,event,false,i==0)
    end
  end
end

#-------------------------------------------------------------------------------
# Functions for handling the work that the variables did earlier
#-------------------------------------------------------------------------------
class PokemonGlobalMetadata
  attr_accessor :followerToggled
  attr_accessor :callRefresh
  attr_accessor :timeTaken
  attr_accessor :followerHoldItem
  attr_writer :dependentEvents

  def dependentEvents
    @dependentEvents=[] if !@dependentEvents
    return @dependentEvents
  end

  def callRefresh
    @callRefresh = [false,false] if !@callRefresh
    return @callRefresh
  end

  def callRefresh=(value)
    ret = value
    ret = [value,false] if !value.is_a?(Array)
    @callRefresh = value
  end

  def followerToggled
    @followerToggled = false if !@followerToggled
    return @followerToggled
  end

  def timeTaken
    @timeTaken = 0 if !@timeTaken
    return @timeTaken
  end

  def followerHoldItem
    @followerHoldItem = false if !@followerHoldItem
    return @followerHoldItem
  end
end

Events.onStepTaken += proc { |_sender,_e|
  if $PokemonGlobal.callRefresh[0]
    $PokemonTemp.dependentEvents.come_back($PokemonGlobal.callRefresh[1])
    $PokemonGlobal.callRefresh = [false,false]
  end
}

class PokeBattle_Trainer
  def hasArenay?
    return true if arenayIndex > -1
    return false
  end

  def arenayIndex(pkmn=false)
    ret = -1
    @party.each_with_index do |p,i|
      ret = i if p && p.isSpecies?(:ARENAY) && (p.able? || $game_switches[400])
    end
    if pkmn
      return @party[ret] if ret >= 0
      return nil
    end
    return ret
  end
end

if defined?(PluginManager)
  PluginManager.register({
    :name => "Following Pokemon EX",
    :version => "1.2",
    :credits => ["Golisopod User","Help-14","zingzags","Rayd12smitty","Venom12","mej71","PurpleZaffre","Akizakura16"],
    :link => "https://reliccastle.com/resources/"
  })
else
  raise "This script is only compatible with Essentials v18.x. You should update your Essentials ya goof."
end
