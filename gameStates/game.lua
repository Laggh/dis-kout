local thisState = {}

local disc = {
    x = 90,
    y = 160,
    angle = 0,
    speed = 0,
    isFirstImpact = false,
}
local particles = {}
local touchingScreen = false

function createSingleParticle(_X,_Y,_Dir,_Speed,_Life,_DeathTime)
    local particle = {}
    particle.x = _X
    particle.y = _Y
    particle.dir = _Dir
    particle.speed = _Speed*(0.5 + love.math.random())
    particle.life = _Life
    particle.deathTime = _DeathTime
    table.insert(particles,particle)
end
function createParticles(_Amount,_X,_Y,_Dir,_Spread,_Speed,_Life,_DeathTime)
    _Dir = _Dir or math.random()*2*math.pi
    _Spread = _Spread or math.pi/4
    _Speed = _Speed or 1
    _Life = _Life or 60
    _DeathTime = _DeathTime or 15

    for i=1,_Amount do
        local dir = _Dir + love.math.random()*_Spread - _Spread/2
        createSingleParticle(_X,_Y,dir,_Speed,_Life,_DeathTime)
    end
end
function runParticles(timeScale)
    timeScale = timeScale or 1
    for i,v in ipairs(particles) do
        v.x = v.x + math.cos(v.dir)*v.speed*timeScale
        v.y = v.y + math.sin(v.dir)*v.speed*timeScale
        v.life = v.life - 1*timeScale
        if v.life <= -v.deathTime then
            table.remove(particles,i)
        end
    end
end
function drawParticles()
    for i,v in ipairs(particles) do
        local size = 2
        if v.life < 0 then size = 2 + (v.life/v.deathTime) end
        love.graphics.rectangle("fill",
            v.x-size/2,
            v.y-size/2,
            size,
            size)
    end
end

function runDisc(timeScale)
    timeScale = timeScale or 1
    if disc.angle > math.pi then disc.angle = disc.angle - 2*math.pi end
    if disc.angle < -math.pi then disc.angle = disc.angle + 2*math.pi end

    disc.x = disc.x + math.cos(disc.angle)*disc.speed*timeScale
    disc.y = disc.y + math.sin(disc.angle)*disc.speed*timeScale

    local function handleImpact(wallAngle)

        local dot = math.angleDotProduct(disc.angle, wallAngle)
        if dot > 0 then return end

        disc.angle = math.reflectAngle(disc.angle, wallAngle)
        disc.speed = disc.speed*0.9



        local x = disc.x - math.cos(wallAngle)*12
        local y = disc.y - math.sin(wallAngle)*12
        local impactForce = math.min(disc.speed*20,5)
        local dir = wallAngle
        local spread = math.pi
        local speed = 1
        local life = 30
        local deathTime = 15
        if disc.isFirstImpact then
            impactForce = impactForce^2
            speed = 1.5
            deathTime = 30
            disc.isFirstImpact = false
        end
        createParticles(impactForce,x,y,dir,spread,speed,life,deathTime)
    end


    -- Colisões com as bordas
    if disc.x < 16 then -- Esquerd
        disc.x = 16 + 2
        handleImpact(0)

    end
    if disc.x > 180 - 16 then -- Direita
        disc.x = 180 - 16 - 2
        handleImpact(math.pi)
    end
    if disc.y < 16 then -- Topo
        disc.y = 16 + 2
        handleImpact(math.pi/2)
    end
    if disc.y > 320 - 16 then -- Baixo
        disc.y = 320 - 16 - 2
        handleImpact(-math.pi/2)
    end

    -- Redução de velocidade
    disc.speed = disc.speed*0.99
    disc.speed = math.max(0, disc.speed)
end

function launchDisc(_Angle,_Speed)
    disc.isFirstImpact = true
    disc.angle = _Angle
    disc.speed = _Speed

    disc.x = disc.x + math.cos(disc.angle)*disc.speed*3
    disc.y = disc.y + math.sin(disc.angle)*disc.speed*3
end

function thisState.load()
    launchDisc(math.pi/4,0)
end

function thisState.update(_Dt)
    local timeScale
    if touchingScreen then
        timeScale = 0.2
    else
        timeScale = 1
    end

    runParticles(timeScale)
    runDisc(timeScale)
end

function drawDisc()
    local x = disc.x
    local y = disc.y
    local r = disc.angle
    local sx,sy = 2,2
    drawCentered(img.disc,x,y,r,sx,sy) 

    withColor(1,0,0,0.1,function()
        love.graphics.circle("line",x,y,48)
        love.graphics.line(
            x,
            y,
            x + math.cos(disc.angle)*disc.speed*3,
            y + math.sin(disc.angle)*disc.speed*3
        )
        love.graphics.circle("fill",
            x + math.cos(disc.angle)*disc.speed*3,
            y + math.sin(disc.angle)*disc.speed*3,
            3
        )
    end)


end
function drawDiscLine()
    local mx,my = screenLib.getMousePosition()


    for i = 1,10 do
        local x,y = math.interpolateTwo(
            disc.x, disc.y,
            mx, my,
            i/10
        )
        local size = math.interpolateLinear(4,1, i/10)    
    

        love.graphics.rectangle("fill",x,y,size,size)
    end
end
function thisState.draw()
    screenLib.setScreen(180,320)
    love.graphics.rectangle("line",0,0,180,320)


    drawParticles()
    if touchingScreen then
        drawDiscLine()
    end
    drawDisc()

    local speed,x,y,angle = disc.speed, disc.x, disc.y, disc.angle
    local touching = touchingScreen
    local f = string.format
    local infoText = string.interpolate(
        "Speed: ${speed}\nX: ${x}\nY: ${y}\nAngle: ${angle}\n${touchingText}",
        {
            speed = f("%.2f",speed),
            x = f("%.2f",x),
            y = f("%.2f",y),
            angle = f("%.2f",angle),
            touchingText = touching and "Touching Screen" or "Not Touching Screen",
        }
    )
    love.graphics.printf(infoText, 10, 10, 160, "left")
end


function thisState.mousepressed()

    local x,y = screenLib.getMousePosition()

    if collision.pointInCircle(
        x,y,
        disc.x,disc.y,
        48) then
        print("tocou no disco")
        touchingScreen = true
    end 


end

function thisState.mousereleased()
    if not touchingScreen then return end
    local mx,my = screenLib.getMousePosition()
    local angle,dist = math.getAngleDistance( --Invertido para ter o efeito de "puxar"
        mx,my,
        disc.x,disc.y
    )

    if dist > 50 then
        local launchSpeed = setLimits(dist/10, 5, 20)
        launchDisc(angle,launchSpeed)
    end
    touchingScreen = false
    

end



return thisState