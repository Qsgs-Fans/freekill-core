local ReqActiveSkill = require 'core.request_type.active_skill'
local ReqUseCard = require 'lua.core.request_type.use_card'
local control = require 'ui_emu.control'
local Button = control.Button

---@class ReqPlayCard: ReqUseCard
---@field public selected_card? Card 使用一张牌时会用到 支持VS技
local ReqPlayCard = ReqUseCard:subclass("ReqPlayCard")

-- function ReqPlayCard:initialize(player)
--   ReqUseCard.initialize(self, player)
--   self.scene = RoomScene:new(self)
-- end

-- 这种具体的合法性分析代码要不要单独放到某个模块呢
---@param player Player @ 使用者
---@param card Card @ 目标卡牌
---@param data? any @ 额外数据?
function ReqPlayCard:canUseCard(player, card, data)
  -- TODO: 补全判断逻辑
  -- 若需要其他辅助函数的话在这个文件进行local
  return player:canUse(card)
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
  local player = self.player
  p("setup playcard!")

  -- 准备牌堆
  self:updateCard()

  -- RoomScene.enableSkills();
  local skills = player:getAllSkills()
  local actives = table.filter(skills, function(s)
    return s:isInstanceOf(ActiveSkill)
  end)
  local vss = table.filter(skills, function(s)
    return s:isInstanceOf(ViewAsSkill)
  end)
  ---@param skill ActiveSkill
  for _, skill in ipairs(actives) do
    scene:update("SkillButton", skill.name, {
      enabled = not not(skill:canUse(player, nil))
    })
  end
  ---@param skill ViewAsSkill
  for _, skill in ipairs(vss) do
    local ret = skill:enabledAtPlay(player)
    if ret then
      local exp = Exppattern:Parse(skill.pattern)
      local cnames = {}
      for _, m in ipairs(exp.matchers) do
        if m.name then
          table.insertTable(cnames, m.name)
        end
        if m.trueName then
          table.insertTable(cnames, m.trueName)
        end
      end
      for _, n in ipairs(cnames) do
        local c = Fk:cloneCard(n)
        c.skillName = skill.name
        ret = self:canUseCard(player, c)
        if ret then break end
      end
    end
    scene:update("SkillButton", skill.name, {
      enabled = ret
    })
  end

  -- 出牌阶段还要多模拟一个结束按钮
  scene:addItem(Button:new(self.scene, "End"))
  scene:update("Button", "End", { enabled = true })
  scene:notifyUI()
end

-- function ReqPlayCard:doOKButton()
--   -- const reply = JSON.stringify({
--   --   card: dashboard.getSelectedCard(),
--   --   targets: selected_targets,
--   --   special_skill: roomScene.getCurrentCardUseMethod(),
--   --   interaction_data: roomScene.skillInteraction.item ?
--   --                     roomScene.skillInteraction.item.answer : undefined,
--   -- });
--   ClientInstance:notifyUI("ReplyToServer", "")
-- end

-- function ReqPlayCard:doCancelButton()
--   ClientInstance:notifyUI("ReplyToServer", "__cancel")
-- end

-- function ReqPlayCard:doOKButton()
--   local cardstr
--   -- 正在选技能
--   if self.skill_name then
--     cardstr = json.encode{
--       skill = self.skill_name,
--       subcards = self.pendings
--     }
--   else
--     cardstr = self.selected_card:getEffectiveId()
--   end
--   local reply = {
--     card = cardstr,
--     targets = self.selected_targets,
--   }
--   ClientInstance:notifyUI("ReplyToServer", json.encode(reply))
-- end

function ReqPlayCard:doEndButton()
  ClientInstance:notifyUI("ReplyToServer", "")
end

function ReqPlayCard:checkButton(data)
  local player = self.player
  local scene = self.scene
  -- 正在选技能
  if self.skill_name then
    return ReqActiveSkill.checkButton(self, data)
  end
  local card = self.selected_card
  local dat = { enabled = false }
  if card then
    local skill = card.skill ---@type ActiveSkill
    dat.enabled = not not (skill:feasible(self.selected_targets, { card.id },
    player, card))
  end
  scene:update("Button", "OK", dat)
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
    self:updateTarget(data)
  elseif elemType == "Photo" then
    self:selectTarget(id, data)
  elseif elemType == "SkillButton" then
    self:selectSkill(id, data)
  end
  self.scene:notifyUI()
end

return ReqPlayCard
