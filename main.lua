io.stdout:setvbuf("no")
local bit = require("bit")
local utf8 = require("utf8")

--local tohex = bit.tohex
--require("mobdebug").start()

--local font = love.graphics.newFont("Vazir-FD-WOL.ttf",44)
local font = love.graphics.newFont("tahoma.ttf",22)
local persianText = "حرف a اولین حرف در زبان انگلیسی است."
persianText = "حروف گ و چ و پ و ژ در زبان عربی وجود ندارند" .. "\n" .. persianText

local varientsCount = {1,2,2,2,2, 4,2,4,2,4, 4,4,4,4,2, 2,2,2,4,4, 4,4,4,4,4,4, 4,4,4,4,4, 4,4,2,2,4, 4,4,2,4,4, 4}
local persianLettersHex = {[0x067E] = 0xFB56, [0x0686] = 0xFB7A, [0x0698] = 0xFB8A, [0x06A9] = 0xFB8E, [0x06AF] = 0xFB92, [0x06CC] = 0xFBFC}

local varientPos = 1
local nextVarient = 0xFE80
local connectableCharacters = {}
for i=0x0621, 0x064A do -- 1569 1610
  if i <= 0x063A or i >= 0x0641 then
    local char = utf8.char(i)
    local varients = {}
    for n=1,varientsCount[varientPos] do
      varients[n] = utf8.char(nextVarient)
      nextVarient = nextVarient + 1
    end
    varientPos = varientPos + 1
    connectableCharacters[char] = varients
  end
end

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end


for i,nextVarient in pairsByKeys(persianLettersHex) do
    char = utf8.char(i)
    varients = {}
    for n=1,varientsCount[varientPos] do
      varients[n] = utf8.char(nextVarient)
      nextVarient = nextVarient + 1
    end
    varientPos = varientPos + 1
    connectableCharacters[char] = varients
end



local function processPersian(text)
  
  local length = utf8.len(text)
  local proc1 = {}
  local iter1 = string.gmatch(text,utf8.charpattern)
  local iter2 = string.gmatch(text,utf8.charpattern)
  local prevChar, nextChar = " ", " "
  iter2()
  
  for char in iter1 do
    local codepoint = utf8.codepoint(char)
    if codepoint <= 0x064A or codepoint >= 0x065E then
      while true do
        nextChar = iter2() or " "
        local nextCodepoint = utf8.codepoint(nextChar)
        if nextCodepoint <= 0x064A or nextCodepoint >= 0x065E then
          break
        end
      end
    end
    local prevVars = connectableCharacters[prevChar] or {}
    local curVars = connectableCharacters[char] or {}
    local nextVars = connectableCharacters[nextChar] or {}
    
    local backC = (#prevVars == 4)
    local nextC = (#nextVars >= 2)
    local prevCan = (#curVars == 4)
    local result = char
    if #curVars > 1 then
      if backC and nextC and prevCan then
        result = curVars[4]
      elseif nextC and prevCan then
        result = curVars[3]
      elseif backC then
        result = curVars[2]
      else
        result = curVars[1]
      end
    end
    if codepoint <= 0x064A or codepoint >= 0x065E then
      prevChar = char
    end
    proc1[#proc1 + 1] = result
  end
  text = table.concat(proc1)
  local procrev = {}
  local revpos = length
  for char in string.gmatch(text,utf8.charpattern) do
    procrev[revpos] = char
    revpos = revpos-1
  end
  
  return table.concat(procrev)
end


function love.load()
  love.window.setMode(800, 600, {resizable=true, vsync=false, minwidth=400, minheight=300})
  love.graphics.setFont(font)
  persianText = processPersian(persianText)
  
end

function love.draw()
  love.graphics.setColor(1,1,1,1)
  
  local gwidth = love.graphics.getWidth()
  local gheight = love.graphics.getHeight()
  local strwidth = font:getWidth(persianText)
  love.graphics.print(persianText, gwidth/2, gheight/2, 0, 1, 1, math.floor(strwidth/2), math.floor(font:getHeight()/2))
end