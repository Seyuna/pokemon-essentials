class PokeBattle_Pokemon
  attr_accessor :formTime     # Time when Furfrou's/Hoopa's form was set
  attr_accessor :forcedForm

  def form
    return @forcedForm if @forcedForm!=nil
    return (@form || 0) if $game_temp.in_battle
    v = MultipleForms.call("getForm",self)
    self.form = v if v!=nil && (!@form || v!=@form)
    return @form || 0
  end

  def form=(value)
    setForm(value)
  end

  def setForm(value)
    oldForm = @form
    @form = value
    yield if block_given?
    MultipleForms.call("onSetForm",self,value,oldForm)
    self.calcStats
    pbSeenForm(self)
  end

  def formSimple
    return @forcedForm if @forcedForm!=nil
    return @form || 0
  end

  def formSimple=(value)
    @form = value
    self.calcStats
  end

  def fSpecies
    return pbGetFSpeciesFromForm(@species,formSimple)
  end

  alias __mf_compatibleWithMove? compatibleWithMove?   # Deprecated
  def compatibleWithMove?(move)
    v = MultipleForms.call("getMoveCompatibility",self)
    if v!=nil
      return v.any? { |j| j==move }
    end
    return __mf_compatibleWithMove?(move)
  end

  alias __mf_initialize initialize
  def initialize(*args)
    @form = (pbGetSpeciesFromFSpecies(args[0])[1] rescue 0)
    __mf_initialize(*args)
    if @form==0
      f = MultipleForms.call("getFormOnCreation",self)
      if f
        self.form = f
        self.resetMoves
      end
    end
  end
end



class PokeBattle_RealBattlePeer
  def pbOnEnteringBattle(battle,pkmn,wild=false)
    f = MultipleForms.call("getFormOnEnteringBattle",pkmn,wild)
    pkmn.form = f if f
  end

  # For switching out, including due to fainting, and for the end of battle
  def pbOnLeavingBattle(battle,pkmn,usedInBattle,endBattle=false)
    f = MultipleForms.call("getFormOnLeavingBattle",pkmn,battle,usedInBattle,endBattle)
    pkmn.form = f if f && pkmn.form!=f
    pkmn.hp = pkmn.totalhp if pkmn.hp>pkmn.totalhp
  end
end



module MultipleForms
  @@formSpecies = SpeciesHandlerHash.new

  def self.copy(sym,*syms)
    @@formSpecies.copy(sym,*syms)
  end

  def self.register(sym,hash)
    @@formSpecies.add(sym,hash)
  end

  def self.registerIf(cond,hash)
    @@formSpecies.addIf(cond,hash)
  end

  def self.hasFunction?(pkmn,func)
    spec = (pkmn.is_a?(Numeric)) ? pkmn : pkmn.species
    sp = @@formSpecies[spec]
    return sp && sp[func]
  end

  def self.getFunction(pkmn,func)
    spec = (pkmn.is_a?(Numeric)) ? pkmn : pkmn.species
    sp = @@formSpecies[spec]
    return (sp && sp[func]) ? sp[func] : nil
  end

  def self.call(func,pkmn,*args)
    sp = @@formSpecies[pkmn.species]
    return nil if !sp || !sp[func]
    return sp[func].call(pkmn,*args)
  end
end



def drawSpot(bitmap,spotpattern,x,y,red,green,blue)
  height = spotpattern.length
  width  = spotpattern[0].length
  for yy in 0...height
    spot = spotpattern[yy]
    for xx in 0...width
      if spot[xx]==1
        xOrg = (x+xx)<<1
        yOrg = (y+yy)<<1
        color = bitmap.get_pixel(xOrg,yOrg)
        r = color.red+red
        g = color.green+green
        b = color.blue+blue
        color.red   = [[r,0].max,255].min
        color.green = [[g,0].max,255].min
        color.blue  = [[b,0].max,255].min
        bitmap.set_pixel(xOrg,yOrg,color)
        bitmap.set_pixel(xOrg+1,yOrg,color)
        bitmap.set_pixel(xOrg,yOrg+1,color)
        bitmap.set_pixel(xOrg+1,yOrg+1,color)
      end
    end
  end
end

