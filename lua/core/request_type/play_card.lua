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

  -- TODO: &牌堆
  for _, cid in ipairs(self.player:getCardIds("h")) do
    if self:canUseCard(self.player, Fk:getCardById(cid)) then
      scene:update("CardItem", cid, { enabled = true })
    end
  end

  -- RoomScene.enableSkills();

  -- 出牌阶段还要多模拟一个结束按钮
  scene:addItem(Button:new(self.scene, "Ok"))
  scene:addItem(Button:new(self.scene, "Cancel"))
  scene:addItem(Button:new(self.scene, "End"))
  scene:update("Button", "End", { enabled = true })
  scene:notifyUI()
end

function ReqPlayCard:doOkButton()
  -- const reply = JSON.stringify({
  --   card: RoomScene.getSelectedCard(),
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

function ReqPlayCard:checkButton(data)
  local player = self.player
  local scene = self.scene
  local card = self.selected_card
  if card then
    local skill = card.skill ---@type ActiveSkill
    local ret = skill:feasible(self.selected_targets, { card.id }, player, card)
    if ret then
      scene:update("Button", "Ok", { enabled = true })
      return
    end
  end
  scene:update("Button", "Ok", { enabled = false })
end

function ReqPlayCard:updateTargets(data)
  local player = self.player
  local room = self.room
  local scene = self.scene
  local card = self.selected_card
  -- 重置
  self.selected_targets = {}
  for _, p in ipairs(room.alive_players) do
    local dat = {}
    local pid = p.id
    dat.state = "normal"
    -- dat.enabled = false
    -- dat.selected = false
    scene:update("Photo", pid, dat)
  end
  -- 选择实体卡牌时
  if card then
    local skill = card.skill ---@type ActiveSkill
    for _, p in ipairs(room.alive_players) do
      local dat = {}
      local pid = p.id
      dat.state = "candidate"
      dat.enabled = not not(not player:isProhibited(p, card) and skill and
      skill:targetFilter(pid, self.selected_targets,
      { card.id }, card, data.extra_data))
      -- print(string.format("<%d %s>", pid, tostring(dat.enabled)))
      scene:update("Photo", pid, dat)
    end
  end
  -- 确认按钮
  self:checkButton(data)
end

function ReqPlayCard:selectTarget(playerid, data)
  local player = self.player
  local room = self.room
  local scene = self.scene
  local selected = data.selected
  local card = self.selected_card
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
    for _, p in ipairs(room.alive_players) do
      local dat = {}
      local pid = p.id
      if not table.contains(self.selected_targets, pid) then
        dat.enabled = not not(not player:isProhibited(p, card) and skill and
        skill:targetFilter(pid, self.selected_targets,
          {card.id}, card, data.extra_data))
        print(string.format("<%d %s>", pid, tostring(dat.enabled)))
        scene:update("Photo", pid, dat)
      end
    end
  else
    for _, p in ipairs(room.alive_players) do
      local dat = {}
      local pid = p.id
      dat.state = "normal"
      scene:update("Photo", pid, dat)
    end
  end
  -- 确认按钮
  self:checkButton(data)
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
    self:updateTargets(data)
  elseif elemType == "Photo" then
    self:selectTarget(id, data)
  elseif elemType == "SkillButton" then
  end
  self.scene:notifyUI()
end

return ReqPlayCard
