local ReqActiveSkill = require 'core.request_type.active_skill'
local ReqUseCard = require 'lua.core.request_type.use_card'
local Button = (require 'ui_emu.control').Button

---@class ReqPlayCard: ReqUseCard
local ReqPlayCard = ReqUseCard:subclass("ReqPlayCard")

function ReqPlayCard:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene

  self:updateUnselectedCards()
  self:updateSkillButtons()

  -- 出牌阶段还要多模拟一个结束按钮
  scene:addItem(Button:new(self.scene, "End"))
  scene:update("Button", "End", { enabled = true })
  scene:notifyUI()
end

function ReqPlayCard:cardValidity(cid)
  if self.skill_name then return ReqActiveSkill.cardValidity(self, cid) end
  local player = self.player
  local card = cid
  if type(cid) == "number" then card = Fk:getCardById(cid) end
  local ret = player:canUse(card)
  if ret then
    local min_target = card.skill:getMinTargetNum()
    if min_target > 0 then
      for _, p in ipairs(ClientInstance.players) do
        if card.skill:targetFilter(p.id, {}, {}, card, self.extra_data) then
          return true
        end
      end
      return false
    end
  end
end

function ReqPlayCard:skillButtonValidity(name)
  local player = self.player
  local skill = Fk.skills[name]
  if skill:isInstanceOf(ViewAsSkill) then
    return skill:enabledAtPlay(player, true)
  elseif skill:isInstanceOf(ActiveSkill) then
    return skill:canUse(player, nil)
  end
end

function ReqPlayCard:feasible()
  local player = self.player
  if self.skill_name then
    return ReqActiveSkill.feasible(self)
  end
  local card = self.selected_card
  local ret = false
  if card then
    local skill = card.skill ---@type ActiveSkill
    ret = skill:feasible(self.selected_targets, { card.id }, player, card)
  end
  return ret
end

function ReqPlayCard:doEndButton()
  ClientInstance:notifyUI("ReplyToServer", "")
end

function ReqPlayCard:update(elemType, id, action, data)
  self.change = ClientInstance and {} or nil
  if elemType == "Button" then
    if id == "OK" then self:doOKButton()
    elseif id == "Cancel" then self:doCancelButton()
    elseif id == "End" then self:doEndButton() end
    return
  elseif elemType == "CardItem" then
    self:selectCard(id, data)
    self:updateTargetsAfterCardSelected()
  elseif elemType == "Photo" then
    self:selectTarget(id, data)
  elseif elemType == "SkillButton" then
    self:selectSkill(id, data)
  end
  self.scene:notifyUI()
end

return ReqPlayCard
