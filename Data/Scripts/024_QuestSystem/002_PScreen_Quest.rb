class PokemonQuestScene 
    def update
        pbUpdateSpriteHash(@sprites)
    end

    def pbStartScene
        @sprites = {}
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z=1000
        @sprites["background"]=IconSprite.new(0,0,@viewport)
        @sprites["background"].setBitmap(QUEST_GRAPHICS_PATH + "bg")
        @selarrow = AnimatedBitmap.new("Graphics/Pictures/Quests/cursor")
        @quests = $game_variables[ALL_PLAYER_QUEST_VARIABLE]

        p @quests


        pbSetSystemFont(@sprites["background"].bitmap)

        pbDrawInterface
        if @quests != 0
            drawCursor
            pbDrawQuestNames
        end

    end

    def drawCursor
        bmp = @selarrow.bitmap
        bitmap = @sprites["background"].bitmap
        pbCopyBitmap(bitmap,bmp,33,71 + ((mkxp? && $PokemonSystem.font) ? -3 : 0))
    end

    def pbMain
        loop do
            Graphics.update
            Input.update
            self.update
            if Input.trigger?(Input::B)
                pbPlayCloseMenuSE
                break
            end
        end
    end

    def pbDrawInterface
        overlay = @sprites["background"].bitmap
        basecolor = Color.new(248,248,248)
        shadowcolor = Color.new(104,104,104)

        textpos = []

        textpos.push([_INTL("Quests"), 25, 18, 0, basecolor, shadowcolor])

        if @quests == 0
            textpos.push([_INTL("You currently have no quests"), 99, 73, 0, basecolor, shadowcolor])
        end

        pbDrawTextPositions(overlay, textpos)
    end

    def pbDrawQuestNames
        overlay = @sprites["background"].bitmap
        textpos = []
        basecolor = Color.new(248,248,248)
        shadowcolor = Color.new(104,104,104)
        for i in 0...@quests.length
            textpos.push([_INTL(@quests[i].name), 65, 71, 0, basecolor, shadowcolor])
        end
        pbDrawTextPositions(overlay, textpos)
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites) { update }
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
    end
end

class QuestScreen
    def initialize(scene)
        @scene=scene
    end

    def pbStartScreen
        @scene.pbStartScene
        @scene.pbMain
        @scene.pbEndScene
    end
end
