#===============================================================================
# DO NOT TOUCH THIS UNDER ANY CIRCUMSTANCES
#===============================================================================
class FollowerEvent < Event
  def trigger(*arg)
    for callback in @callbacks
      ret = callback.call(*arg)
      return ret if ret == true || ret == false
    end
    return -1
  end
end

module Events
  @@OnTalkToFollower = FollowerEvent.new
  def self.OnTalkToFollower;     @@OnTalkToFollower;     end
  def self.OnTalkToFollower=(v); @@OnTalkToFollower = v; end

  @@FollowerRefresh = FollowerEvent.new
  def self.FollowerRefresh;     @@FollowerRefresh;     end
  def self.FollowerRefresh=(v); @@FollowerRefresh = v; end
end

#===============================================================================
# Config Script For Your Game starts Here.
# V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V  V
#===============================================================================
# Common event that contains "pbTalkToFollower" in  a script command
Follower_Common_Event         = 5

# Animation IDs from followers, change this if you are not using the
# Animations.rxdata provided in the script
Animation_Come_Out = 30
Animation_Come_In = 29
Emo_Happy = 10
Emo_Normal = 18
Emo_Hate = 12
Emo_Poison = 14
Emo_sing = 16
Emo_love = 9

# Allow the player to toggle followers on/off using the Key specified below
ALLOWTOGGLEFOLLOW = false
TOGGLEFOLLOWERKEY = :CTRL

#Status tones to be used, if this is true (Red,Green,Blue,Gray)
APPLYSTATUSTONES = false
BURNTONE = [204,51,51,50]
POISONTONE = [153,102,204,50]
PARALYSISTONE = [255,255,153,50]
FREEZETONE = [153,204,204,50]
SLEEPTONE = [0,0,0,50]

#Follower sprite will always animated while standing still
ALWAYS_ANIMATE  = true

#Regardless of the above setting,the species in this array will always animate
ALWAYS_ANIMATED_FOLLOWERS = [
  # ARENAY
  907
]

#===============================================================================
# These are used to define whether the follower should appear or disappear when
# refreshing it. "next true" will let it stay and "next false" will make it disappear
#===============================================================================
Events.FollowerRefresh += proc{|pkmn|
  if $PokemonGlobal.diving
    next true if pkmn.hasType?(:WATER)
    next false
  end
}

# Animate if has Levitate, is a flying type or always animates
Events.FollowerRefresh += proc{|pkmn|
  next true if pkmn.hasType?(:FLYING)
  next true if pkmn.hasAbility?(:LEVITATE)
  next true if ALWAYS_ANIMATED_FOLLOWERS.include?(pkmn.species)
}

#-------------------------------------------------------------------------------
# These are used to define what the Follower will say when spoken to
#-------------------------------------------------------------------------------

# Amie Compatibility
if defined?(pokemonAmieRefresh)
  Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
    cmd = pbMessage("What would you like to do?",["Play","Talk","Cancel"])
    pokemonAmieRefresh if cmd == 0
    next true if [0,2].include?(cmd)
  }
