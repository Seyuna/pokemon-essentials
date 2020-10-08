#=============================
# Cam's Utility Functions
#=============================
def poisonAllPokemon(event=nil)
    for pkmn in $Trainer.ablePokemonParty
       next if pkmn.hasType?(:POISON)  || pkmn.hasType?(:STEEL) ||
          pkmn.hasAbility?(:COMATOSE)  || pkmn.hasAbility?(:SHIELDSDOWN) ||
          pkmn.status!=0
       pkmn.status = 2
     end
end

#thundaga
def paralyzeAllPokemon(event=nil)
    for pkmn in $Trainer.ablePokemonParty
       next if pkmn.hasType?(:ELECTRIC) ||
          pkmn.hasAbility?(:COMATOSE)  || pkmn.hasAbility?(:SHIELDSDOWN) ||
          pkmn.status!=0
       pkmn.status = 4
     end
end

def drawPlayerPicture(opacity=255)
  if $Trainer.gender==0 # Male
      $game_screen.pictures[1].show("Character1-"+$Trainer.outfit.to_s,0,0,0,100,100,opacity,0)
  else #Female
      $game_screen.pictures[1].show("Character1_1-"+$Trainer.outfit.to_s,0,0,0,100,100,opacity,0)
  end
end

# Outfit Utilities
def pbUnlockOutfit(id,displayName)
  if !$game_variables[56].is_a?(Array)
    $game_variables[56]=[[0,"Default"]]
  end
  ids= []
  outfits = $game_variables[56]
  for i in 0...outfits.length
    if outfits[i].is_a?(Array)
      ids.push(outfits[i][0])
    end
  end
  if !ids.include?(id)
    $game_variables[56].push([id,displayName])
    return true
  end
  return false
end

def pbSelectOutfit
  choices=[]
  ids= []
  if $game_variables[56].is_a?(Array) && $game_variables[56].length>1
    outfits = $game_variables[56]
    for i in 0...outfits.length
      if outfits[i].is_a?(Array)
        choices.push(outfits[i][1])
        ids.push(outfits[i][0])
      end
    end
    outfitVal=pbMessage("Select an Outfit:",choices)
    if $Trainer.outfit != ids[outfitVal]
      viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      viewport.z = 99999
      bmp = pbFade
      screen = Sprite.new(viewport)
      screen.bitmap = bmp
      10.times do
        Graphics.update
        pbWait(1)
      end
      $Trainer.outfit = ids[outfitVal]
      pbWait(30)
      10.times do
        Graphics.update
        pbWait(1)
      end
      screen.visible= false
      pbFade(true)
      screen.dispose
      viewport.dispose
      drawPlayerPicture(255)
      pbMessage(_INTL("\\pgLooking good!"))
      $game_screen.pictures[1].erase
    else
      pbMessage(_INTL("\\pgAlready wearing this outfit!"))
    end
  else
    Kernel.pbMessage("No Outfits Unlocked")
  end
end

#===============================================================================
#  Fade Out Animations by Luka SJ
#===============================================================================
def pbFade(reverse=false)
  return if !$game_player || !$scene.is_a?(Scene_Map)
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  viewport.color = Color.new(0,0,0,reverse ? 255 : 0)
  15.times do
    viewport.color.alpha += 17*(reverse ? -1 : 1)
    Graphics.update
  end
  bmp = Graphics.snap_to_bitmap
  viewport.dispose
  return bmp
end


