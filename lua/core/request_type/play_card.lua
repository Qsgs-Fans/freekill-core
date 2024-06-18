local Dashboard = require 'ui_emu.dashboard'
local ReqActiveSkill = require 'core.request_type.active_skill'
local control = require 'ui_emu.control'
local Button = control.Button

---@class ReqPlayCard: ReqActiveSkill
---@field public selected_card? Card 使用一张牌时会用到 支持VS技
local ReqPlayCard = ReqActiveSkill:subclass("ReqPlayCard")

function ReqPlayCard:initialize(player)
  ReqActiveSkill.initialize(self, player)
  self.scene = Dashboard:new(self)
end

-- 这种具体的合法性分析代码要不要单独放到某个模块呢
---@param player Player
---@param card Card
---@param data any 这啥啊
function ReqPlayCard:canUseCard(player, card, data)
  -- TODO: 补全判断逻辑
  -- 若需要其他辅助函数的话在这个文件进行local
  return player:canUse(card, data)
  --[[
    if ret then
    local min_target = c.skill:getMinTargetNum()
    if min_target > 0 then
      for _, p in ipairs(ClientInstance.players) do
        if c.skill:targetFilter(p.id, {}, {}, c, extra_data) then
          return true
        end
      end
      return false
    end
  end
  ]]
end

function ReqPlayCard:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene

  -- TODO: &牌堆
  for _, cid in ipairs(self.player:getCardIds("h")) do
    if self:canUseCard(self.player, Fk:getCardById(cid)) then
      scene:update("CardItem", cid, { enabled = true })
    end
  end

  -- dashboard.enableSkills();

  -- 出牌阶段还要多模拟一个结束按钮
  scene:addItem(Button:new(self.scene, "End"))
  scene:update("Button", "End", { enabled = true })
  scene:notifyUI()
end

function ReqPlayCard:doOkButton()
  -- const reply = JSON.stringify({
  --   card: dashboard.getSelectedCard(),
  --   targets: selected_targets,
  --   special_skill: roomScene.getCurrentCardUseMethod(),
  --   interaction_data: roomScene.skillInteraction.item ?
  --                     roomScene.skillInteraction.item.answer : undefined,
  -- });
  ClientInstance:notifyUI("ReplyToServer", "")
end

function ReqPlayCard:doCancelButton()
  ClientInstance:notifyUI("ReplyToServer", "__cancel")
end

function ReqPlayCard:doEndButton()
  ClientInstance:notifyUI("ReplyToServer", "")
end

function ReqPlayCard:selectCard(cid, data)
  local scene = self.scene
  local selected = data.selected
  scene:update("CardItem", cid, data)

  if selected then
    self.selected_card = Fk:getCardById(cid)
    local dat = { selected = false }
    for _, id in ipairs(self.player:getCardIds("h")) do
      if id ~= cid then
        scene:update("CardItem", id, dat)
      end
    end
  else
    self.selected_card = nil
  end
end

function ReqPlayCard:updateTargets()
  if not self.selected_card then

  end
end

function ReqPlayCard:update(elemType, id, action, data)
  self.change = ClientInstance and {} or nil
  if elemType == "Button" then
    if id == "Ok" then self:doOkButton()
    elseif id == "Cancel" then self:doCancelButton()
    elseif id == "End" then self:doEndButton() end
    return
  elseif elemType == "CardItem" then
    self:selectCard(id, data)
    self:updateTargets()
  elseif elemType == "Photo" then
  elseif elemType == "SkillButton" then
  end
  self.scene:notifyUI()
end

return ReqPlayCard
