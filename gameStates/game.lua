local thisState = {}

local disc = {}
local objects = {}

local particles = {}
local touchingScreen = false

function thisState.load()
    -- Variaveis iniciais
    objects = {spikes={},coins={},bumpers={}}
    createBumper(50,50)
    createBumper(130,80)
    createBumper(90,200)
    createBumper(60,250)
    --createCoin(50,100)
    --createSpike(20,20)
    disc = {
        x = 90,
        y = 160,
        angle = 0,
        speed = 0,
        isFirstImpact = false,
    }
    launchDisc(math.pi/4,0)
end

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

function runDisc(_TimeScale)
    local timeScale = _TimeScale or 1
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


    --#region Colisões com as paredes
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
    --#endregion

    for i,v in ipairs(objects.coins) do
        if collision.circleCircle(
            disc.x,disc.y,16,
            v.x,v.y,8
        ) then
            --table.remove(objects.coins,i)
            v.x = math.random(16,180-16)
            v.y = math.random(16,320-16)
            print("moeda")
        end
    end

    for i,v in ipairs(objects.spikes) do
        if collision.circleCircle(
            disc.x,disc.y,16,
            v.x,v.y,8
        ) then
            print("spike")
            changeGameState("menu")
        end
    end

    for i,v in ipairs(objects.bumpers) do
        if collision.circleRectangle(
            disc.x,disc.y,16,
            v.x-16,v.y-16,32,32
        ) then
            if disc.speed > 10 then --destroir se rapido demais
                createParticles(20,v.x,v.y,0,2*math.pi,2,15,15) 
                table.remove(objects.bumpers,i)
                print("bumper destruido")
            else
                v.tSinceLastHit = 0
                handleImpact(math.getAngle(
                    v.x,v.y,
                    disc.x,disc.y
                ))
            end
        end
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
function createCoin(_X,_Y)
    local coin = {}
    coin.x = _X or math.random(16,180-16)
    coin.y = _Y or math.random(16,320-16)
    coin.t = 0
    table.insert(objects.coins,coin)
end
function createBumper(_X,_Y)
    local bumper = {}
    bumper.x = _X or math.random(16,180-16)
    bumper.y = _Y or math.random(16,320-16)
    bumper.t = 0
    bumper.tSinceLastHit = 0
    table.insert(objects.bumpers,bumper)
end
function createSpike(_X,_Y)
    local spike = {}
    spike.x = _X or math.random(16,180-16)
    spike.y = _Y or math.random(16,320-16)
    spike.t = 0
    table.insert(objects.spikes,spike)
end

function runObjects(_TimeScale)
    local timeScale = _TimeScale or 1
    
    for i,v in ipairs(objects.coins) do
        v.t = v.t + 1*timeScale
    end
    for i,v in ipairs(objects.bumpers) do
        v.t = v.t + 1*timeScale
        v.tSinceLastHit = v.tSinceLastHit + 1*timeScale
    end
    for i,v in ipairs(objects.spikes) do
        v.t = v.t + 1*timeScale
    end

end

function thisState.update(_Dt)
    local timeScale
    if touchingScreen then
        timeScale = 0.2
    else
        timeScale = 1
    end

    runObjects(timeScale)
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
function drawCoin(_Coin)
    local x = _Coin.x
    local y = _Coin.y
    local r = 0
    local sx,sy = 2,2
    withColor(1,1,0,1, function()
        drawCentered(img.coin,x,y,r,sx,sy) 
    end)
end
function drawBumper(_Bumper)
    local x = _Bumper.x
    local y = _Bumper.y
    local r = 0
    local scale = 1
    if _Bumper.tSinceLastHit < 1 then
        scale = 0.9 + (_Bumper.tSinceLastHit*0.15)
    end
    local sx,sy = scale*2,scale*2
    withColor(1,1,1,1, function()
        drawCentered(img.bumper,x,y,r,sx,sy) 
    end)
end

function drawSpike(_Spike)
    local x = _Spike.x
    local y = _Spike.y
    local r = 0
    local sx,sy = 2,2
    withColor(1,0,0,1, function()
        drawCentered(img.spike,x,y,r,sx,sy) 
    end)
end
function drawObjetcts()
    local function _drawTableWithFunction(_Tab,_Func)
        for i,v in ipairs(_Tab) do
            _Func(v)
        end
    end

    _drawTableWithFunction(objects.coins,drawCoin)
    _drawTableWithFunction(objects.bumpers,drawBumper)
    _drawTableWithFunction(objects.spikes,drawSpike)
end
function thisState.draw()
    screenLib.setScreen(180,320)
    love.graphics.rectangle("line",0,0,180,320)


    drawParticles()
    if touchingScreen then
        drawDiscLine()
    end
    drawDisc()
    drawObjetcts()


    -- mostra info do bumper[1]
    local f = string.format
    infoText = disc.speed




    love.graphics.printf(infoText, 10, 10, 160, "left")
end


function thisState.mousepressed()

    --createParticles(100,50,50,0,2*math.pi,2,15,15)


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
        print(dist/10)
        local launchSpeed = setLimits(dist/10, 5, 12)
        launchDisc(angle,launchSpeed)
    end
    touchingScreen = false
    

end





return thisState