def pbSpindaSpots(pkmn,bitmap)
  spot1 = [
     [0,0,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,0,0]
  ]
  spot2 = [
     [0,0,1,1,1,0,0],
     [0,1,1,1,1,1,0],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [0,1,1,1,1,1,0],
     [0,0,1,1,1,0,0]
  ]
  spot3 = [
     [0,0,0,0,0,1,1,1,1,0,0,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,0,0,0,1,1,1,0,0,0,0,0]
  ]
  spot4 = [
     [0,0,0,0,1,1,1,0,0,0,0,0],
     [0,0,1,1,1,1,1,1,1,0,0,0],
     [0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,0,1,1,1,1,1,0,0,0]
  ]
  id = pkmn.personalID
  h = (id>>28)&15
  g = (id>>24)&15
  f = (id>>20)&15
  e = (id>>16)&15
  d = (id>>12)&15
  c = (id>>8)&15
  b = (id>>4)&15
  a = (id)&15
  if pkmn.shiny?
    drawSpot(bitmap,spot1,b+33,a+25,-75,-10,-150)
    drawSpot(bitmap,spot2,d+21,c+24,-75,-10,-150)
    drawSpot(bitmap,spot3,f+39,e+7,-75,-10,-150)
    drawSpot(bitmap,spot4,h+15,g+6,-75,-10,-150)
  else
    drawSpot(bitmap,spot1,b+33,a+25,0,-115,-75)
    drawSpot(bitmap,spot2,d+21,c+24,0,-115,-75)
    drawSpot(bitmap,spot3,f+39,e+7,0,-115,-75)
    drawSpot(bitmap,spot4,h+15,g+6,0,-115,-75)
  end
end

#===============================================================================
# Regular form differences
#===============================================================================

MultipleForms.register(:UNOWN,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(28)
  }
})

MultipleForms.register(:SPINDA,{
  "alterBitmap" => proc { |pkmn,bitmap|
    pbSpindaSpots(pkmn,bitmap)
  }
})

MultipleForms.register(:CASTFORM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:BURMY,{
  "getFormOnCreation" => proc { |pkmn|
    case pbGetEnvironment
    when PBEnvironment::Rock, PBEnvironment::Sand, PBEnvironment::Cave
      next 1   # Sandy Cloak
    when PBEnvironment::None
      next 2   # Trash Cloak
    else
      next 0   # Plant Cloak
    end
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next if !endBattle || !usedInBattle
    env = battle.environment
    case battle.environment
    when PBEnvironment::Rock, PBEnvironment::Sand, PBEnvironment::Cave
      next 1   # Sandy Cloak
    when PBEnvironment::None
      next 2   # Trash Cloak
    else
      next 0   # Plant Cloak
    end
  }
})

MultipleForms.register(:WORMADAM,{
  "getFormOnCreation" => proc { |pkmn|
    case pbGetEnvironment
    when PBEnvironment::Rock, PBEnvironment::Sand, PBEnvironment::Cave
      next 1   # Sandy Cloak
    when PBEnvironment::None
      next 2   # Trash Cloak
    else
      next 0   # Plant Cloak
    end
  }
})

MultipleForms.register(:CHERRIM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:MORPEKO,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:ROTOM,{
  "onSetForm" => proc { |pkmn,form,oldForm|
    formMoves = [
       :OVERHEAT,    # Heat, Microwave
       :HYDROPUMP,   # Wash, Washing Machine
       :BLIZZARD,    # Frost, Refrigerator
       :AIRSLASH,    # Fan
       :LEAFSTORM    # Mow, Lawnmower
    ]
    idxMoveToReplace = -1
    pkmn.moves.each_with_index do |move,i|
      next if !move
      formMoves.each do |newMove|
        next if !isConst?(move.id,PBMoves,newMove)
        idxMoveToReplace = i
        break
      end
      break if idxMoveToReplace>=0
    end
    if form==0
      if idxMoveToReplace>=0
        moveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
        pbMessage(_INTL("{1} forgot {2}...",pkmn.name,moveName))
        pkmn.pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves==0
      end
    else
      newMove = getConst(PBMoves,formMoves[form-1])
      if idxMoveToReplace>=0
        oldMoveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        if newMove && newMove>0
          newMoveName = PBMoves.getName(newMove)
          pkmn.moves[idxMoveToReplace].id = newMove
          pbMessage(_INTL("1,\\wt[16] 2, and\\wt[16]...\\wt[16] ...\\wt[16] ... Ta-da!\\se[Battle ball drop]\1"))
          pbMessage(_INTL("{1} forgot how to use {2}.\\nAnd...\1",pkmn.name,oldMoveName))
          pbMessage(_INTL("\\se[]{1} learned {2}!\\se[Pkmn move learnt]",pkmn.name,newMoveName))
        else
          pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
          pbMessage(_INTL("{1} forgot {2}...",pkmn.name,oldMoveName))
          pkmn.pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves==0
        end
      elsif newMove && newMove>0
        pbLearnMove(pkmn,newMove,true)
      end
    end
  }
})

