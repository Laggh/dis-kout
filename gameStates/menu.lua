local thisState = {}

function thisState.load()
    
end

function thisState.update(_Dt)

end

function thisState.draw()
    love.graphics.print("Menu",200,200)
end

function thisState.mousePressed()
    changeGameState("game")
end




return thisState