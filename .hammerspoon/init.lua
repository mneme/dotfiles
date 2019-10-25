require "preload"
local window = require "hs.window"
local alert = require "hs.alert"

local machine = require "statemachine"
local windows = require "windows"
local slack = require "slack"
local chrome = require "chrome"

local super = {'cmd','alt','ctrl'}

local applications = {
  c = "Google Chrome",
  f = "Firefox",
  s = "Slack",
  t = "kitty",
  e = "Emacs",
  y = "Skype",
  m = "Activity Monitor",
  v = "Visual Studio Code",
  p = "Spotify",
  q = "Studio 3T"
}

local handlers = {
  ["Slack"] = slack
};


function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local displayModalText = function(txt)
  hs.alert.closeAll()
  alert(txt, 999999)
end

function getApplicationBindings(applications)
  local modalText;
  for k,v in spairs(applications, function(t,a,b) return a < b end) do
    if not modalText then
      modalText = k .. "\t" .. v
    else
      modalText = modalText .. "\n" .. k .. "\t" .. v
    end
  end
  return modalText
end

modals = {
  base = {
    init = function(self, fsm)
      if self.modal then
        self.modal:enter()
      else
        self.modal = hs.hotkey.modal.new(super, "space")
      end

      function self.modal:entered()
        fsm:toMain()
      end
    end
  },
  main = {
    init = function(self, fsm)
      self.modal = hs.hotkey.modal.new()

      self.modal:bind("", "escape", function() fsm:toIdle() end)
      -- self.modal:bind(super,"b", nil, function() fsm:toBind() end)
      -- self.modal:bind(super,"u", nil, function() fsm:toBind() end)


      local modalText = getApplicationBindings(applications);

      for k,v in spairs(applications, function(t,a,b) return a < b end) do
        if handlers[v] then
          handlers[v].bind(self.modal, fsm, k)
        else
          self.modal:bind("", k, function()
            fsm:toIdle()
            windows.activateApp(v);
          end)
        end
      end

      displayModalText(modalText)
      self.modal:enter()
    end
  },
  bind = {
    init = function(self, fsm)
      if not self.eventtap then
        self.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
          self.eventtap:stop()
          local key = hs.keycodes.map[event:getKeyCode()]
          local flags = event:getFlags()
          local app = hs.application.frontmostApplication()

          if flags["cmd"] then
            applications[key] = nil

          elseif key ~= "escape" then
            for k,v in pairs(applications) do
              if v == app:name() then
                applications[k] = nil
              end
            end

            print('tap!', key, app:name())
            applications[key] = app:name()
          end

          fsm:toIdle()
          return true
        end)
      end

      self.eventtap:start();
      local modalText = getApplicationBindings(applications)
      modalText = modalText .. "\n\n".. "press key to bind application" .. "\n"
      modalText = modalText .. "press cmd + key to unbind"
      displayModalText(modalText)
    end
  }
}

local initModal = function(state, fsm)
  local m = modals[state]
  m.init(m, fsm)
end

exitAllModals = function()
  utils.each(modals,
    function(m)
     if m.modal then
       m.modal:exit()
     end
  end)
end

local fsm = machine.create({
    initial = "idle",
    events = {
      { name = "toIdle", from = "*",    to = "idle" },
      { name = "toBase", from = "*",    to = "base" },
      { name = "toMain", from = {"base", "idle"}, to = "main" },
      { name = "toBind", from = "main", to = "bind" },

    },
    callbacks = {
      onidle = function(self, event, from, to)
        hs.alert.closeAll()
        exitAllModals()
      end,

      onbase = function(self, event, from, to)
        initModal(to, self)
      end,

      onmain = function(self, event, from, to)
        initModal(to, self)
      end,

      onbind = function(self, event, from, to)
        modals[from].modal:exit()
        initModal(to, self)
      end
    }
})

fsm:toBase()

hs.alert.show("Config Loaded")
