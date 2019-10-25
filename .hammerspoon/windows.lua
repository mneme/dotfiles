local windows = {}

windows.highlighActiveWin = function()
  local rect = hs.drawing.rectangle(fw():frame())
  rect:setStrokeColor({["red"]=1,  ["blue"]=0, ["green"]=1, ["alpha"]=1})
  rect:setStrokeWidth(5)
  rect:setFill(false)
  rect:show()
  hs.timer.doAfter(0.3, function() rect:delete() end)
end

windows.activateApp = function(appName)
  hs.application.launchOrFocus(appName)

  local app = hs.application.find(appName)
  if app then
    app:activate()
    hs.timer.doAfter(0.1, windows.highlighActiveWin)
    app:unhide()
  end
end

windows.setMouseCursorAtApp = function(appTitle)
  local sf = hs.application.find(appTitle):findWindow(appTitle):frame()
  local desired_point = hs.geometry.point(sf._x + sf._w - (sf._w * 0.10), sf._y + sf._h - (sf._h * 0.10))
  hs.mouse.setAbsolutePosition(desired_point)
end
return windows
