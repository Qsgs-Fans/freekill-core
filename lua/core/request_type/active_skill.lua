local RoomScene = require 'ui_emu.roomscene'

--[[
  负责处理AskForUseActiveSkill的Handler。
  涉及的UI组件：手牌区内的牌（TODO：expand牌）、在场角色、确定取消按钮
                （TODO：interaction小组件）
  可能发生的事件：
  * 点击手牌：刷新所有未选中牌的enable
  * 点击角色：刷新所有未选中的角色
  * (TODO) 修改interaction：重置信息
  * 按下按钮：发送答复

  为了后续的复用性需将ViewAsSkill也考虑进去
--]]

---@class ReqActiveSkill: RequestHandler
---@field public skill_name string 当前响应的技能名
---@field public prompt string 提示信息
---@field public cancelable boolean 可否取消
---@field public extra_data any 鬼晓得是啥 先any
---@field public pendings integer[] 卡牌id数组
---@field public selected_targets integer[] 选择的目标
local ReqActiveSkill = RequestHandler:subclass("ReqActiveSkill")

function ReqActiveSkill:initialize(player)
  RequestHandler.initialize(self, player)
  self.scene = RoomScene:new(self)
end

function ReqActiveSkill:setup()
  local scene = self.scene

  -- TODO: interaction
  self.pendings = {}
  scene:unselectAllCards()
  self:updateUnselectedCards()

  self.selected_targets = {}
  scene:unselectAllTargets()
  self:updateUnselectedTargets()

  self:updateButtons()
end

function ReqActiveSkill:feasible()
  local player = self.player
  local skill = Fk.skills[self.skill_name]
  if not skill then return false end
  local ret
  if skill:isInstanceOf(ActiveSkill) then
    ret = skill:feasible(self.selected_targets, self.pendings, player)
  elseif skill:isInstanceOf(ViewAsSkill) then
    local card = skill:viewAs(self.pendings)
    if card then
      local card_skill = card.skill ---@type ActiveSkill
      ret = card_skill:feasible(self.selected_targets, { card.id }, player, card)
    end
  end
  return ret
end

function ReqActiveSkill:isCancelable()
  return self.cancelable
end

function ReqActiveSkill:cardValidity(cid)
  local skill = Fk.skills[self.skill_name]
  if not skill then return false end
  return skill:cardFilter(cid, self.pendings)
end

function ReqActiveSkill:targetValidity(pid)
  local skill = Fk.skills[self.skill_name]
  if not skill then return false end
  return skill:targetFilter(pid, self.selected_targets, self.pendings)
end

function ReqActiveSkill:updateButtons()
  local scene = self.scene
  scene:update("Button", "OK", { enabled = not not self:feasible() })
  scene:update("Button", "Cancel", { enabled = not not self:isCancelable() })
end

function ReqActiveSkill:updateUnselectedCards()
  local scene = self.scene

  for cid, item in pairs(scene:getAllItems("CardItem")) do
    if not item.selected then
      scene:update("CardItem", cid, { enabled = not not self:cardValidity(cid) })
    end
  end
end

function ReqActiveSkill:updateUnselectedTargets()
  local scene = self.scene

  for pid, item in pairs(scene:getAllItems("Photo")) do
    if not item.selected then
      scene:updateTargetEnability(pid, self:targetValidity(pid))
    end
  end
end

-- FIXME: 想办法换个名
function ReqActiveSkill:updateTargetsAfterCardSelected()
  local room = self.room
  local scene = self.scene
  local skill = Fk.skills[self.skill_name]
  if skill:isInstanceOf(ViewAsSkill) then
    local card = skill:viewAs(self.pendings)
    if card then skill = card.skill else skill = nil end
  end

  self.selected_targets = {}
  scene:unselectAllTargets()
  if skill then
    self:updateUnselectedTargets()
  else
    scene:disableAllTargets()
  end
  self:updateButtons()
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

-- 对点击卡牌的处理。data中包含selected属性，可能是选中或者取消选中，分开考虑。
function ReqActiveSkill:selectCard(cardid, data)
  local scene = self.scene
  local selected = data.selected
  scene:update("CardItem", cardid, data)

  -- 若选中，则加入已选列表；若取消选中，则其他牌可能无法满足可选条件，需额外判断
  -- 例如周善 选择包括“安”在内的任意张手牌交出
  if selected then
    table.insert(self.pendings, cardid)
  else
    local old_pendings = table.simpleClone(self.pendings)
    self.pendings = {}
    for _, cid in ipairs(old_pendings) do
      local ret = cid ~= cardid and self:cardValidity(cid)
      if ret then table.insert(self.pendings, cid) end
      -- 因为这里而变成未选中的牌稍后将更新一次enable 但是存在着冗余的cardFilter调用
      scene:update("CardItem", cid, { selected = not not ret })
    end
  end

  -- 最后刷新未选牌的enable属性
  self:updateUnselectedCards()
end

-- 对点击角色的处理。data中包含selected属性，可能是选中或者取消选中。
function ReqActiveSkill:selectTarget(playerid, data)
  local scene = self.scene
  local selected = data.selected
  local skill = Fk.skills[self.skill_name]
  scene:update("Photo", playerid, data)
  -- 发生以下Viewas判断时已经是因为选角色触发的了，说明肯定有card了，这么写不会出事吧？
  if skill:isInstanceOf(ViewAsSkill) then
    skill = skill:viewAs(self.pendings).skill
  end

  -- 类似选卡
  if selected then
    table.insert(self.selected_targets, playerid)
  else
    local old_targets = table.simpleClone(self.selected_targets)
    self.selected_targets = {}
    scene:unselectAllTargets()
    for _, pid in ipairs(old_targets) do
      local ret = pid ~= playerid and self:targetValidity(pid)
      if ret then table.insert(self.selected_targets, pid) end
      scene:update("Photo", pid, { selected = not not ret })
    end
  end

  self:updateUnselectedTargets()
  self:updateButtons()
end

function ReqActiveSkill:update(elemType, id, action, data)
  if elemType == "Button" then
    if id == "OK" then self:doOKButton()
    elseif id == "Cancel" then self:doCancelButton() end
    return true
  elseif elemType == "CardItem" then
    self:selectCard(id, data)
    self:updateTargetsAfterCardSelected()
  elseif elemType == "Photo" then
    self:selectTarget(id, data)
  end
end

return ReqActiveSkill
