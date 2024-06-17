local Dashboard = require 'ui_emu.dashboard'

---@class PlayCardHandler: RequestHandler
local ReqPlayCard = RequestHandler:subclass("ReqPlayCard")

function ReqPlayCard:initialize(player)
  RequestHandler.initialize(self, player)
  -- TODO: 应该不用每次都新建一套 牌多技能多就费事
  self.scene = Dashboard:new(self)
end

return ReqPlayCard