MultipleForms.register(:GIRATINA,{
  "getForm" => proc { |pkmn|
    maps = [49,50,51,72,73]   # Map IDs for Origin Forme
    if isConst?(pkmn.item,PBItems,:GRISEOUSORB) ||
       maps.include?($game_map.map_id)
      next 1
    end
    next 0
  }
})

MultipleForms.register(:SHAYMIN,{
  "getForm" => proc { |pkmn|
    next 0 if pkmn.fainted? || pkmn.status==PBStatuses::FROZEN ||
              PBDayNight.isNight?
  }
})

MultipleForms.register(:ARCEUS,{
  "getForm" => proc { |pkmn|
    next nil if !isConst?(pkmn.ability,PBAbilities,:MULTITYPE)
    typeArray = {
       1  => [:FISTPLATE,:FIGHTINIUMZ],
       2  => [:SKYPLATE,:FLYINIUMZ],
       3  => [:TOXICPLATE,:POISONIUMZ],
       4  => [:EARTHPLATE,:GROUNDIUMZ],
       5  => [:STONEPLATE,:ROCKIUMZ],
       6  => [:INSECTPLATE,:BUGINIUMZ],
       7  => [:SPOOKYPLATE,:GHOSTIUMZ],
       8  => [:IRONPLATE,:STEELIUMZ],
       10 => [:FLAMEPLATE,:FIRIUMZ],
       11 => [:SPLASHPLATE,:WATERIUMZ],
       12 => [:MEADOWPLATE,:GRASSIUMZ],
       13 => [:ZAPPLATE,:ELECTRIUMZ],
       14 => [:MINDPLATE,:PSYCHIUMZ],
       15 => [:ICICLEPLATE,:ICIUMZ],
       16 => [:DRACOPLATE,:DRAGONIUMZ],
       17 => [:DREADPLATE,:DARKINIUMZ],
       18 => [:PIXIEPLATE,:FAIRIUMZ]
    }
    ret = 0
    typeArray.each do |f, items|
      for i in items
        next if !isConst?(pkmn.item,PBItems,i)
        ret = f
        break
      end
      break if ret>0
    end
    next ret
  }
})

#THUNDAGA ARENAYFORMS
MultipleForms.register(:ARENAY,{
"getForm"=>proc{|pokemon|
   next 1  if isConst?(pokemon.item,PBItems,:FIRECELL)
   next 2  if isConst?(pokemon.item,PBItems,:WATERCELL)
   next 3  if isConst?(pokemon.item,PBItems,:GRASSCELL)
   next 4  if isConst?(pokemon.item,PBItems,:FLYCELL)
   next 5  if isConst?(pokemon.item,PBItems,:STEELCELL)
   next 6  if isConst?(pokemon.item,PBItems,:ELECCELL)
   next 7  if isConst?(pokemon.item,PBItems,:ICECELL)
   next 8  if isConst?(pokemon.item,PBItems,:PSYCELL)
   next 9  if isConst?(pokemon.item,PBItems,:BUGCELL)
   next 10 if isConst?(pokemon.item,PBItems,:GROUNDCELL)
   next 11 if isConst?(pokemon.item,PBItems,:POISONCELL)
   next 12 if isConst?(pokemon.item,PBItems,:DRAGONCELL)
   next 13 if isConst?(pokemon.item,PBItems,:FIGHTCELL)
   next 14 if isConst?(pokemon.item,PBItems,:ROCKCELL)
   next 15 if isConst?(pokemon.item,PBItems,:GHOSTCELL)
   next 16 if isConst?(pokemon.item,PBItems,:DARKCELL)
   next 17 if isConst?(pokemon.item,PBItems,:FAIRYCELL)
   next 0
}
})

MultipleForms.copy(:ARENAY,:DRAGAIA,:PRISMATRIX)

MultipleForms.register(:BASCULIN,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(2)
  }
})

MultipleForms.register(:DARMANITAN,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:DEERLING,{
  "getForm" => proc { |pkmn|
    next pbGetSeason
  }
})

