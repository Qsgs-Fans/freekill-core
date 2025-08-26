---@class Base.Engine : Object
local Engine = class("Base.Engine")

function Engine:initialize()
end

---@deprecated
function Engine:loadPackage(pack)
  pack:install(self)
end

return Engine
