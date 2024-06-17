-- sdk libs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics

-- local libs
import "../playout.lua"

fonts = {
  normal = gfx.getSystemFont(gfx.font.kVariantNormal),
  bold = gfx.getSystemFont(gfx.font.kVariantBold)
}

local button = {
  padding = 4,
  paddingLeft = 16,
  borderRadius = 12,
  border = 2,
  shadow = 3,
  shadowAlpha = 1/4,
  backgroundColor = gfx.kColorWhite,
  font = fonts.bold
}

local buttonHover = {
  padding = 4,
  paddingLeft = 16,
  borderRadius = 12,
  border = 2,
  shadow = 3,
  shadowAlpha = 1/4,
  backgroundColor = gfx.kColorWhite,
  backgroundAlpha = 1/2,
  font = fonts.bold,
  paddingBottom = 5,
  shadow = 5,
}

local menu = nil
local menuImg, menuSprite, menuTimer
local selectedIndex = 1

local pointer
local pointerPos = nil
local pointerTimer

local logo = gfx.image.new("images/play.png")

local selected

local function setPointerPos()
  selected = menu.tabIndex[selectedIndex]
  local menuRect = menuSprite:getBoundsRect()

  pointerPos = getRectAnchor(selected.rect, playout.kAnchorCenterLeft):
    offsetBy(getRectAnchor(menuRect, playout.kAnchorTopLeft):unpack())  
end

local function nextMenuItem()
  selectedIndex = selectedIndex + 1
  if selectedIndex > #menu.tabIndex then
    selectedIndex = 1
  end
  setPointerPos()
end

local function prevMenuItem()
  selectedIndex = selectedIndex - 1
  if selectedIndex < 1 then
    selectedIndex = #menu.tabIndex
  end
  setPointerPos()
end

local function createMenu(ui)
  local box = ui.box
  local image = ui.image
  local text = ui.text

  plattdeutschWort = "*" .. redewendungen[1]["plattdeutsch"] .. "*"
  hochdeutschWort = redewendungen[1]["hochdeutsch"]

  return box({
    maxWidth = 400,
    backgroundColor = gfx.kColorWhite,
    borderRadius = 9,
    border = 2,
    direction = playout.kDirectionHorizontal,
    shadow = 4,
    shadowAlpha = 1/3
  }, {
    box({
      margin = 12,
      spacing = 10,
      backgroundColor = gfx.kColorBlack,
      backgroundAlpha = 7/8,
      borderRadius = 100,
      border = 2
    }, { image(logo, { id = "furzbedeinten", tabIndex = 1 }) }),
    box({
      spacing = 12,
      paddingTop = 16,
      paddingLeft = 20,
      hAlign = playout.kAlignStart
    }, {
      text(plattdeutschWort),
      text(hochdeutschWort)
    })
  })
end

local inputHandlers = {
  rightButtonDown = nextMenuItem,
  downButtonDown = nextMenuItem,
  leftButtonDown = prevMenuItem,
  upButtonDown = prevMenuItem,
  AButtonDown = function ()
    local selected = menu.tabIndex[selectedIndex]
    if selected == menu:get("furzbedeinten") then
      local wort = playdate.sound.fileplayer.new("audio/furzbedeinten")
      wort:play()
    end
    if selected == menu:get("yes") then
      menuSprite:moveBy(0, 4)
      menuSprite:update()
    end
    setPointerPos()
  end
}

function setup()
  -- import words
  redewendungen = json.decodeFile("redewendungen.json")

  -- attach input handlers
  playdate.inputHandlers.push(inputHandlers)

  -- setup menu
  menu = playout.tree:build(createMenu)
  menu:computeTabIndex()
  menuImg = menu:draw()
  menuSprite = gfx.sprite.new(menuImg)
  menuSprite:moveTo(200, 400)
  menuSprite:add()

  -- setup bg sprite
  local bg = gfx.image.new("images/wrapping-pattern.png")
  gfx.sprite.setBackgroundDrawingCallback(
    function(x, y, width, height)
      gfx.setClipRect(x, y, width, height)
      bg:draw(0, 0)
      gfx.clearClipRect()
    end
  )

  -- setup pointer
  local pointerImg = gfx.image.new("images/pointer")
  pointer = gfx.sprite.new(pointerImg)
  pointer:setRotation(90)
  pointer:setZIndex(1)
  pointer:add()
  setPointerPos()

  -- setup pointer animation
  pointerTimer = playdate.timer.new(500, -18, -14, playdate.easingFunctions.inOutSine)
  pointerTimer.repeats = true
  pointerTimer.reverses = true

  -- setup menu animation
  menuTimer = playdate.timer.new(500, 400, 100, playdate.easingFunctions.outCubic)
  menuTimer.timerEndedCallback = setPointerPos
end

-- frame callback
function playdate.update()
  if menuTimer.timeLeft > 0 then
    menuSprite:moveTo(200, menuTimer.value)
    menuSprite:update()
  end

  pointer:moveTo(
    pointerPos:offsetBy(pointerTimer.value, 0)
  )
  pointer:update()

  playdate.timer.updateTimers()
  playdate.drawFPS()
end

setup()
