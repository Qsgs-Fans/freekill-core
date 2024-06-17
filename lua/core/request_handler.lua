-- 用于当一名玩家需要对Request作出回应时
-- 包含相关数据以及一个模拟UI场景 以及需要用到的所有UI合法性判断逻辑
--@field public data any 相关数据，需要子类自行定义一个类或者模拟类

---@class RequestHandler: Object
---@field public room AbstractRoom
---@field public scene Scene
---@field public player Player 需要应答的玩家
local RequestHandler = class("RequestHandler")

function RequestHandler:initialize(player)
  self.room = Fk:currentRoom()
  self.player = player
  self.room.current_request_handler = self
end

-- 需要实现各种合法性检验，决定需要变更状态的UI，并最终将变更反馈给真实的界面
function RequestHandler:update(ui_class_name, id, change)
end

return RequestHandler
