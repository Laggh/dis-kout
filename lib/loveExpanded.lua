-- FUNCTIONS

---Interpolates a string with the given arguments.
---@param _Str string
---@param _Args table
---@return string
function string.interpolate(_Str,_Args)
    return (_Str:gsub('($%b{})', function(w) return _Args[w:sub(3, -2)] or w end))
end

---Clamps a value between a minimum and maximum value.
---@param _Value number
---@param _Min number
---@param _Max number
---@return number
function setLimits(_Value,_Min,_Max)
    if _Value < _Min then return _Min end
    if _Value > _Max then return _Max end
    return _Value
end

---Checks if a value is within a specified range.
---@param _Value number
---@param _Min number
---@param _Max number
---@return boolean
function inLimits(_Value,_Min,_Max)
    if _Value < _Min then return false end
    if _Value > _Max then return false end
    return true
end

---Joins multiple values into a single string.
---@vararg any
---@return string
function strJoin(...)
    local args = {...}
    return table.concat(args)
end

---Draws an image centered at the given coordinates.
---@param _Draw any
---@param _X number
---@param _Y number
---@param _R number
---@param _Sx number
---@param _Sy number
function drawCentered(_Draw, _X, _Y, _R, _Sx , _Sy)
    local width, height = _Draw:getDimensions()
    love.graphics.draw(_Draw, _X, _Y, _R, _Sx, _Sy ,width/2, height/2)
end

---Isolates a color inside a function
---@param _R number
---@param _G number
---@param _B number
---@param _A number
---@param _Function function
function withColor(_R,_G,_B,_A,_Function)
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(_R,_G,_B,_A)
    _Function()
    love.graphics.setColor(r,g,b,a)
end

---Reflects and angle over a normal angle
---@param _Angle number
---@param _Normal number
---@return number
---@diagnostic disable-next-line: duplicate-set-field
function math.reflectAngle(_Angle,_Normal)
    return _Normal - (_Angle - _Normal) + math.pi
end

---Gets the dot product of two Angles
---@param _A1 number
---@param _A2 number
---@return number
function math.angleDotProduct(_A1,_A2)
    return math.cos(_A1 - _A2)
end

---Gets the angle difference of 2 points
---@param _X1 number
---@param _Y1 number
---@param _X2 number
---@param _Y2 number
---@return number angle
function math.getAngle(_X1,_Y1,_X2,_Y2)
    _X2,_Y2 = _X2 or 0,_Y2 or 0
    return math.atan2(_Y2-_Y1,_X2-_X1)
end

---Gets the distance between 2 points
---@param _X1 number
---@param _Y1 number
---@param _X2 number
---@param _Y2 number
---@return number distance
function math.getDistance(_X1,_Y1,_X2,_Y2)
    return math.sqrt((_X2-_X1)^2 + (_Y2-_Y1)^2)
end

---Gets the angle and distance between 2 points
---@param _X1 number
---@param _Y1 number
---@param _X2 number
---@param _Y2 number
---@return number angle
---@return number distance
function math.getAngleDistance(_X1,_Y1,_X2,_Y2)
    return math.getAngle(_X1,_Y1,_X2,_Y2), math.getDistance(_X1,_Y1,_X2,_Y2)
end
---Interpolates number with linear method
---@param _A number
---@param _B number
---@param _T number
---@return number
function math.interpolateLinear(_A,_B,_T)
    return _A + (_B - _A) * _T
end

---Interpolates multiple numbers with linear method
function math.interpolateTwo(_A1,_A2,_B1,_B2,_T)
    return math.interpolateLinear(_A1,_B1,_T),math.interpolateLinear(_A2,_B2,_T)
end

collision = {}
---Checks if a point is inside a rectangle
---@param _X1 number
---@param _Y1 number
---@param _X2 number
---@param _Y2 number
---@param _W number
---@param _H number
---@return boolean
function collision.pointInRectangle(_X1,_Y1,_X2,_Y2,_W,_H)
    return _X1 > _X2 and _X1 < _X2 + _W and _Y1 > _Y2 and _Y1 < _Y2 + _H
end

---Checks if two rectangles intersect
---@param _X1 number
---@param _Y1 number
---@param _W1 number
---@param _H1 number
---@param _X2 number
---@param _Y2 number
---@param _W2 number
---@param _H2 number
---@return boolean
function collision.rectangleRectangle(_X1,_Y1,_W1,_H1,_X2,_Y2,_W2,_H2)
    return _X1 < _X2 + _W2 and
           _X2 < _X1 + _W1 and
           _Y1 < _Y2 + _H2 and
           _Y2 < _Y1 + _H1
end

---Checks if a point is inside a circle
---@param _X1 number
---@param _Y1 number
---@param _X2 number
---@param _Y2 number
---@param _R number
---@return boolean
function collision.pointInCircle(_X1,_Y1,_X2,_Y2,_R)
    return math.getDistance(_X1,_Y1,_X2,_Y2) < _R
end

---Checks if two circles intersect
---@param _X1 number
---@param _Y1 number
---@param _R1 number
---@param _X2 number
---@param _Y2 number
---@param _R2 number
---@return boolean
function collision.circleCircle(_X1,_Y1,_R1,_X2,_Y2,_R2)
    return math.getDistance(_X1,_Y1,_X2,_Y2) < _R1 + _R2
end

---Checks if a circle is intersecting a rectangle
---@param _CX number
---@param _CY number
---@param _CR number
---@param _RX number
---@param _RY number
---@param _RW number
---@param _RH number
---@return boolean
function collision.circleRectangle(_CX,_CY,_CR,_RX,_RY,_RW,_RH)
    local closestX = setLimits(_CX, _RX, _RX + _RW)
    local closestY = setLimits(_CY, _RY, _RY + _RH)
    return collision.pointInCircle(closestX, closestY, _CX, _CY, _CR)
end

local function loadAllThings(_Path)
    local loaded = {}
    for i,v in pairs(love.filesystem.getDirectoryItems(_Path)) do
        -- if it is a directory
        local isDirectory = false
        if love.filesystem.getInfo then
            isDirectory = love.filesystem.getInfo(_Path.."/"..v, "directory") ~= nil
        else
            isDirectory = love.filesystem.isDirectory(_Path.."/"..v)
        end

        if isDirectory then
            loaded[v] = {}
            for ii,vv in pairs(love.filesystem.getDirectoryItems(_Path .. "/" .. v)) do
                local imgName = string.sub(vv, 1, -5)
                loaded[v][imgName] = love.graphics.newImage(strJoin(_Path, "/", v, "/", vv))
            end
        else -- if it is a file
            local imgName = string.sub(v, 1, -5)
            loaded[imgName] = love.graphics.newImage(_Path .. "/" .. v)
        end
    end
    return loaded
end
---Prints things
function printm(...)
    local separator = " "
    local args = {...}
    local str = table.concat(args,separator)
    print(str)
end


--LOADING FILES

img = {}
img = loadAllThings("img")

sfx = {}
sfx = loadAllThings("sfx")

font = {}
font = {
    small = love.graphics.newFont(12),
    medium = love.graphics.newFont(24),
    big = love.graphics.newFont(48),
    monospace = {
        small = love.graphics.newFont("fonts/monospaced.ttf", 12),
        medium = love.graphics.newFont("fonts/monospaced.ttf", 24),
        big = love.graphics.newFont("fonts/monospaced.ttf", 48)
    }
}

print(json.encode(img))