def outfitChoices
  # Initialize the player's outfits
  if $game_variables[55]==0
    $game_variables[55]=1
  end
  # Unlock the Quantech outfit if its not already unlocked
  #Quantech = $game_switches[105]
  #Quantech Joined = $game_switches[62]
  if !$game_switches[105] && $game_switches[62]
    $game_switches[105]=true
    $game_variables[55]=($game_variables[55]+1)
  end
  # Unlock the Biogress outfit if its not already unlocked
  #Biogress = $game_switches[106]
  #Biogress Joined = $game_switches[61]
  if !$game_switches[106] && $game_switches[61]
    $game_switches[106]=true
    $game_variables[55]=($game_variables[55]+1)
  end
  # Show outfit choices and apply them to the player
  if $game_switches[105] && $game_switches[106] # Both Quantech and Biogress outfits unlocked
    pbMessage(_INTL("Change outfits?\nOutfits unlocked: {1}\\ch[1,-1,Standard,Quantech,Biogress]",$game_variables[55]))
    $Trainer.outfit=$game_variables[1]
  elsif $game_switches[105] # Quantech outfit unlocked
    pbMessage(_INTL("Change outfits?\nOutfits unlocked: {1}\\ch[1,-1,Standard,Quantech]",$game_variables[55]))
    $Trainer.outfit=$game_variables[1]
  elsif $game_switches[106] # Biogess outfit unlocked
    pbMessage(_INTL("Change outfits?\nOutfits unlocked: {1}\\ch[1,-1,Standard,Biogress]",$game_variables[55]))
    if $game_variables[1]==1 #Increment by 1 for the Biogress outfit
      $game_variables[1]=2
    end
      $Trainer.outfit=$game_variables[1]
  else # Only the Standard outfit is unlocked
    pbMessage(_INTL("Change outfits?\nOutfits unlocked: {1}\\ch[1,-1,Standard]",$game_variables[55]))
    $Trainer.outfit=$game_variables[1]
  end
  # Have player show outfit and say "looking good!"
  drawPlayerPicture(255)
  pbMessage(_INTL("\\pgLooking good!"))
  $game_screen.pictures[1].erase
end

Events.onMapSceneChange += proc { |_sender,e|
  scene      = e[0]
  mapChanged = e[1]
  next if !scene || !scene.spriteset
  # Update map trail
  if $game_map
    $PokemonGlobal.mapTrail = [] if !$PokemonGlobal.mapTrail
    if $PokemonGlobal.mapTrail[0]!=$game_map.map_id
      $PokemonGlobal.mapTrail[3] = $PokemonGlobal.mapTrail[2] if $PokemonGlobal.mapTrail[2]
      $PokemonGlobal.mapTrail[2] = $PokemonGlobal.mapTrail[1] if $PokemonGlobal.mapTrail[1]
      $PokemonGlobal.mapTrail[1] = $PokemonGlobal.mapTrail[0] if $PokemonGlobal.mapTrail[0]
    end
    $PokemonGlobal.mapTrail[0] = $game_map.map_id
  end
  # Display darkness circle on dark maps
  darkmap = pbGetMetadata($game_map.map_id,MetadataDarkMap)
  if darkmap
    if $PokemonGlobal.flashUsed
      $PokemonTemp.darknessSprite = DarknessSprite.new
      scene.spriteset.addUserSprite($PokemonTemp.darknessSprite)
      darkness = $PokemonTemp.darknessSprite
      darkness.radius = darkness.radiusMax
    else
      $PokemonTemp.darknessSprite = DarknessSprite.new
      scene.spriteset.addUserSprite($PokemonTemp.darknessSprite)
    end
  elsif !darkmap
    $PokemonGlobal.flashUsed = false
    if $PokemonTemp.darknessSprite
      $PokemonTemp.darknessSprite.dispose
      $PokemonTemp.darknessSprite = nil
    end
  end
  # Show location signpost
  if mapChanged
    if pbGetMetadata($game_map.map_id,MetadataShowArea)
      nosignpost = false
      if $PokemonGlobal.mapTrail[1]
        for i in 0...NO_SIGNPOSTS.length/2
          nosignpost = true if NO_SIGNPOSTS[2*i]==$PokemonGlobal.mapTrail[1] && NO_SIGNPOSTS[2*i+1]==$game_map.map_id
          nosignpost = true if NO_SIGNPOSTS[2*i+1]==$PokemonGlobal.mapTrail[1] && NO_SIGNPOSTS[2*i]==$game_map.map_id
          break if nosignpost
        end
        mapinfos = $RPGVX ? load_data("Data/MapInfos.rvdata") : load_data("Data/MapInfos.rxdata")
        oldmapname = mapinfos[$PokemonGlobal.mapTrail[1]].name
        nosignpost = true if $game_map.name==oldmapname
      end
      scene.spriteset.addUserSprite(LocationWindow.new($game_map.name)) if !nosignpost
    end
  end
  # Force cycling/walking
  if pbGetMetadata($game_map.map_id,MetadataBicycleAlways)
    pbMountBike
  elsif !pbCanUseBike?($game_map.map_id)
    pbDismountBike
  end
}
