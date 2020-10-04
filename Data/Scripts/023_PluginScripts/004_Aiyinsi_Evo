def evolvePokemonSilent(pokemon)
  newspecies=pbCheckEvolution(pokemon)
  if newspecies == -1
    return pokemon
  end
  newspeciesname=PBSpecies.getName(newspecies)
  oldspeciesname = pokemon.name
  pokemon.species=newspecies
  pokemon.name=newspeciesname if pokemon.name==oldspeciesname
  pokemon.calcStats
  pokemon.resetMoves
  return pokemon
end
