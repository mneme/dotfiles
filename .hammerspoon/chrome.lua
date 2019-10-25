-- This module is to improve workflow in Slack
local chrome = {}
local windows = require "windows"

chrome.create = function(profile)
  local ret = {}
  ret.bind = function(modal, fsm, key)
    modal:bind("", key, function()
      hs.application.launchOrFocus("Google Chrome")
      local app = hs.application.find("Google Chrome")
      hs.timer.doAfter(0.2, function() app:selectMenuItem(profile) end)
      fsm:toIdle()
    end)
  end

  return ret
end

return chrome
