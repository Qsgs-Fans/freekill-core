-- 用于当一名玩家需要对Request作出回应时
-- 包含相关数据以及一个模拟UI场景 以及需要用到的所有UI合法性判断逻辑
--@field public data any 相关数据，需要子类自行定义一个类或者模拟类

---@class RequestHandler: Object
---@field public room AbstractRoom
---@field public scene Scene
---@field public player Player 需要应答的玩家
---@field public change { [string]: Item[] } 将会传递给UI的更新数据
local RequestHandler = class("RequestHandler")

function RequestHandler:initialize(player)
  self.room = Fk:currentRoom()
  self.player = player
  self.room.current_request_handler = self
end

-- 进入Request之后需要做的第一步操作，对应之前UI代码中state变换
function RequestHandler:setup() end

function RequestHandler:disabledAll()
  local scene = self.scene
  local room = self.room
  -- TODO: 统一调用一个公有ID表（代表屏幕亮出的这些牌）
  for _, cid in ipairs(self.player:getCardIds("h")) do
    local dat = {}
    dat.selected = false
    dat.enabled = false
    scene:update("CardItem", cid, dat)
  end
  for _, p in ipairs(room.alive_players) do
    local dat = {}
    local pid = p.id
    dat.state = "normal"
    -- dat.enabled = false
    -- dat.selected = false
    scene:update("Photo", pid, dat)
  end
  scene:notifyUI()
end

-- 产生UI事件后由UI触发
-- 需要实现各种合法性检验，决定需要变更状态的UI，并最终将变更反馈给真实的界面
---@param elemType string
---@param id string | integer
---@param action string
---@param data any
function RequestHandler:update(elemType, id, action, data) end

return RequestHandler
