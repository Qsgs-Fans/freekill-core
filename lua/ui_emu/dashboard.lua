local base = require 'ui_emu.base'
local common = require 'ui_emu.common'
local control = require 'ui_emu.control'
local Scene = base.Scene
local CardItem = common.CardItem
local Photo = common.Photo
local SkillButton = common.SkillButton
local Button = control.Button

---@class Dashboard: Scene
local Dashboard = Scene:subclass("Dashboard")

---@param parent RequestHandler
function Dashboard:initialize(parent)
  Scene.initialize(self, parent)
  local player = parent.player

  for _, p in ipairs(parent.room.alive_players) do
    self:addItem(Photo:new(self, p.id))
  end
  for _, cid in ipairs(player:getCardIds("he")) do
    self:addItem(CardItem:new(self, cid))
  end
  for _, skill in ipairs(player:getAllSkills()) do
    if skill:isInstanceOf(ActiveSkill) or skill:isInstanceOf(ViewAsSkill) then
      self:addItem(SkillButton:new(self, skill.name))
    end
  end

  self:addItem(Button:new(self, "OK"))
  self:addItem(Button:new(self, "Cancel"))
end

return Dashboard