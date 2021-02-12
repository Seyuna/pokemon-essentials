class GameQuest
  attr_accessor :id
  attr_accessor :name
  attr_accessor :description

  def initialize (id, name, description)
    @id = id
    @name = name
    @description = description
  end
end

class GameQuests
  attr_accessor :allquests


end