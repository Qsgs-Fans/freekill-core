local RoomScene = require 'ui_emu.roomscene'
local ReqActiveSkill = require 'core.request_type.active_skill'
local ReqResponseCard = require 'core.request_type.response_card'

---@class ReqUseCard: ReqResponseCard
local ReqUseCard = ReqResponseCard:subclass("ReqUseCard")

function ReqUseCard:initialize(player)
  ReqResponseCard.initialize(self, player)
  self.scene = RoomScene:new(self)
end

-- 这种具体的合法性分析代码要不要单独放到某个模块呢
---@param player Player @ 使用者
---@param card Card @ 目标卡牌
---@param data? any @ 额外数据?
function ReqUseCard:canUseCard(player, card, data)
  -- TODO: 补全判断逻辑
  -- 若需要其他辅助函数的话在这个文件进行local
  local exp = Exppattern:Parse(self.pattern)
  return not player:prohibitUse(card) and exp:match(card)
end

function ReqUseCard:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene
  local player = self.player
  p("setup use!")

  -- 准备牌堆
  self:updateCard()

  -- RoomScene.enableSkills();
  local vss = table.filter(player:getAllSkills(), function(s)
    return s:isInstanceOf(ViewAsSkill)
  end)
  ---@param skill ViewAsSkill
  for _, skill in ipairs(vss) do
    local ret = skill:enabledAtResponse(player, false)
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

  scene:update("Button", "Cancel", { enabled = self.cancelable })
  scene:notifyUI()
end

function ReqUseCard:selectSkill(skill, data)
  local scene = self.scene
  local selected = data.selected
  scene:update("SkillButton", skill, data)

  if selected then
    self.skill_name = skill
    self.selected_card = nil
    ReqActiveSkill.updateCard(self, data)
    ReqActiveSkill.updateTarget(data)
  else
    self.skill_name = nil
    self:updateCard(data)
    self:updateTarget(data)
  end
end

function ReqUseCard:checkButton(data)
  local scene = self.scene
  local skill = Fk.skills[self.skill_name] ---@type ViewAsSkill
  local card = self.selected_card
  local dat = { enabled = false }
  -- 正在选技能
  if skill then
    card = skill:viewAs(self.pendings)
  end
  if card and self:canUseCard(self.player, card) then
    dat.enabled = not not (card.skill:feasible(
    self.selected_targets, { card.id }, self.player, card))
  end
  scene:update("Button", "OK", dat)
end

function ReqUseCard:updateTarget(data)
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

function ReqUseCard:selectTarget(playerid, data)
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

function ReqUseCard:update(elemType, id, action, data)
  self.change = ClientInstance and {} or nil
  if elemType == "Button" then
    if id == "OK" then self:doOKButton()
    elseif id == "Cancel" then self:doCancelButton() end
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

return ReqUseCard
