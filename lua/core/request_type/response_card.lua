local RoomScene = require 'ui_emu.roomscene'
local ReqActiveSkill = require 'core.request_type.active_skill'

---@class ReqResponseCard: ReqActiveSkill
---@field public selected_card? Card 使用一张牌时会用到 支持锁视技
---@field public pattern string 请求格式
local ReqResponseCard = ReqActiveSkill:subclass("ReqResponseCard")

function ReqResponseCard:initialize(player)
  ReqActiveSkill.initialize(self, player)
  self.scene = RoomScene:new(self)
end

-- 这种具体的合法性分析代码要不要单独放到某个模块呢
---@param player Player @ 使用者
---@param card Card @ 目标卡牌
---@param data? any @ 额外数据?
function ReqResponseCard:canUseCard(player, card, data)
  -- TODO: 补全判断逻辑
  -- 若需要其他辅助函数的话在这个文件进行local
  local exp = Exppattern:Parse(self.pattern)
  return not player:prohibitResponse(card) and exp:match(card)
end

function ReqResponseCard:setup()
  self.change = ClientInstance and {} or nil
  local scene = self.scene
  local player = self.player
  p("setup response!")

  -- 准备牌堆
  self:updateCard()

  -- RoomScene.enableSkills();
  local vss = table.filter(player:getAllSkills(), function(s)
    return s:isInstanceOf(ViewAsSkill)
  end)
  ---@param skill ViewAsSkill
  for _, skill in ipairs(vss) do
    local ret = skill:enabledAtResponse(player, true)
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

function ReqResponseCard:updateCard(data)
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

function ReqResponseCard:doOKButton()
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

function ReqResponseCard:selectSkill(skill, data)
  local scene = self.scene
  local selected = data.selected
  scene:update("SkillButton", skill, data)

  if selected then
    self.skill_name = skill
    self.selected_card = nil
    ReqActiveSkill.updateCard(self)
    ReqActiveSkill.checkButton(self)
  else
    self.skill_name = nil
    self:updateCard()
    self:checkButton()
  end
end

function ReqResponseCard:selectCard(cid, data)
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

function ReqResponseCard:checkButton(data)
  local scene = self.scene
  local skill = Fk.skills[self.skill_name] ---@type ViewAsSkill
  local card = self.selected_card
  local dat = { enabled = false }
  -- 正在选技能
  if skill then
    card = skill:viewAs(self.pendings)
  end
  if card and self:canUseCard(self.player, card) then
    dat.enabled = true
  end
  scene:update("Button", "OK", dat)
end

function ReqResponseCard:update(elemType, id, action, data)
  self.change = ClientInstance and {} or nil
  if elemType == "Button" then
    if id == "OK" then self:doOKButton()
    elseif id == "Cancel" then self:doCancelButton() end
    return
  elseif elemType == "CardItem" then
    self:selectCard(id, data)
    self:checkButton(data)
  elseif elemType == "SkillButton" then
    self:selectSkill(id, data)
  end
  self.scene:notifyUI()
end

return ReqResponseCard
