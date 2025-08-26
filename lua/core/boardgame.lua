---@class Base.QmlComponent
---@field uri? string
---@field name? string
---@field url? string
---@field prop? { [string]: any }

---@class Base.BoardGameSpec
---@field name string
---@field engine Base.Engine engine实例
---@field client_klass Client client类
---@field room_klass Room room类
---@field page Base.QmlComponent 主游戏页面数据

--- 定义某款桌游。桌游大类只负责：
---
--- * 服务端newroom时创建相应类型的Room
--- * 
---@class Base.BoardGame : Base.BoardGameSpec, Object
local BoardGame = class("Base.BoardGame")

function BoardGame:initialize(spec)
  self.name = spec.name
  self.engine = spec.engine
  self.page = spec.page
end

return BoardGame
