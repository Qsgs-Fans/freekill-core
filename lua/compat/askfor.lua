---@class CompatAskFor: Object
local CompatAskFor = {} -- mixin

--- 询问player是否要发动一个主动技。
---
--- 如果发动的话，那么会执行一下技能的onUse函数，然后返回选择的牌和目标等。
---@param player ServerPlayer @ 询问目标
---@param skill_name string @ 主动技的技能名
---@param prompt? string @ 烧条上面显示的提示文本内容
---@param cancelable? boolean @ 是否可以点取消
---@param extra_data? table @ 额外信息，因技能而异了
---@param no_indicate? boolean @ 是否不显示指示线
---@return boolean, table? @ 返回第一个值为是否成功发动，第二值为技能选牌、目标等数据
---@deprecated
function CompatAskFor:askForUseActiveSkill(player, skill_name, prompt, cancelable, extra_data, no_indicate)
  prompt = prompt or ""
  cancelable = (cancelable == nil) and true or cancelable
  no_indicate = (no_indicate == nil) and true or no_indicate
  extra_data = extra_data or Util.DummyTable
  local skill = Fk.skills[skill_name]
  if not (skill and (skill:isInstanceOf(ActiveSkill) or skill:isInstanceOf(ViewAsSkill))) then
    print("Attempt ask for use non-active skill: " .. skill_name)
    return false
  end

  local command = "AskForUseActiveSkill"
  local data = {skill_name, prompt, cancelable, extra_data}

  Fk.currentResponseReason = extra_data.skillName
  local req = Request:new(player, command)
  req:setData(player, data)
  req.focus_text = extra_data.skillName or skill_name
  local result = req:getResult(player)
  Fk.currentResponseReason = nil

  if result == "" then
    return false
  end

  data = result
  local card = data.card
  local targets = data.targets
  local card_data = card
  local selected_cards = card_data.subcards
  local interaction
  if not no_indicate then
    self:doIndicate(player.id, targets)
  end

  if skill.interaction then
    interaction = data.interaction_data
    skill.interaction.data = interaction
  end

  if skill:isInstanceOf(ActiveSkill) and not extra_data.skipUse then
    skill:onUse(self, SkillUseData:new {
      from = player,
      cards = selected_cards,
      tos = table.map(targets, Util.Id2PlayerMapper),
    })
  end

  return true, {
    cards = selected_cards,
    targets = targets,
    interaction = interaction
  }
end

---@deprecated
CompatAskFor.askForUseViewAsSkill = CompatAskFor.askForUseActiveSkill

return CompatAskFor
