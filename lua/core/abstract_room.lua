---@class Base.AbstractRoom : Object
---@field public players Player[] @ 房内参战角色们
---@field public observers Player[] @ 看戏的
---@field public current Player @ 当前行动者
---@field public capacity integer @ 房间的最大参战人数
---@field public timeout integer @ 出牌时长上限
---@field public settings table @ 房间的额外设置，差不多是json对象
---@field public current_request_handler RequestHandler @ 当前正处理的请求数据
---@field public banners table<string, any> @ 全局mark
local AbstractRoom = class("Base.AbstractRoom")

function AbstractRoom:initialize()
  self.players = {}
  self.observers = {}
  self.current = nil

  self.banners = {}
end

-- 仅供注释，其余空函数一样

--- 根据角色id，获得那名角色本人
---@param id integer @ 角色的id
---@return Player
function AbstractRoom:getPlayerById(id)
  ---@diagnostic disable-next-line
  return table.find(self.players, function(p) return p.id == id end)
end

-- 根据角色座位号，获得那名角色本人
---@param seat integer
---@return Player
function AbstractRoom:getPlayerBySeat(seat)
  ---@diagnostic disable-next-line
  return table.find(self.players, function(p) return p.seat == seat end)
end

--- 设置房间的当前行动者
---@param player Player
function AbstractRoom:setCurrent(player)
  self.current = player
end

---@return Player? @ 当前回合角色
function AbstractRoom:getCurrent()
  return self.current
end

--- 设置房间banner于左上角，用于模式介绍，仁区等
function AbstractRoom:setBanner(name, value)
  if value == 0 then value = nil end
  self.banners[name] = value
end

--- 获得房间的banner，如果不存在则返回nil
function AbstractRoom:getBanner(name)
  local v = self.banners[name]
  if type(v) == "table" and not Util.isCborObject(v) then
    return table.simpleClone(v)
  end
  return v
end

-- 底层逻辑这一块之序列化和反序列化

function AbstractRoom:toJsonObject()
  local players = {}
  for _, p in ipairs(self.players) do
    players[p.id] = p:toJsonObject()
  end

  return {
    circle = table.map(self.players, Util.IdMapper),
    current = self.current and self.current.id or nil,
    capacity = self.capacity,
    timeout = self.timeout,
    settings = self.settings,
    banners = cbor.encode(self.banners),

    players = players,
  }
end

function AbstractRoom:loadJsonObject(o)
  self.current = self:getPlayerById(o.current)
  self.capacity = o.capacity or #self.players
  self.timeout = o.timeout
  self.settings = o.settings

  -- 需要上层（目前是Client）自己根据circle添加玩家
  for k, v in pairs(o.players) do
    self:getPlayerById(k):loadJsonObject(v)
  end

  self.banners = cbor.decode(o.banners)
end

return AbstractRoom
