local base = require 'ui_emu.base'
local SelectableItem = base.SelectableItem

---@class CardItem: SelectableItem
---@field public id integer
local CardItem = SelectableItem:subclass("CardItem")

function CardItem:initialize(scene, cardId)
  SelectableItem.initialize(self, scene)
  self.id = cardId
end

---@class Photo: SelectableItem
---@field public id integer
local Photo = SelectableItem:subclass("Photo")

function Photo:initialize(scene, playerId)
  SelectableItem.initialize(self, scene)
  self.id = playerId
end

---@class SkillButton: SelectableItem
---@field public name string
local SkillButton = SelectableItem:subclass("SkillButton")

return {
  CardItem = CardItem,
  Photo = Photo,
  SkillButton = SkillButton,
}