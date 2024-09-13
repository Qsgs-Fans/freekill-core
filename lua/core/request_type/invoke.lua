local OKScene = require 'ui_emu.okscene'

-- 极其简单的skillinvoke

---@class ReqInvoke: RequestHandler
---@field public prompt string 提示信息
local ReqInvoke = RequestHandler:subclass("ReqInvoke")

function ReqInvoke:initialize(player)
  RequestHandler.initialize(self, player)
  self.scene = OKScene:new(self)
end

function ReqInvoke:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene

  scene:update("Button", "OK", { enabled = true })
  scene:update("Button", "Cancel", { enabled = true })
  scene:notifyUI()
end

function ReqInvoke:doOKButton()
  ClientInstance:notifyUI("ReplyToServer", "1")
end

function ReqInvoke:doCancelButton()
  ClientInstance:notifyUI("ReplyToServer", "__cancel")
end

function ReqInvoke:update(elemType, id, action, data)
  self.change = ClientInstance and {} or nil
  if elemType == "Button" then
    if id == "OK" then self:doOKButton()
    elseif id == "Cancel" then self:doCancelButton() end
  end
end

return ReqInvoke