end


Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  cmd = pbMessage("What would you like to do?",["Talk","Give Item","Take Item","Cancel"])
  if cmd == 1
    item = 0
    oldItem = pkmn.item
    pbFadeOutIn {
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene,$PokemonBag)
      item = screen.pbChooseItemCelluloseScreen
    }
    if item>0
      ret = false
      newitemname = PBItems.getName(item)
      if pkmn.mail
        pbMessage(_INTL("{1}'s mail must be removed before giving it an item.",pkmn.name))
        ret = false
      end
      if pkmn.hasItem?
        olditemname = PBItems.getName(pkmn.item)
        if pkmn.hasItem?(:LEFTOVERS)
          pbMessage(_INTL("{1} is already holding some {2}.\1",pkmn.name,olditemname))
        elsif newitemname.starts_with_vowel?
          pbMessage(_INTL("{1} is already holding an {2}.\1",pkmn.name,olditemname))
        else
          pbMessage(_INTL("{1} is already holding a {2}.\1",pkmn.name,olditemname))
        end
        if pbConfirmMessage(_INTL("Would you like to switch the two items?"))
          $PokemonBag.pbDeleteItem(item)
          if !$PokemonBag.pbStoreItem(pkmn.item)
            if !$PokemonBag.pbStoreItem(item)
              raise _INTL("Could't re-store deleted item in Bag somehow")
            end
            pbMessage(_INTL("The Bag is full. The Pokémon's item could not be removed."))
          else
            if pbIsMail?(item)
              ret = false
            else
              pkmn.setItem(item)
              pbMessage(_INTL("Took the {1} from {2} and gave it the {3}.",olditemname,pkmn.name,newitemname))
              ret = true
            end
          end
        end
      else
        if !pbIsMail?(item)
          $PokemonBag.pbDeleteItem(item)
          pkmn.setItem(item)
          pbMessage(_INTL("{1} is now holding the {2}.",pkmn.name,newitemname))
          ret = true
        end
      end
      if ret
        if pbGetPocket(pkmn.item) == 6 || (pbGetPocket(oldItem) == 6 && pbGetPocket(pkmn.item) != 6)
          $scene.spriteset.addUserAnimation(DUST_ANIMATION_ID,x,y+1,true,1)
          pbSEPlay("animform")
        end
        $PokemonTemp.dependentEvents.change_sprite([pkmn.species, pkmn.female?,
          pkmn.shiny?, pkmn.form,
          pkmn.shadowPokemon?])
        pbWait(Graphics.frame_rate/5)
        pbPlayCry(pkmn)
      end
    end
  elsif cmd == 2
    ret = false
    oldItem = pkmn.item
    if !pkmn.hasItem?
      pbMessage(_INTL("{1} isn't holding anything.",pkmn.name))
    elsif !$PokemonBag.pbCanStore?(pkmn.item)
      pbMessage(_INTL("The Bag is full. The Pokémon's item could not be removed."))
    elsif pkmn.mail
      if pbConfirmMessage(_INTL("Save the removed mail in your PC?"))
        if !pbMoveToMailbox(pkmn)
          pbMessage(_INTL("Your PC's Mailbox is full."))
        else
          pbMessage(_INTL("The mail was saved in your PC."))
          pkmn.setItem(0)
          ret = true
        end
      elsif pbConfirmMessage(_INTL("If the mail is removed, its message will be lost. OK?"))
        $PokemonBag.pbStoreItem(pkmn.item)
        itemname = PBItems.getName(oldItem)
        pbMessage(_INTL("Received the {1} from {2}.",itemname,pkmn.name))
        pkmn.setItem(0)
        ret = true
        pkmn.mail = nil
      end
    else
      itemname = PBItems.getName(oldItem)
      pbMessage(_INTL("Received the {1} from {2}.",itemname,pkmn.name))
      $PokemonBag.pbStoreItem(pkmn.item)
      pkmn.setItem(0)
      ret = true
    end
    if ret
      if pbGetPocket(oldItem) == 6
        $scene.spriteset.addUserAnimation(DUST_ANIMATION_ID,x,y+1,true,1)
        pbSEPlay("animform")
        $PokemonTemp.dependentEvents.change_sprite([pkmn.species, pkmn.female?,
          pkmn.shiny?, pkmn.form,
          pkmn.shadowPokemon?])
        pbWait(Graphics.frame_rate/5)
      end
      pbPlayCry(pkmn)
    end
  end
  next true if cmd != 0
  pbPlayCry(pkmn)
}

Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
# Special Dialogue when statused
  case pkmn.status
  when PBStatuses::POISON
    $scene.spriteset.addUserAnimation(Emo_Poison,x,y)
    pbWait(120)
    pbMessage(_INTL("{1} is shivering with the effects of being poisoned.",pkmn.name))
  when PBStatuses::BURN
    $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
    pbWait(70)
    pbMessage(_INTL("{1}'s burn looks painful.",pkmn.name))
  when PBStatuses::FROZEN
    $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
    pbWait(100)
    pbMessage(_INTL("{1} seems very cold. It's frozen solid!",pkmn.name))
  when PBStatuses::SLEEP
    $scene.spriteset.addUserAnimation(Emo_Normal, x, y)
    pbWait(100)
    pbMessage(_INTL("{1} seems really tired.",pkmn.name))
  when PBStatuses::PARALYSIS
    $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
    pbWait(100)
    pbMessage(_INTL("{1} is standing still and twitching.",pkmn.name))
  end
  next true if pkmn.status != PBStatuses::NONE
}

Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $PokemonGlobal.followerHoldItem
    if pkmn.happiness > 250
      items=[:MAXPOTION,:FULLRESTORE,:BIGPEARL,:STARPIECE,:ULTRABALL,
        :CHOICEBAND,:LIFEORB,:SACREDASH,:AGUAVBERRY,:SITRUSBERRY
      ]
      message = "#{pkmn.name} is eager to give you something..."
    elsif pkmn.happiness > 200
      items=[:MAXPOTION,:HYPERPOTION,:NUGGET,:STARPIECE,:GREATBALL,
        :CHOICESCARF,:AIRBALLOON,:MAXREVIVE,:LUMBERRY,:SITRUSBERRY
      ]
      message = "#{pkmn.name} wants to give you something..."
    elsif pkmn.happiness > 150
      items=[:MOOMOOMILK,:HYPERPOTION,:NUGGET,:PEARL,:DUSKBALL,
        :CHOICESPECS,:EVIOLITE,:REVIVE,:CUSTAPBERRY,:SITRUSBERRY
      ]
      message = "#{pkmn.name} is found something for you..."
    elsif pkmn.happiness > 100
      items=[:SUPERPOTION,:MOOMOOMILK,:STARDUST,:PEARL,:POKEBALL,
        :PRETTYWING,:FULLHEAL,:ESCAPEROPE,:ORANBERRY,:SITRUSBERRY
      ]
      message = "#{pkmn.name} is holding an item..."
    elsif pkmn.happiness > 50
      items=[:POTION,:SUPERPOTION,:BIGMUSHROOM,:STARDUST,:POKETOY,
        :PRETTYWING,:ORANBERRY,:CHESTOBERRY,:PECHABERRY,:HONEY
      ]
      message = "#{pkmn.name} found something..."
    else
      pbMessage("Oh, looks like Arenay is holding something.")
      $scene.spriteset.addUserAnimation(12,x,y)
      followingMoveRoute([PBMoveRoute::Wait,6,PBMoveRoute::TurnAwayFromPlayer,PBMoveRoute::Wait,6])
      pbMessage("Arenay threw the item away!")
      next true
    end
    next true if pbPokemonFound(rand(items.length),1,message)
  end
}