MultipleForms.copy(:DEERLING,:SAWSBUCK)

MultipleForms.register(:KYUREM,{
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next pkmn.form+2 if pkmn.form==1 || pkmn.form==2
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form-2 if pkmn.form>=3   # Fused forms stop glowing
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    case form
    when 0   # Normal
      pkmn.moves.each do |move|
        next if !move
        if (isConst?(move.id,PBMoves,:ICEBURN) ||
           isConst?(move.id,PBMoves,:FREEZESHOCK)) && hasConst?(PBMoves,:GLACIATE)
          move.id = getConst(PBMoves,:GLACIATE)
        end
        if (isConst?(move.id,PBMoves,:FUSIONFLARE) ||
           isConst?(move.id,PBMoves,:FUSIONBOLT)) && hasConst?(PBMoves,:SCARYFACE)
          move.id = getConst(PBMoves,:SCARYFACE)
        end
      end
    when 1   # White
      pkmn.moves.each do |move|
        next if !move
        if isConst?(move.id,PBMoves,:GLACIATE) && hasConst?(PBMoves,:ICEBURN)
          move.id = getConst(PBMoves,:ICEBURN)
        end
        if isConst?(move.id,PBMoves,:SCARYFACE) && hasConst?(PBMoves,:FUSIONFLARE)
          move.id = getConst(PBMoves,:FUSIONFLARE)
        end
      end
    when 2   # Black
      pkmn.moves.each do |move|
        next if !move
        if isConst?(move.id,PBMoves,:GLACIATE) && hasConst?(PBMoves,:FREEZESHOCK)
          move.id = getConst(PBMoves,:FREEZESHOCK)
        end
        if isConst?(move.id,PBMoves,:SCARYFACE) && hasConst?(PBMoves,:FUSIONBOLT)
          move.id = getConst(PBMoves,:FUSIONBOLT)
        end
      end
    end
  }
})

MultipleForms.register(:KELDEO,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasMove?(:SECRETSWORD) # Resolute Form
    next 0                                # Ordinary Form
  }
})

MultipleForms.register(:MELOETTA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:GENESECT,{
  "getForm" => proc { |pkmn|
    next 1 if isConst?(pkmn.item,PBItems,:SHOCKDRIVE)
    next 2 if isConst?(pkmn.item,PBItems,:BURNDRIVE)
    next 3 if isConst?(pkmn.item,PBItems,:CHILLDRIVE)
    next 4 if isConst?(pkmn.item,PBItems,:DOUSEDRIVE)
    next 0
  }
})

MultipleForms.register(:GRENINJA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:SCATTERBUG,{
  "getFormOnCreation" => proc { |pkmn|
    next $Trainer.secretID%18
  }
})

MultipleForms.copy(:SCATTERBUG,:SPEWPA,:VIVILLON)

MultipleForms.register(:FLABEBE,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(5)
  }
})

MultipleForms.copy(:FLABEBE,:FLOETTE,:FLORGES)

MultipleForms.register(:FURFROU,{
  "getForm" => proc { |pkmn|
    if !pkmn.formTime || pbGetTimeNow.to_i>pkmn.formTime.to_i+60*60*24*5   # 5 days
      next 0
    end
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    pkmn.formTime = (form>0) ? pbGetTimeNow.to_i : nil
  }
})

MultipleForms.register(:ESPURR,{
  "getForm" => proc { |pkmn|
    next pkmn.gender
  }
})

MultipleForms.copy(:ESPURR,:MEOWSTIC)

MultipleForms.register(:AEGISLASH,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:PUMPKABOO,{
  "getFormOnCreation" => proc { |pkmn|
    r = rand(100)
    if r<5;     next 3   # Super Size (5%)
    elsif r<20; next 2   # Large (15%)
    elsif r<65; next 1   # Average (45%)
    end
    next 0               # Small (35%)
  }
})

MultipleForms.copy(:PUMPKABOO,:GOURGEIST)

MultipleForms.register(:XERNEAS,{
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next 1
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:ZYGARDE,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form-2 if pkmn.form>=2 && (pkmn.fainted? || endBattle)
  }
})

MultipleForms.register(:HOOPA,{
  "getForm" => proc { |pkmn|
    if !pkmn.formTime || pbGetTimeNow.to_i>pkmn.formTime.to_i+60*60*24*3   # 3 days
      next 0
    end
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    pkmn.formTime = (form>0) ? pbGetTimeNow.to_i : nil
  }
})

