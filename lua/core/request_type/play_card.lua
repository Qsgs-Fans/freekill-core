local RoomScene = require 'ui_emu.roomscene'
local ReqActiveSkill = require 'core.request_type.active_skill'
local control = require 'ui_emu.control'
local Button = control.Button

---@class ReqPlayCard: ReqActiveSkill
---@field public selected_card? Card 使用一张牌时会用到 支持VS技
local ReqPlayCard = ReqActiveSkill:subclass("ReqPlayCard")

function ReqPlayCard:initialize(player)
  ReqActiveSkill.initialize(self, player)
  self.scene = RoomScene:new(self)
end

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
        ret = c.skill:canUse(Self, c)
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

function ReqPlayCard:updateCard()
  local scene = self.scene
  local player = self.player
  self.selected_card = nil
  self.pendings = {}
  -- TODO: 统一调用一个公有ID表（代表屏幕亮出的这些牌）
  for _, cid in ipairs(player:getCardIds("h")) do
    local dat = {
      selected = false,
      enabled = not not(self:canUseCard(player, Fk:getCardById(cid))),
    }
    -- print(string.format("<%d %s>", cid, inspect(dat)))
    scene:update("CardItem", cid, dat)
  end
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

function ReqPlayCard:doOKButton()
  local cardstr
  -- 正在选技能
  if self.skill_name then
    cardstr = json.encode{
      skill = self.skill_name,
      subcards = self.pendings
    }
  else
    cardstr = self.selected_card:getEffectiveId()
  end
  local reply = {
    card = cardstr,
    targets = self.selected_targets,
  }
  ClientInstance:notifyUI("ReplyToServer", json.encode(reply))
end

function ReqPlayCard:doEndButton()
  ClientInstance:notifyUI("ReplyToServer", "")
end

function ReqPlayCard:selectSkill(skill, data)
  local scene = self.scene
  local selected = data.selected
  scene:update("SkillButton", skill, data)

  if selected then
    self.skill_name = skill
    self.selected_card = nil
    ReqActiveSkill.updateCard(self)
    ReqActiveSkill.updateTarget(self)
  else
    self.skill_name = nil
    self:updateCard()
    self:updateTarget()
  end
end

function ReqPlayCard:selectCard(cid, data)
  local scene = self.scene
  local selected = data.selected
  -- 正在选技能
  if self.skill_name then
    return ReqActiveSkill.selectCard(self, cid, data)
  end
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

function ReqPlayCard:updateTarget(data)
  local player = self.player
  local room = self.room
  local scene = self.scene
  local card = self.selected_card
  -- 正在选技能
  if self.skill_name then
    return ReqActiveSkill.updateTarget(self, data)
  end
  -- 重置
  self.selected_targets = {}
  local skill
  -- 选择实体卡牌时
  if card then
    skill = card.skill ---@type ActiveSkill
  end
  self:checkTargets(skill, data)
  -- 确认按钮
  self:checkButton(data)
end

function ReqPlayCard:selectTarget(playerid, data)
  local player = self.player
  local room = self.room
  local scene = self.scene
  local selected = data.selected
  local card = self.selected_card
  -- 正在选技能
  if self.skill_name then
    return ReqActiveSkill.selectTarget(self, playerid, data)
  end
  scene:update("Photo", playerid, data)

  if card then
    local skill = card.skill ---@type ActiveSkill
    if selected then
      table.insert(self.selected_targets, playerid)
    else
      -- 存储剩余目标
      local previous_targets = table.filter(self.selected_targets, function(id)
        return id ~= playerid
      end)
      self.selected_targets = {}
      for _, pid in ipairs(previous_targets) do
        local ret
        ret = not player:isProhibited(p, card) and skill and
        skill:targetFilter(pid, self.selected_targets,
        { card.id }, card, data.extra_data)
        -- 从头开始写目标
        if ret then
          table.insert(self.selected_targets, pid)
        end
        scene:update("Photo", pid, { selected = not not ret })
      end
    end
    p(self.selected_targets)
    -- 剩余合法性检测
    self:checkTargets(skill, data)
  else
    self:checkTargets(nil, data)
  end
  -- 确认按钮
  self:checkButton(data)
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
