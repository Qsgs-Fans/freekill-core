---@class ClientPlayerBase: Base.Player
---@field public player fk.Player
local ClientPlayerBase = {}

function ClientPlayerBase:initialize(cp)
  self.player = cp
  self.id = cp:getId()
end

function ClientPlayerBase:serialize()
  local klass = self.class.super --[[@as Base.Player]]
  local o = klass.serialize(self)
  local sp = self.player
  o.setup_data = {
    self.id,
    sp:getScreenName(),
    sp:getAvatar(),
    false,
    sp:getTotalGameTime(),
  }
  return o
end

return ClientPlayerBase