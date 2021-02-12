class PlayerQuest
    attr_accessor :id
    attr_accessor :name
    attr_accessor :stage
    attr_accessor :completed

    def initialize(id,name)
        @id = id
        @name = name
        @stage = 1
        @completed = false
    end
end

# Gives the player a quest with a specific id
def pbGiveQuest(id)
    allquests = $game_variables[ALL_PLAYER_QUEST_VARIABLE]

    quest = PlayerQuest.new(id, "Quest name")

    if allquests.kind_of?(Array)
        allquests.push(quest)
    else
        allquests = [quest]
    end

    $game_variables[ALL_PLAYER_QUEST_VARIABLE] = allquests
end

# Opens quest overview with all active quests
def pbViewQuests
    scene = PokemonQuestScene.new
    screen = QuestScreen.new(scene)
    screen.pbStartScreen
end

def pbGetQuestName(id)
    p PBQuests.maxValue
end