MultipleForms.register(:ORICORIO,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(4)   # 0=red, 1=yellow, 2=pink, 3=purple
  },
})

MultipleForms.register(:ROCKRUFF,{
  "getForm" => proc { |pkmn|
    next if pkmn.formSimple>=2   # Own Tempo Rockruff cannot become another form
    next 1 if PBDayNight.isNight?
    next 0
  }
})

MultipleForms.register(:LYCANROC,{
  "getFormOnCreation" => proc { |pkmn|
    next 2 if PBDayNight.isEvening?   # Dusk
    next 1 if PBDayNight.isNight?     # Midnight
    next 0                            # Midday
  },
})

MultipleForms.register(:WISHIWASHI,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:SILVALLY,{
  "getForm" => proc { |pkmn|
    next nil if !isConst?(pkmn.ability,PBAbilities,:RKSSYSTEM)
    typeArray = {
       1  => [:FIGHTINGMEMORY],
       2  => [:FLYINGMEMORY],
       3  => [:POISONMEMORY],
       4  => [:GROUNDMEMORY],
       5  => [:ROCKMEMORY],
       6  => [:BUGMEMORY],
       7  => [:GHOSTMEMORY],
       8  => [:STEELMEMORY],
       10 => [:FIREMEMORY],
       11 => [:WATERMEMORY],
       12 => [:GRASSMEMORY],
       13 => [:ELECTRICMEMORY],
       14 => [:PSYCHICMEMORY],
       15 => [:ICEMEMORY],
       16 => [:DRAGONMEMORY],
       17 => [:DARKMEMORY],
       18 => [:FAIRYMEMORY]
    }
    ret = 0
    typeArray.each do |f, items|
      for i in items
        next if !isConst?(pkmn.item,PBItems,i)
        ret = f
        break
      end
      break if ret>0
    end
    next ret
  }
})

MultipleForms.register(:MINIOR,{
  "getFormOnCreation" => proc { |pkmn|
    next 7+rand(7)   # Meteor forms are 0-6, Core forms are 7-13
  },
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next pkmn.form-7 if pkmn.form>=7 && wild   # Wild Minior always appear in Meteor form
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form+7 if pkmn.form<7
  }
})

MultipleForms.register(:MIMIKYU,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:NECROZMA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    # Fused forms are 1 and 2, Ultra form is 3 or 4 depending on which fusion
    next pkmn.form-2 if pkmn.form>=3 && (pkmn.fainted? || endBattle)
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    next if form>2 || oldForm>2   # Ultra form changes don't affect moveset
    formMoves = [
       :SUNSTEELSTRIKE,   # Dusk Mane (with Solgaleo) (form 1)
       :MOONGEISTBEAM     # Dawn Wings (with Lunala) (form 2)
    ]
    if form==0
      idxMoveToReplace = -1
      pkmn.moves.each_with_index do |move,i|
        next if !move
        formMoves.each do |newMove|
          next if !isConst?(move.id,PBMoves,newMove)
          idxMoveToReplace = i
          break
        end
        break if idxMoveToReplace>=0
      end
      if idxMoveToReplace>=0
        moveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
        pbMessage(_INTL("{1} forgot {2}...",pkmn.name,moveName))
        pkmn.pbLearnMove(:CONFUSION) if pkmn.numMoves==0
      end
    else
      newMove = getConst(PBMoves,formMoves[form-1])
      if newMove && newMove>0
        pbLearnMove(pkmn,newMove,true)
      end
    end
  }
})

#===============================================================================
# Alolan forms
#===============================================================================

# These species don't have visually different Alolan forms, but they need to
# evolve into different forms depending on the location where they evolved.
MultipleForms.register(:PIKACHU,{
  "getForm" => proc { |pkmn|
    next if pkmn.formSimple>=2
    mapPos = pbGetMetadata($game_map.map_id,MetadataMapPosition)
    next 1 if mapPos && mapPos[0]==1   # Tiall region
    next 0
  }
})

MultipleForms.copy(:PIKACHU,:EXEGGCUTE,:CUBONE)