# Specific message if the map name has the players name in it ie the Player's Hpuse
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $game_map.name.include?($Trainer.name)
    $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
    pbWait(70)
    messages = [
      "{1} is sniffing around the room.",
      "{1} noticed {2}'s mom is nearby.",
      "{1} seems to want to settle down at home."
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Pokecenter or Pokemon Center
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $game_map.name.include?("Poké Center") || $game_map.name.include?("Pokémon Center")
    $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
    pbWait(70)
    messages = [
      "{1} looks happy to see the nurse.",
      "{1} looks a little better just being in the Pokémon Center.",
      "{1} seems fascinated by the healing machinery.",
      "{1} looks like it wants to take a nap.",
      "{1} chirped a greeting at the nurse.",
      "{1} is watching {2} with a playful gaze.",
      "{1} seems to be completely at ease.",
      "{1} is making itself comfortable.",
      "There's a content expression on {1}'s face."
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Forest
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $game_map.name.include?("Forest") || $game_map.name.include?("Lush")
    $scene.spriteset.addUserAnimation(Emo_sing,x,y)
    pbWait(50)
    messages = [
      "{1} seems highly interested in the trees.",
      "{1} seems to enjoy the buzzing of the bug Pokémon.",
      "{1} is jumping around restlessly in the forest.",
      "{1} is wandering around and listening to the different sounds.",
      "{1} is munching at the grass.",
      "{1} is wandering around and enjoying the forest scenery.",
      "{1} is playing around, plucking bits of grass.",
      "{1} is staring at the light coming through the trees.",
      "{1} is playing around with a leaf!",
      "{1} seems to be listening to the sound of rustling leaves.",
      "{1} is standing perfectly still and might be imitating a tree...",
      "{1} got tangled in the branches and almost fell down!",
      "{1} was surprised when it got hit by a branch!"
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Gym in it
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $game_map.name.include?("Dojo") || $game_map.name.include?("Driftwood")
    $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
    pbWait(70)
    messages = [
      "{1} looks eager to battle!",
      "{1} is looking at {2} with a determined gleam in its' eye.",
      "{1} is trying to intimidate the other trainers.",
      "{1} trusts {2} to come up with a winning strategy.",
      "{1} is keeping an eye on the gym leader.",
      "{1} is ready to pick a fight with someone.",
      "{1} looks like it might be preparing for a big showdown!",
      "{1} wants to show off how strong it is!",
      "{1} is...doing warm-up exercises?",
      "{1} is growling quietly in contemplation..."
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name is Pokemon Lab
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $game_map.name.include?("Lab")
    $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
    pbWait(100)
    messages = [
      "{1} is touching some kind of switch.",
      "{1} has a cord in its mouth!",
      "{1} seems to want to touch the machinery."
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Beach in it
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if $game_map.name.include?("Beach") || $game_map.name.include?("Costa")
    $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
    pbWait(70)
    messages = [
      "{1} seems to be enjoying the scenery.",
      "{1} seems to enjoy the sound of the waves moving the sand.",
      "{1} looks like it wants to swim!",
      "{1} can barely look away from the ocean.",
      "{1} is staring longingly at the water.",
      "{1} keeps trying to shove {2} towards the water.",
      "{1} is excited to be looking at the sea!",
      "{1} is happily watching the waves!",
      "{1} is playing on the sand!",
      "{1} is staring at {2}'s footprints in the sand.",
      "{1} is rolling around in the sand."
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Rain specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if [PBFieldWeather::Rain,PBFieldWeather::HeavyRain].include?($game_screen.weather_type)
    if pkmn.hasType?(:FIRE) || pkmn.hasType?(:GROUND) || pkmn.hasType?(:ROCK)
      $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
      pbWait(70)
      messages = [
        "{1} seems very upset at the weather.",
        "{1} is shivering...",
        "{1} doesn't seem to like being all wet...",
        "{1} keeps trying to shake itself dry...",
        "{1} moved closer to {2} for comfort.",
        "{1} is looking up at the sky and scowling.",
        "{1} seems to be having difficulty moving its body."
      ]
    elsif pkmn.hasType?(:WATER) || pkmn.hasType?(:GRASS)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} seems to be enjoying the weather.",
        "{1} seems to be happy about the rain!",
        "{1} seems to be very surprised that it is raining!",
        "{1} beamed happily at {2}!",
        "{1} is gazing up at the rainclouds.",
        "Raindrops keep falling on {1}.",
        "{1} is looking up with its mouth gaping open."
      ]
    else
      $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
      pbWait(100)
      messages = [
        "{1} is staring up at the sky.",
        "{1} looks a bit surprised to see rain.",
        "{1} keeps trying to shake itself dry.",
        "The rain doesn't seem to bother {1} much.",
        "{1} is playing in a puddle!",
        "{1} is slipping in the water and almost fell over!"
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Storm Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if PBFieldWeather::Storm == $game_screen.weather_type
    if pkmn.hasType?(:ELECTRIC)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} is staring up at the sky.",
        "The storm seems to be making {1} excited.",
        "{1} looked up at the sky and shouted loudly!",
        "The storm only seems to be energizing {1}!",
        "{1} is happily zapping and jumping in circles!",
        "The lightning doesn't bother {1} at all."
      ]
    else
      $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
      pbWait(100)
      messages = [
        "{1} is staring up at the sky.",
        "The storm seems to be making {1} a bit nervous.",
        "The lightning startled {1}!",
        "The rain doesn't seem to bother {1} much.",
        "The weather seems to be putting {1} on edge.",
        "{1} was startled by the lightning and snuggled up to {2}!"
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Snow Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if PBFieldWeather::Snow == $game_screen.weather_type
    if pkmn.hasType?(:ICE)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} is watching the snow fall.",
        "{1} is thrilled by the snow!",
        "{1} is staring up at the sky with a smile.",
        "The snow seems to have put {1} in a good mood.",
        "{1} is cheerful because of the cold!"
      ]
    else
      $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
      pbWait(100)
      messages = [
        "{1} is watching the snow fall.",
        "{1} is nipping at the falling snowflakes.",
        "{1} wants to catch a snowflake in its' mouth.",
        "{1} is fascinated by the snow.",
        "{1}'s teeth are chattering!",
        "{1} made its body slightly smaller because of the cold..."
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Blizzard Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if PBFieldWeather::Blizzard == $game_screen.weather_type
    if pkmn.hasType?(:ICE)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} is watching the hail fall.",
        "{1} isn't bothered at all by the hail.",
        "{1} is staring up at the sky with a smile.",
        "The hail seems to have put {1} in a good mood.",
        "{1} is gnawing on a piece of hailstone."
      ]
    else
      $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
      pbWait(70)
      messages = [
        "{1} is getting pelted by hail!",
        "{1} wants to avoid the hail.",
        "The hail is hitting {1} painfully.",
        "{1} looks unhappy.",
        "{1} is shaking like a leaf!"
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Sandstorm Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if PBFieldWeather::Sandstorm == $game_screen.weather_type
    if pkmn.hasType?(:ROCK) || pkmn.hasType?(:GROUND)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} is coated in sand.",
        "The weather doesn't seem to bother {1} at all!",
        "The sand can't slow {1} down!",
        "{1} is enjoying the weather."
      ]
    elsif pkmn.hasType?(:STEEL)
      $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
      pbWait(100)
      messages = [
        "{1} is coated in sand, but doesn't seem to mind.",
        "{1} seems unbothered by the sandstorm.",
        "The sand doesn't slow {1} down.",
        "{1} doesn't seem to mind the weather."
      ]
    else
      $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
      pbWait(70)
      messages = [
        "{1} is covered in sand...",
        "{1} spat out a mouthful of sand!",
        "{1} is squinting through the sandstorm.",
        "The sand seems to be bothering {1}."
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Sunny Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if PBFieldWeather::Sun == $game_screen.weather_type
    if pkmn.hasType?(:GRASS)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} seems pleased to be out in the sunshine.",
        "{1} is soaking up the sunshine.",
        "The bright sunlight doesn't seem to bother {1} at all.",
        "{1} sent a ring-shaped cloud of spores into the air!",
        "{1} is stretched out its body and is relaxing in the sunshine.",
        "{1} is giving off a floral scent."
      ]
    elsif pkmn.hasType?(:FIRE)
      $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
      pbWait(70)
      messages = [
        "{1} seems to be happy about the great weather!",
        "The bright sunlight doesn't seem to bother {1} at all.",
        "{1} looks thrilled by the sunshine!",
        "{1} blew out a fireball.",
        "{1} is breathing out fire!",
        "{1} is hot and cheerful!"
      ]
    elsif pkmn.hasType?(:DARK)
      $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
      pbWait(70)
      messages = [
        "{1} is glaring up at the sky.",
        "{1} seems personally offended by the sunshine.",
        "The bright sunshine seems to bothering {1}.",
        "{1} looks upset for some reason.",
        "{1} is trying to stay in {2}'s shadow.",
        "{1} keeps looking for shelter from the sunlight.",
      ]
    else
      $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
      pbWait(100)
      messages = [
        "{1} is squinting in the bright sunshine.",
        "{1} is starting to sweat.",
        "{1} seems a little uncomfortable in this weather.",
        "{1} looks a little overheated.",
        "{1} seems very hot...",
        "{1} shielded its vision against the sparkling light!",
       ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Music Note animation
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if randomVal == 0
    $scene.spriteset.addUserAnimation(Emo_sing,x,y)
    pbWait(50)
    messages = [
      "{1} seems to want to play with {2}.",
      "{1} is singing and humming.",
      "{1} is looking up at {2} with a happy expression.",
      "{1} swayed and danced around as it pleased.",
      "{1} is jumping around in a carefree way!",
      "{1} is showing off its agility!",
      "{1} is moving around happily!",
      "Whoa! {1} suddenly started dancing in happiness!",
      "{1} is steadily keeping up with {2}!",
      "{1} is happy skipping about.",
      "{1} is playfully nibbling at the ground.",
      "{1} is playfully nipping at {2}'s feet!",
      "{1} is following {2} very closely!",
      "{1} turns around and looks at {2}.",
      "{1} is working hard to show off its mighty power!",
      "{1} looks like it wants to run around!",
      "{1} is wandering around enjoying the scenery.",
      "{1} seems to be enjoying this a little bit!",
      "{1} is cheerful!",
      "{1} seems to be singing something?",
      "{1} is dancing around happily!",
      "{1} is having fun dancing a lively jig!",
      "{1} is so happy, it started singing!",
      "{1} looked up and howled!",
      "{1} seems to be feeling optimistic.",
      "It looks like {1} feels like dancing!",
      "{1} Suddenly started to sing! It seems to be feeling great.",
      "It looks like {1} wants to dance with {2}!"
    ]
    value = rand(messages.length)
    case value
    # Special move route to go along with some of the dialogue
    when 3, 9
        followingMoveRoute([
        PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,
        PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,
        PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,
        PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,PBMoveRoute::Jump,0,0])
    when 4, 5
        followingMoveRoute([
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,PBMoveRoute::Jump,0,0])
    when 6, 17
        followingMoveRoute([
        PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,PBMoveRoute::TurnUp])
    when 7, 28
        followingMoveRoute([
        PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,PBMoveRoute::Jump,0,0])
    when 21, 22
        followingMoveRoute([
        PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
        PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Angry animation
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if randomVal == 1
    $scene.spriteset.addUserAnimation(Emo_Hate,x,y)
    pbWait(70)
    messages = [
      "{1} let out a roar!",
      "{1} is making a face like it's angry!",
      "{1} seems to be angry for some reason.",
      "{1} chewed on {2}'s feet.",
      "{1} turned to face the other way, showing a defiant expression.",
      "{1} is trying to intimidate {2}'s foes!",
      "{1} wants to pick a fight!",
      "{1} is ready to fight!",
      "It looks like {1} will fight just about anyone right now!",
      "{1} is growling in a way that sounds almost like speech..."
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 6, 7, 8
        followingMoveRoute([
          PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Neutral Animation
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if randomVal == 2
    $scene.spriteset.addUserAnimation(Emo_Normal,x,y)
    pbWait(100)
    messages = [
      "{1} is looking down steadily.",
      "{1} is sniffing around.",
      "{1} is concentrating deeply.",
      "{1} faced {2} and nodded.",
      "{1} is glaring straight into {2}'s eyes.",
      "{1} is surveying the area.",
      "{1} focused with a sharp gaze!",
      "{1} is looking around absentmindedly.",
      "{1} yawned very loudly!",
      "{1} is relaxing comfortably.",
      "{1} is focusing its attention on {2}.",
      "{1} is staring intently at nothing.",
      "{1} is concentrating.",
      "{1} faced {2} and nodded.",
      "{1} is looking at {2}'s footprints.",
      "{1} seems to want to play and is gazing at {2} expectedly.",
      "{1} seems to be thinking deeply about something.",
      "{1} isn't paying attention to {2}...Seems it's thinking about something else.",
      "{1} seems to be feeling serious.",
      "{1} seems disinterested.",
      "{1}'s mind seems to be elsewhere.",
      "{1} seems to be observing the surroundings instead of watching {2}.",
      "{1} looks a bit bored.",
      "{1} has an intense look on its' face.",
      "{1} is staring off into the distance.",
      "{1} seems to be carefully examining {2}'s face.",
      "{1} seems to be trying to communicate with its' eyes.",
      "...{1} seems to have sneezed!",
      "...{1} noticed that {2}'s shoes are a bit dirty.",
      "Seems {1} ate something strange, it's making an odd face... ",
      "{1} seems to be smelling something good.",
      "{1} noticed that {2}' Bag has a little dirt on it...",
      "...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... {1} silently nodded!"
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when  1, 5, 7, 20, 21
        followingMoveRoute([
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,10,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,10,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,10,
          PBMoveRoute::TurnDown])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Happy animation
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if randomVal == 3
    $scene.spriteset.addUserAnimation(Emo_Happy,x,y)
    pbWait(70)
    messages = [
      "{1} began poking {2}.",
      "{1} looks very happy.",
      "{1} happily cuddled up to {2}.",
      "{1} is so happy that it can't stand still.",
      "{1} looks like it wants to lead!",
      "{1} is coming along happily.",
      "{1} seems to be feeling great about walking with {2}!",
      "{1} is glowing with health.",
      "{1} looks very happy.",
      "{1} put in extra effort just for {2}!",
      "{1} is smelling the scents of the surounding air.",
      "{1} is jumping with joy!",
      "{1} is still feeling great!",
      "{1} stretched out its body and is relaxing.",
      "{1} is doing its' best to keep up with {2}.",
      "{1} is happily cuddling up to {2}!",
      "{1} is full of energy!",
      "{1} is so happy that it can't stand still!",
      "{1} is wandering around and listening to the different sounds.",
      "{1} gives {2} a happy look and a smile.",
      "{1} started breathing roughly through its nose in excitement!",
      "{1} is trembling with eagerness!",
      "{1} is so happy, it started rolling around.",
      "{1} looks thrilled at getting attention from {2}.",
      "{1} seems very pleased that {2} is noticing it!",
      "{1} started wriggling its' entire body with excitement!",
      "It seems like {1} can barely keep itself from hugging {2}!",
      "{1} is keeping close to {2}'s feet"
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 3
        followingMoveRoute([
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,PBMoveRoute::Jump,0,0])
    when 11, 16, 17, 24
        followingMoveRoute([
          PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,
          PBMoveRoute::Jump,0,0,PBMoveRoute::Wait,10,PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Heart animation
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if randomVal == 4
    $scene.spriteset.addUserAnimation(Emo_love,x,y)
    pbWait(70)
    messages = [
      "{1} suddenly started walking closer to {2}.",
      "Woah! {1} suddenly hugged {2}.",
      "{1} is rubbing up against {2}.",
      "{1} is keeping close to {2}.",
      "{1} blushed.",
      "{1} loves spending time with {2}!",
      "{1} is suddenly playful!",
      "{1} is rubbing against {2}'s legs!",
      "{1} is regarding {2} with adoration!",
      "{1} seems to want some affection from {2}.",
      "{1} seems to want some attention from {2}.",
      "{1} seems happy travelling with {2}.",
      "{1} seems to be feeling affectionate towards {2}.",
      "{1} is looking at {2} with loving eyes.",
      "{1} looks like it wants a treat from {2}.",
      "{1} looks like it wants {2} to pet it!",
      "{1} is rubbing itself against {2} affectionately.",
      "{1} bumps its' head gently against {2}'s hand.",
      "{1} rolls over and looks at {2} expectantly.",
      "{1} is looking at {2} with trusting eyes.",
      "{1} seems to be begging {2} for some affection!",
      "{1} mimicked {2}!"
    ]
    value = rand(messages.length)
    case value
    when 1, 6,
        followingMoveRoute([
          PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with no animation
Events.OnTalkToFollower += proc {|pkmn,x,y,randomVal|
  if randomVal == 5
    if rand(5)<1
      messages = [
        "{1} looks like its itching to hold onto some of the cellulose in {2}'s bag!",
        "{1} is shooting small puffs of smoke into the air, trying to make various shapes.",
        "{1} is splashing around, making little puddles in the ground!",
        "{1} is shaking loose leaves out of the top of it's bushy growth.",
        "{1} is slowly flapping its wings and trying to stay in the same place.",
        "{1} curls up, in a defensive pose! It looks ready to take on anything!",
        "{1} releases a small jolt of electricty, gently tickling {2}'s' fingers!",
        "{1} is freezing the ground underneath it, allowing it to slide around a little! Looks fun!",
        "{1} is sending psychic waves in your direction, in attempt to persuade you to feed it more berries.",
        "{1} has spiderwebs stuck on its tentacles... they seem hard to remove!",
        "{1} is burrowing under the ground, kicking up small pebbles as it moves.",
        "{1} slides away as you try to pet it... It doesn't want to poison {2}!",
        "{1} has a confident look on its face, almost like it wants to test its strength!",
        "{1} is meditating... it looks like it's trying to focus its chakras!",
        "{1} is staying motionless. It looks like it wants to blend in to the environment!",
        "{1} is fading in and out of our living realm... that's pretty spooky!",
        "{1} is shimmering with a dark aura... It's hard not to stare!",
        "{1} is radiating optimistic energy! It looks so cute, you can't resist hugging it!"
      ]
      pbMessage(_INTL(messages[pkmn.form],pkmn.name,$Trainer.name))
      next true
    end
    messages = [
      "{1} spun around in a circle!",
      "{1} let out a battle cry.",
      "{1} is on the lookout!",
      "{1} is standing patiently.",
      "{1} is looking around restlessly.",
      "{1} is wandering around.",
      "{1} yawned loudly!",
      "{1} is steadily poking at the ground around {2}'s feet.",
      "{1} is looking at {2} and smiling.",
      "{1} is staring intently into the distance.",
      "{1} is keeping up with {2}.",
      "{1} looks pleased with itself.",
      "{1} is still going strong!",
      "{1} is walking in sync with {2}.",
      "{1} started spinning around in circles.",
      "{1} looks at {2} with anticipation.",
      "{1} fell down and looks a little embarrassed.",
      "{1} is waiting to see what {2} will do.",
      "{1} is calmly watching {2}.",
      "{1} is looking to {2} for some kind of cue.",
      "{1} is staying in place, waiting for {2} to make a move.",
      "{1} obidiently sat down at {2}'s feet.",
      "{1} jumped in surprise!",
      "{1} jumped a little!"
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 0
        followingMoveRoute([
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,PBMoveRoute::TurnDown])
    when 2,4
        followingMoveRoute([
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,10,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,10,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,10,PBMoveRoute::TurnDown])
    when 14
        followingMoveRoute([
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnRight,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,PBMoveRoute::Wait,4,PBMoveRoute::TurnDown])
    when 22, 23
        followingMoveRoute([
          PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}
