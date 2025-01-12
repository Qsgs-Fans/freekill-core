---@class TriggerData: Object
---@field private _data any
TriggerData = class("TriggerData")

--预设值
TriggerData.default_values = {} 
function TriggerData:initialize(spec)
  -- table.assign(self, spec)
  self._data = table.clone(self.default_values)
  for key, value in pairs(spec or {}) do
    self._data[key] = value
  end
end

function TriggerData:__index(k)
  if k == "_data" then return rawget(self, k) end
  return self._data[k]
end

function TriggerData:__newindex(k, v)
  if k == "_data" then rawset(self, k, v) end
  if not self._data then rawset(self, k, v) end
  self._data[k] = v
end

--fill_missing_data(default_value)
function TriggerData:initData(room)
end

--condition for break event
function TriggerData:checkBreak()

end
function TriggerData:initCardSkillName()
  if self.card and not self.skillName then
    self.skillName = self.card.skill.name
  end
end
-- mainly for no_source if dead
---@field playerKey string @"from" or "to"
function TriggerData:removeDeathPlayer(playerKey)
  if self[playerKey] and self[playerKey].dead then
    self[playerKey] = nil
  end
end
require "core.events.misc"
require "core.events.hp"
require "core.events.death"
require "core.events.movecard"
require "core.events.usecard"
require "core.events.skill"
require "core.events.judge"
require "core.events.gameflow"
require "core.events.pindian"
