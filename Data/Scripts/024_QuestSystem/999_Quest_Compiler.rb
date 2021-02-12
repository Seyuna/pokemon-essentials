def pbCompileQuestData
  linecount = 0
  currentquest = 0
  quests = []
  requiredinformation = QuestData.requiredValues

  name = ""
  description = ""

  pbCompilerEachCommentedLine("PBS/" + QUEST_PBS_FILE_NAME) do |line,lineno|
    linecount += 1
    if line[/^\s*\[\s*(\d+)\s*\]\s*$/]
      if currentquest > 0
        quests.push(GameQuest.new(currentquest, name, description))

        name = ""
        description = ""
      end
      sectionname = $~[1]
      currentquest = sectionname.to_i
    else

      if !line[/^\s*(\w+)\s*=\s*(.*)$/]
        raise _INTL('ASDF')
      end
      matchdata = $~
      schema = nil
      FileLineData.setSection(currentquest,matchdata[1],matchdata[2])
      schema = requiredinformation[matchdata[1]]
      schemavalues = schema[1]
      if schema
        schemavalues = schema[1].split('|')
      end

      if schema
        for i in 0...schemavalues.length
          schema[1] = schemavalues[i]
          record = pbGetCsvRecord(matchdata[2], lineno, schema) rescue next
          case schema
          when requiredinformation[QuestName]
            name = record
            break
          when requiredinformation[QuestDescription]
            description = record
            break
          end
        end
      end
    end
  end
  quests.push(GameQuest.new(currentquest,name,description))
  save_data(quests, "Data/" + QUEST_RXDATA_FILE_NAME)
end

def pbLoadQuests

end