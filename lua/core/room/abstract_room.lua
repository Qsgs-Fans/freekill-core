-- 作Room和Client的基类，这二者有不少共通之处
--
-- 子类纯属写给注释看，这个面向对象库没有实现多重继承
---@class AbstractRoom : CardManager
---@field public players Player[] @ 房内参战角色们
---@field public alive_players Player[] @ 所有存活玩家的数组
---@field public observers Player[] @ 看戏的
---@field public current Player @ 当前行动者
---@field public status_skills table<class, Skill[]> @ 这个房间中含有的状态技列表
---@field public skill_costs table<string, any> @ 用来存skill.cost_data
---@field public card_marks table<integer, any> @ 用来存实体卡的card.mark
---@field public banners table<string, any> @ 全局mark
---@field public current_request_handler RequestHandler @ 当前正处理的请求数据
local AbstractRoom = class("AbstractRoom")

local CardManager = require 'core.room.card_manager'
AbstractRoom:include(CardManager)

function AbstractRoom:initialize()
  self.players = {}
  self.alive_players = {}
  self.observers = {}
  self.current = nil

  self:initCardManager()
  self.status_skills = {}
  for class, skills in pairs(Fk.global_status_skill) do
    self.status_skills[class] = {table.unpack(skills)}
  end

  self.skill_costs = {}
  self.banners = {}
end

-- 仅供注释，其余空函数一样
---@param id integer
---@return Player
---@diagnostic disable-next-line: missing-return
function AbstractRoom:getPlayerById(id) end

--- 获得拥有某一张牌的玩家。
---@param cardId integer | Card @ 要获得主人的那张牌，可以是Card实例或者id
---@return Player? @ 这张牌的主人的，可能返回nil
function AbstractRoom:getCardOwner(cardId)
  local ret = CardManager.getCardOwner(self, cardId)
  return ret and self:getPlayerById(ret)
end

function AbstractRoom:setBanner(name, value)
  if value == 0 then value = nil end
  self.banners[name] = value
end

function AbstractRoom:getBanner(name)
  return self.banners[name]
end

return AbstractRoom
