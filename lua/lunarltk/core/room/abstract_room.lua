local baseAbstractRoom = require "core.abstract_room"

-- 作Room和Client的基类，这二者有不少共通之处
---@class AbstractRoom : Base.AbstractRoom, CardManager
---@field public alive_players Player[] @ 所有存活玩家的数组
---@field public status_skills table<class, Skill[]> @ 这个房间中含有的状态技列表
---@field public skill_costs table<string, any> @ 用来存skill.cost_data
---@field public card_marks table<integer, any> @ 用来存实体卡的card.mark
---@field public disabled_packs string[] @ 未开启的扩展包名（是小包名，不是大包名）
---@field public disabled_generals string[] @ 未开启的武将
local AbstractRoom = baseAbstractRoom:subclass("AbstractRoom")

local CardManager = require 'lunarltk.core.room.card_manager'
AbstractRoom:include(CardManager)

function AbstractRoom:initialize()
  baseAbstractRoom.initialize(self)
  self.alive_players = {}

  self:initCardManager()
  self.status_skills = {}
  for class, skills in pairs(Fk.global_status_skill) do
    self.status_skills[class] = {table.unpack(skills)}
  end

  self.skill_costs = {}
end

--- 获得拥有某一张牌的玩家。
---@param cardId integer | Card @ 要获得主人的那张牌，可以是Card实例或者id
---@return Player? @ 这张牌的主人，可能返回nil
function AbstractRoom:getCardOwner(cardId)
  local ret = CardManager.getCardOwner(self, cardId)
  return ret and self:getPlayerById(ret)
end

--- 获得当前房间中的当前回合角色。
---
--- 游戏开始时及每轮开始时当前回合还未正式开始，该函数可能返回nil。
---@return Player? @ 当前回合角色
function AbstractRoom:getCurrent()
  if self.current and self.current.phase ~= Player.NotActive then
    return self.current
  end
  return nil
end


function AbstractRoom:toJsonObject()
  local o = baseAbstractRoom.toJsonObject(self)
  local card_manager = CardManager.toJsonObject(self)
  o.card_manager = card_manager

  return o
end

function AbstractRoom:loadJsonObject(o)
  CardManager.loadJsonObject(self, o.card_manager)

  baseAbstractRoom.loadJsonObject(self, o)

  self.alive_players = table.filter(self.players, function(p)
    return p:isAlive()
  end)
end

-- TODO 这个好像是三国杀特有？

-- 判断当前模式是否为某类模式
---@param mode string @ 需要判定的模式类型
---@return boolean
function AbstractRoom:isGameMode(mode)
  return table.contains(Fk.main_mode_list[mode] or {}, self.settings.gameMode)
end

return AbstractRoom
