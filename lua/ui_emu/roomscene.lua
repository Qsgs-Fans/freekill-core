local common = require 'ui_emu.common'
local OKScene = require 'ui_emu.okscene'
local CardItem = common.CardItem
local Photo = common.Photo
local SkillButton = common.SkillButton

---@class RoomScene: OKScene
local RoomScene = OKScene:subclass("RoomScene")

---@param parent RequestHandler
function RoomScene:initialize(parent)
  OKScene.initialize(self, parent)
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
end

return RoomScene