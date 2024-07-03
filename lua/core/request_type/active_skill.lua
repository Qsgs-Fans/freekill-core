local RoomScene = require 'ui_emu.roomscene'
local control = require 'ui_emu.control'
local Button = control.Button

-- 这里就要定义各种状态性质的属性了 参考一下目前的

---@class ReqActiveSkill: RequestHandler
---@field public skill_name string 当前响应的技能名
---@field public prompt string 提示信息
---@field public cancelable boolean 可否取消
---@field public extra_data any 需要另外定义 先any
---@field public pendings integer[] 卡牌id数组
---@field public selected_targets integer[] 选择的目标
local ReqActiveSkill = RequestHandler:subclass("ReqActiveSkill")

function ReqActiveSkill:initialize(player)
  RequestHandler.initialize(self, player)
  self.scene = RoomScene:new(self)

  self.pendings = {}
  self.selected_targets = {}
end

function ReqActiveSkill:checkTargets(skill, data)
  local scene = self.scene
  local room = self.room

  for _, p in ipairs(room.alive_players) do
    local pid = p.id
    if skill then
      local dat = {
        state = "candidate",
      }
      if not table.contains(self.selected_targets, pid) then
        dat.enabled = not not(skill:targetFilter(
        pid, self.selected_targets, self.pendings))
        print(string.format("<%d %s>", pid, tostring(dat.enabled)))
        scene:update("Photo", pid, dat)
      end
    else
      local dat = {
        state = "normal",
      }
      scene:update("Photo", pid, dat)
    end
  end
end

function ReqActiveSkill:checkCards(skill, data)
  local scene = self.scene
  local room = self.room

  -- TODO: 统一调用一个公有ID表（代表屏幕亮出的这些牌）
  for _, cid in ipairs(self.player:getCardIds("h")) do
    local dat = {}
    if not table.contains(self.pendings, cid) then
      dat.enabled = not not(skill:cardFilter(cid, self.pendings))
      scene:update("CardItem", cid, dat)
    end
  end
end

function ReqActiveSkill:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene
  p("setup active!")
  -- skillInteraction.sourceComponent = undefined;
  -- RoomScene.updateHandcards();
  -- RoomScene.enableCards(responding_card);
  -- RoomScene.enableSkills(responding_card, respond_play);
  -- autoPending = false;
  -- progress.visible = true;
  -- okCancel.visible = true;
  self:updateCard()
  self:updateTarget()
  scene:update("Button", "Cancel", { enabled = self.cancelable })
  scene:notifyUI()
end

function ReqActiveSkill:checkButton(data)
  local player = self.player
  local scene = self.scene
  local skill = Fk.skills[self.skill_name] ---@type ActiveSkill | ViewAsSkill
  local dat = { enabled = false }
  if skill then
    if skill:isInstanceOf(ActiveSkill) then
      dat.enabled = not not (skill:feasible(self.selected_targets, self.pendings, player))
    elseif skill:isInstanceOf(ViewAsSkill) then
      local card = skill:viewAs(self.pendings)
      if card then
        local card_skill = card.skill ---@type ActiveSkill
        dat.enabled = not not (card_skill:feasible(
        self.selected_targets, { card.id }, player, card))
      end
    end
  end
  scene:update("Button", "OK", dat)
end

function ReqActiveSkill:doOKButton()
  local cardstr = json.encode{
    skill = self.skill_name,
    subcards = self.pendings
  }
  local reply = {
    card = cardstr,
    targets = self.selected_targets,
  }
  ClientInstance:notifyUI("ReplyToServer", json.encode(reply))
end

function ReqActiveSkill:doCancelButton()
  ClientInstance:notifyUI("ReplyToServer", "__cancel")
end

function ReqActiveSkill:updateCard(data)
  local scene = self.scene
  local skill = Fk.skills[self.skill_name] ---@type ActiveSkill
  self.pendings = {}

  self:checkCards(skill, data)
end

function ReqActiveSkill:selectCard(cardid, data)
  local scene = self.scene
  local selected = data.selected
  local skill = Fk.skills[self.skill_name] ---@type ActiveSkill | ViewAsSkill
  scene:update("CardItem", cardid, data)

  if selected then
    table.insert(self.pendings, cardid)
  else
    -- 存储剩余卡牌
    local previous_pendings = table.filter(self.pendings, function(id)
      return id ~= cardid
    end)
    self.pendings = {}
    for _, cid in ipairs(previous_pendings) do
      local ret
      ret = skill and
      skill:cardFilter(cid, self.pendings)
      -- 从头开始写卡牌
      if ret then
        table.insert(self.pendings, cid)
      end
      scene:update("CardItem", cid, { selected = not not ret })
    end
  end
  -- 剩余合法性检测
  self:checkCards(skill, data)
end

function ReqActiveSkill:updateTarget(data)
  local room = self.room
  local scene = self.scene
  local skill = Fk.skills[self.skill_name] ---@type ActiveSkill
  local actual_skill = skill ---@type ActiveSkill?
  if skill:isInstanceOf(ViewAsSkill) then
    local card = skill:viewAs(self.pendings)
    if card then
      actual_skill = card.skill
    else
      actual_skill = nil
    end
  end
  -- 重置
  self.selected_targets = {}
  -- 选择技能目标时
  if actual_skill then
    self:checkTargets(actual_skill, data)
  else
    for _, p in ipairs(room.alive_players) do
      local pid = p.id
      local dat = {
        state = "normal",
      }
      scene:update("Photo", pid, dat)
    end
  end
  -- 确认按钮
  self:checkButton(data)
end

function ReqActiveSkill:selectTarget(playerid, data)
  local player = self.player
  local room = self.room
  local scene = self.scene
  local selected = data.selected
  local skill = Fk.skills[self.skill_name] ---@type ActiveSkill | ViewAsSkill
  scene:update("Photo", playerid, data)
  local actual_skill = skill ---@type ActiveSkill?
  if skill:isInstanceOf(ViewAsSkill) then
    local card = skill:viewAs(self.pendings)
    if card then
      actual_skill = card.skill
    else
      actual_skill = nil
    end
  end

  if actual_skill then
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
        ret = skill and
        actual_skill:targetFilter(pid, self.selected_targets, self.pendings)
        -- 从头开始写目标
        if ret then
          table.insert(self.selected_targets, pid)
        end
        scene:update("Photo", pid, { selected = not not ret })
      end
    end
    p(self.selected_targets)
    -- 剩余合法性检测
    self:checkTargets(actual_skill, data)
  else
    for _, p in ipairs(room.alive_players) do
      local pid = p.id
      local dat = {
        state = "normal",
      }
      scene:update("Photo", pid, dat)
    end
  end
  -- 确认按钮
  self:checkButton(data)
end

function ReqActiveSkill:update(elemType, id, action, data)
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
  end
  self.scene:notifyUI()
end

return ReqActiveSkill
