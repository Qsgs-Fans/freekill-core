local RoomScene = require 'ui_emu.roomscene'
local control = require 'ui_emu.control'
local Button = control.Button

-- 这里就要定义各种状态性质的属性了 参考一下目前的

---@class ReqActiveSkill: RequestHandler
---@field public skill_name string 当前响应的技能名
---@field public prompt string 提示信息
---@field public cancelable boolean 可否取消
---@field public extra_data any 需要另外定义 先any
---@field public pending_skill string
---@field public pendings integer[] 卡牌id数组
---@field public selected_targets integer[] 选择的目标
local ReqActiveSkill = RequestHandler:subclass("ReqActiveSkill")

function ReqActiveSkill:initialize(player)
  RequestHandler.initialize(self, player)
  self.scene = RoomScene:new(self)

  self.pendings = {}
  self.selected_targets = {}
end

function ReqActiveSkill:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene
  -- skillInteraction.sourceComponent = undefined;
  -- RoomScene.updateHandcards();
  -- RoomScene.enableCards(responding_card);
  -- RoomScene.enableSkills(responding_card, respond_play);
  -- autoPending = false;
  -- progress.visible = true;
  -- okCancel.visible = true;
  self:updateCard()
  scene:addItem(Button:new(self.scene, "Ok"))
  scene:addItem(Button:new(self.scene, "Cancel"))
end

function ReqActiveSkill:checkButton(data)
  local player = self.player
  local scene = self.scene
  local skill = Fk.skills[self.pending_skill] ---@type ActiveSkill
  if skill then
    local ret = skill:feasible(self.selected_targets, self.pendings, player)
    if ret then
      scene:update("Button", "Ok", { enabled = true })
      return
    end
  end
  scene:update("Button", "Ok", { enabled = false })
end

function ReqActiveSkill:doOkButton()
  ClientInstance:notifyUI("ReplyToServer", "")
end

function ReqActiveSkill:doCancelButton()
  ClientInstance:notifyUI("ReplyToServer", "__cancel")
end

function ReqActiveSkill:updateCard(data)
  local scene = self.scene
  local skill = Fk.skills[self.pending_skill] ---@type ActiveSkill
  -- TODO: expand_pile
  for _, cid in ipairs(self.player:getCardIds("h")) do
    if not skill:cardFilter(cid, self.pendings, self.selected_targets) then
    --   scene:update("CardItem", cid, { enabled = true })
    -- else
      scene:update("CardItem", cid, { enabled = false })
    end
  end
end

function ReqActiveSkill:selectCard(cardid, data)
  local scene = self.scene
  local selected = data.selected
  local skill = Fk.skills[self.pending_skill] ---@type ActiveSkill
  scene:update("CardItem", cardid, data)

  if selected then
    table.insert(self.pendings, cardid)
  else
    -- 存储剩余目标
    local previous_pendings = table.filter(self.pendings, function(id)
      return id ~= cardid
    end)
    self.pendings = {}
    for _, cid in ipairs(previous_pendings) do
      local ret
      ret = skill and
      skill:cardFilter(cid, self.pendings)
      -- 从头开始写目标
      if ret then
        table.insert(self.pendings, cid)
      end
      scene:update("CardItem", cid, { selected = not not ret })
    end
  end
end

function ReqActiveSkill:updateTarget(data)
  local player = self.player
  local room = self.room
  local scene = self.scene
  local skill = Fk.skills[self.pending_skill] ---@type ActiveSkill
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
  if skill then
    for _, p in ipairs(room.alive_players) do
      local dat = {}
      local pid = p.id
      dat.state = "candidate"
      dat.enabled = not not(skill and
      skill:targetFilter(pid, self.selected_targets, self.pendings))
      -- print(string.format("<%d %s>", pid, tostring(dat.enabled)))
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
  local skill = Fk.skills[self.pending_skill] ---@type ActiveSkill
  scene:update("Photo", playerid, data)

  if skill then
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
        skill:targetFilter(pid, self.selected_targets, self.pendings)
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
        dat.enabled = not not(skill and
        skill:targetFilter(pid, self.selected_targets, self.pendings))
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

function ReqActiveSkill:update(elemType, id, action, data)
  self.change = ClientInstance and {} or nil
  if elemType == "Button" then
    if id == "Ok" then self:doOkButton()
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
