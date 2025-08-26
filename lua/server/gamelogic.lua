---@class Base.GameLogic : Object
local GameLogic = class("Base.GameLogic")

---@param room Base.AbstractRoom
function GameLogic:initialize(room)
  self.room = room
end

return GameLogic