#----------------------
# Stacona Forms
#----------------------
MultipleForms.register(:KLINK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SUNNYDAY,:HYPERBEAM,:RAINDANCE,
                     :THUNDERBOLT,:THUNDER,:FLAMETHROWER,
                     :FIREBLAST,:FLAMECHARGE,:OVERHEAT,
                     :SCALD,:CHARGEBEAM,:INCINERATE,
                     :WILLOWISP,:EXPLOSION,:GIGAIMPACT,
                     :VOLTSWITCH,:THUNDERWAVE,:GYROBALL,
                     :FLASHCANNON,:WILDCHARGE,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:KLINK,:KLANG)

MultipleForms.copy(:KLINK,:KLINKLANG)

MultipleForms.register(:SOLOSIS,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SUNNYDAY,:HYPERBEAM,:RAINDANCE,
                     :THUNDERBOLT,:THUNDER,
                     :CHARGEBEAM,:THUNDERWAVE,:GYROBALL,
                     :FLASHCANNON,:PSYSHOCK,:CALMMIND,
                     :TELEKINESIS,:SOLARBEAM,:PSYCHIC,
                     :SHADOWBALL,:FOCUSBLAST,:ENERGYBALL,
                     :FLASH,:PSYCHUP,:DREAMEATER,:GRASSKNOT,
                     :TRICKROOM,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:SOLOSIS,:DUOSION)
MultipleForms.copy(:SOLOSIS,:REUNICLUS)

MultipleForms.register(:LOTAD,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SUNNYDAY,:RAINDANCE,
                     :GIGAIMPACT,:SOLARBEAM,:ENERGYBALL,
                     :FLASH,:GRASSKNOT,:BULKUP,
                     :BRICKBREAK,:ATTRACT,:ECHOEDVOICE,
                     :FOCUSBLAST,:FALSESWIPE,:SCALD,
                     :QUASH,:SHADOWCLAW,:PAYBACK,
                     :RETALIATE,:SWORDSDANCE,:WORKUP,:SWAGGER,
                     :UTURN,:POISONJAB,:TRICKROOM,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:ICEPUNCH,:THUNDERPUNCH,
                     :FIREPUNCH,:MEGAPUNCH,:MEGAKICK,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:LOTAD,:LOMBRE)
MultipleForms.copy(:LOTAD,:LUDICOLO)

MultipleForms.register(:FOONGUS,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SUNNYDAY,:SOLARBEAM,:ENERGYBALL,
                     :FLASH,:GRASSKNOT,:ATTRACT,:ECHOEDVOICE,
                     :QUASH,:PAYBACK,:PSYCHIC,:SHADOWBALL,:SNARL,
                     :RETALIATE,:SWAGGER,:PSYSHOCK,:VENOSHOCK,
                     :UTURN,:TRICKROOM,
                     :TELEKINESIS,:SLUDGEWAVE,:SLUDGEBOMB,
                     :ALLYSWITCH,:EMBARGO,:RETALIATE,:THUNDERWAVE,:PSYCHUP,
                     :POISONJAB,:DREAMEATER,:SNARL,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:FOONGUS,:AMOONGUSS)

MultipleForms.register(:NOSEPASS,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SANDSTORM,:CALMMIND,:SMACKDOWN,
                     :THUNDERBOLT,:THUNDER,:EARTHQUAKE,
                     :DIG,:PSYCHIC,:ROCKTOMB,:FOCUSBLAST,
                     :CHARGEBEAM,:EMBARGO,:EXPLOSION,:GIGAIMPACT,
                     :ROCKPOLISH,:FLASH,:STONEEDGE,:VOLTSWITCH,
                     :THUNDERWAVE,:GYROBALL,:ROCKSLIDE,:FLASHCANNON,
                     :WILDCHARGE,:TRICKROOM,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:NOSEPASS,:PROBOPASS)

