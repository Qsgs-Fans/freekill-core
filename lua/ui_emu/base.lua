-- 模拟一套UI操作，并在具体子类中实现相应操作逻辑。分为UI组件和UI场景两种类。
-- 在客户端与Qml直接同步，在服务端中用于AI。

-- 模拟UI组件。最基本的属性为enabled，表示是否可以进行交互。
---@class Item: Object
---@field public parent Scene
---@field public enabled boolean
local Item = class("Item")

---@parant scene Scene
function Item:initialize(scene)
  self.parent = scene
  self.enabled = false
end

---@class SelectableItem: Item
---@field public selected boolean
local SelectableItem = Item:subclass("SelectableItem")

---@parant scene Scene
function SelectableItem:initialize(scene)
  Item.initialize(self, scene)
  self.selected = false
end

-- 最基本的“交互”，对应到UI中就是一次点击。
-- 在派生类中视情况可能要为其传入参数表示修改后的值。
function Item:interact() end

-- 模拟UI场景。用途是容纳所有模拟UI组件，并与实际的UI进行信息交换。
---@class Scene: Object
---@field public parent RequestHandler
---@field public items table<Item, Item[]>
local Scene = class("Scene")

function Scene:initialize(parent)
  self.parent = parent
  self.items = {}
end

---@param item Item
function Scene:addItem(item)
  local key = item.class.name
  self.items[key] = self.items[key] or {}
  table.insert(self.items[key], item)
end

function Scene:update() end
function Scene:notifyUI(data) end

return {
  Item = Item,
  SelectableItem = SelectableItem,
  Scene = Scene,
}