MultipleForms.register(:DUNSPARCE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :DRAGONCLAW,:ROAR,:BULKUP,:DIG,:FLAMETHROWER,
                     :FIREBLAST,:FLAMECHARGE,:FALSESWIPE,:EMBARGO,
                     :SHADOWCLAW,:PAYBACK,:GIGAIMPACT,
                     :SWORDSDANCE,:BULLDOZE,:DRAGONTAIL,:SNARL,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.register(:MAREEP,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs
                     :TOXIC,:HIDDENPOWER,:HYPERBEAM,:THUNDERWAVE,
                     :PROTECT,:RAINDANCE,:SAFEGUARD,:FRUSTRATION,
                     :RETURN,:DOUBLETEAM,:ICEBEAM,:BLIZZARD,
                     :FACADE,:REST,:ATTRACT,:THUNDER,:THUNDERBOLT,
                     :THIEF,:ROUND,:GIGAIMPACT,:FLASH,:FROSTBREATH,
                     :PSYCHUP,:SWAGGER,:SUBSTITUTE,:DAZZLINGGLEAM,
                     :DRAININGKISS,:CALMMIND,:ROAR,:DRAGONCLAW,:HAIL,
                     :PROTECT,:LIGHTSCREEN,:PSYCHIC,:SHADOWBALL,
                     :AERIALACE,:TORMENT,:FALSESWIPE,:CHARGEBEAM,:SHADOWCLAW,
                     :PAYBACK,:FLASH,:VOLTSWITCH,:WILDCHARGE,:PLAYROUGH,
                     :MOONBLAST,:SHOCKWAVE,
                     # Move Tutors
                     :ENDEAVOR,:MUDSLAP,:SIGNALBEAM,:SKILLSWAP,
                     :SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:ICEPUNCH,:THUNDERPUNCH,
                     :MEGAPUNCH,:MEGAKICK,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:MAREEP,:FLAAFFY)
MultipleForms.copy(:MAREEP,:AMPHAROS)

MultipleForms.register(:MAGIKARP,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :THUNDERBOLT,:THUNDERWAVE,:THUNDER,:WILDCHARGE,
                     :SURF,:WATERFALL,:SCALD,:GIGAIMPACT,:ROAR,
                     :SWORDSDANCE,:DRAGONTAIL,:VOLTSWITCH,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:MAGIKARP,:GYARADOS)

MultipleForms.register(:SANDILE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SCALD,:WATERFALL,:SURF,:GIGAIMPACT,
                     :SWORDSDANCE,:SNARL,:SHADOWCLAW,:DRAGONCLAW,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:ICEPUNCH,:THUNDERPUNCH,:FIREPUNCH,
                     :BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:SANDILE,:KROKOROK)
MultipleForms.copy(:SANDILE,:KROOKODILE)

MultipleForms.register(:KRABBY,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SCALD,:SURF,:WATERFALL,:GIGAIMPACT,:FLASHCANNON,
                     :GYROBALL,:SHADOWCLAW,:DRAGONCLAW,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:ICEPUNCH,:THUNDERPUNCH,
                     :MEGAPUNCH,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:KRABBY,:KINGLER)

MultipleForms.register(:SWABLU,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :ROAR,:RAINDANCE,:FLY,:AERIALACE,
                     :ATTRACT,:ECHOEDVOICE,:FALSESWIPE,
                     :SKYDROP,:ACROBATICS,:PAYBACK,:FLASH,
                     :PLUCK,:WILDCHARGE,:DRAININGKISS,:PLAYROUGH,
                     :MOONBLAST,:FAIRYWIND,:DAZZLINGGLEAM,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:SWABLU,:ALTARIA)

MultipleForms.register(:ABSOL,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :FLASHCANNON,:GYROBALL,:GIGAIMPACT,
                     :SHADOWCLAW,:DRAGONCLAW,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:BITE,:MEGAKICK]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.register(:BLITZLE,{
  "getFormOnCreation" => proc { |pkmn|
    maps = [1]   # Map IDs for Origin Forme
    if maps.include?($game_map.map_id)
      next 0
    end
    next 1
  },
  "getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :SUNNYDAY,:HYPERBEAM,:ROAR,
                     :THUNDERBOLT,:THUNDER,:FLAMETHROWER,
                     :FIREBLAST,:FLAMECHARGE,:OVERHEAT,
                     :CHARGEBEAM,:INCINERATE,
                     :WILLOWISP,:GIGAIMPACT,
                     :VOLTSWITCH,:THUNDERWAVE,
                     :WILDCHARGE,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:MEGAKICK,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:BLITZLE,:ZEBSTRIKA)

MultipleForms.register(:PICHU,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[91]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :GYROBALL,:ROAR,:THUNDERBOLT,:THUNDER,
                     :CHARGEBEAM,:GIGAIMPACT,
                     :VOLTSWITCH,:THUNDERWAVE,
                     :WILDCHARGE,:FLASHCANNON,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:THUNDERPUNCH,:FIREPUNCH,
                     :MEGAPUNCH,:MEGAKICK,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:PICHU,:PIKACHU)
MultipleForms.copy(:PICHU,:RAICHU)

MultipleForms.register(:ELEKID,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[0]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs generic
                     :TOXIC,:HIDDENPOWER,:TAUNT,
                     :HYPERBEAM,:LIGHTSCREEN,:PROTECT,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,
                     :DOUBLETEAM,:REFLECT,:TORMENT,:FACADE,
                     :REST,:THIEF,:ROUND,:FLING,:SUBSTITUTE,
                     # TMs specific
                     :BRICKBREAK,:ROAR,:THUNDERBOLT,:THUNDER,
                     :CHARGEBEAM,:GIGAIMPACT,
                     :VOLTSWITCH,:THUNDERWAVE,
                     :WILDCHARGE,:ROCKSMASH,:POISONJAB,
                     # Move Tutors
                     :ENDEAVOR,:SKILLSWAP,:SLEEPTALK,:SNORE,
                     :SUCKERPUNCH,:UPROAR,:THUNDERPUNCH,:FIREPUNCH,:ICEPUNCH,
                     :MEGAPUNCH,:MEGAKICK,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:ELEKID,:ELECTABUZZ)
MultipleForms.copy(:ELEKID,:ELECTIVIRE)

MultipleForms.register(:TRAPINCH,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# TMs
                     :TOXIC,:HIDDENPOWER,:HYPERBEAM,
                     :PROTECT,:SAFEGUARD,:FRUSTRATION,
                     :RETURN,:DOUBLETEAM,:DRAGONCLAW,:ROAR,:BULKUP,
                     :VENOSHOCK,:TAUNT,:HYPERBEAM,:PROTECT,:EARTHQUAKE,
                     :DIG,:BRICKBREAK,:REFLECT,:SLUDGEWAVE,:FLAMETHROWER,
                     :SLUDGEBOMB,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:AERIALACE,
                     :TORMENT,:FACADE,:FLAMECHARGE,:REST,:ATTRACT,:THIEF,
                     :ROUND,:ECHOEDVOICE,:OVERHEAT,:FALSESWIPE,:FLING,
                     :QUASH,:EMBARGO,:SHADOWCLAW,:PAYBACK,:RETALIATE,
                     :GIGAIMPACT,:STONEEDGE,:SWORDSDANCE,:BULLDOZE,:XSCISSOR,
                     :DRAGONTAIL,:WORKUP,:POISONJAB,:SWAGGER,:UTURN,
                     :SUBSTITUTE,:WILDCHARGE,:SNARL,:CUT,:STRENGTH,
                     # Move Tutors
                     :ENDEAVOR,:MUDSLAP,:SKILLSWAP,
                     :SLEEPTALK,:SNORE,:SUCKERPUNCH,:UPROAR,
                     :MEGAKICK,:BITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

MultipleForms.copy(:TRAPINCH,:VIBRAVA)
MultipleForms.copy(:TRAPINCH,:FLYGON)

MultipleForms.register(:SLOWPOKE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})

MultipleForms.copy(:SLOWPOKE,:SLOWBRO)
MultipleForms.copy(:SLOWPOKE,:SLOWKING)

MultipleForms.register(:HOPPIP,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]   # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})

MultipleForms.copy(:HOPPIP,:SKIPLOOM)
MultipleForms.copy(:HOPPIP,:JUMPLUFF)

MultipleForms.register(:CUBONE,{
  "getForm" => proc { |pkmn|
    maps=[151,152,153,154]   # Map IDs for alola form
    if PBDayNight.isNight? || $game_map && maps.include?($game_map.map_id) # if night or in haunted map, evolve cubone to alola form
      next 1
    else
      next 0
    end
  }
})

MultipleForms.register(:MAROWAK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[151,152,153,154]   # Map IDs for alola form to appear
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
}
})

MultipleForms.register(:SINISTEA,{
"getFormOnCreation"=>proc{|pokemon|
   if rand(99) == 1 # 1/100 odds for authenticity
     next 1
   else
     next 0
   end
}
})

MultipleForms.register(:SUNKERN,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})
MultipleForms.copy(:SUNKERN,:SUNFLORA)

MultipleForms.register(:SPINARAK,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})
MultipleForms.copy(:SPINARAK,:ARIADOS)

MultipleForms.register(:NATU,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})
MultipleForms.copy(:NATU,:XATU)

MultipleForms.register(:TYROGUE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})
MultipleForms.copy(:TYROGUE,:HITMONCHAN,:HITMONLEE,:HITMONTOP)
