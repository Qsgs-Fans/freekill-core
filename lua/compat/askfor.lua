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

  local params = { ---@type AskToUseActiveSkillParams
    skill_name = skill_name,
    prompt = prompt,
    cancelable = cancelable,
    extra_data = extra_data,
    no_indicate = no_indicate,
  }
  local success, ret = self:askToUseActiveSkill(player, params)
  if ret then
    ret.targets = table.map(ret.targets, Util.IdMapper)
  end
  return success, ret
end

---@deprecated
CompatAskFor.askForUseViewAsSkill = CompatAskFor.askForUseActiveSkill

--- 询问一名角色弃牌。
---
--- 在这个函数里面牌已经被弃掉了（除非skipDiscard为true）。
---@param player ServerPlayer @ 弃牌角色
---@param minNum integer @ 最小值
---@param maxNum integer @ 最大值
---@param includeEquip? boolean @ 能不能弃装备区？
---@param skillName? string @ 引发弃牌的技能名
---@param cancelable? boolean @ 能不能点取消？
---@param pattern? string @ 弃牌需要符合的规则
---@param prompt? string @ 提示信息
---@param skipDiscard? boolean @ 是否跳过弃牌（即只询问选择可以弃置的牌）
---@param no_indicate? boolean @ 是否不显示指示线
---@return integer[] @ 弃掉的牌的id列表，可能是空的
---@deprecated
function CompatAskFor:askForDiscard(player, minNum, maxNum, includeEquip, skillName, cancelable, pattern, prompt, skipDiscard, no_indicate)
  cancelable = (cancelable == nil) and true or cancelable
  no_indicate = no_indicate or false
  pattern = pattern or "."

  local params = { ---@type askToDiscardParams
    min_num = minNum,
    max_num = maxNum,
    include_equip = includeEquip,
    skill_name = skillName,
    cancelable = cancelable,
    pattern = pattern,
    prompt = prompt or ("#AskForDiscard:::" .. maxNum .. ":" .. minNum),
    skip = skipDiscard,
    no_indicate = no_indicate
  }
  return self:askToDiscard(player, params)
end

--- 询问一名玩家从targets中选择若干名玩家出来。
---@param player ServerPlayer @ 要做选择的玩家
---@param targets integer[] @ 可以选的目标范围，是玩家id数组
---@param minNum integer @ 最小值
---@param maxNum integer @ 最大值
---@param prompt? string @ 提示信息
---@param skillName? string @ 技能名
---@param cancelable? boolean @ 能否点取消，默认可以
---@param no_indicate? boolean @ 是否不显示指示线
---@param targetTipName? string @ 引用的选择目标提示的函数名
---@param extra_data? table @额外信息
---@return integer[] @ 选择的玩家id列表，可能为空
---@deprecated
function CompatAskFor:askForChoosePlayers(player, targets, minNum, maxNum, prompt, skillName, cancelable, no_indicate, targetTipName, extra_data)
  if maxNum < 1 then
    return {}
  end
  cancelable = (cancelable == nil) and true or cancelable
  no_indicate = no_indicate or false

  local params = { ---@type askToChoosePlayersParams
    targets = table.map(targets, Util.Id2PlayerMapper),
    min_num = minNum,
    max_num = maxNum,
    prompt = prompt or "",
    skill_name = skillName,
    cancelable = cancelable,
    extra_data = extra_data,
    target_tip_name = targetTipName,
    no_indicate = no_indicate
  }
  return table.map(self:askToChoosePlayers(player, params), Util.IdMapper)
end

--- 询问一名玩家选择自己的几张牌。
---
--- 与askForDiscard类似，但是不对选择的牌进行操作就是了。
---@param player ServerPlayer @ 要询问的玩家
---@param minNum integer @ 最小值
---@param maxNum integer @ 最大值
---@param includeEquip? boolean @ 能不能选装备
---@param skillName? string @ 技能名
---@param cancelable? boolean @ 能否点取消
---@param pattern? string @ 选牌规则
---@param prompt? string @ 提示信息
---@param expand_pile? string|integer[] @ 可选私人牌堆名称，或额外可选牌
---@param no_indicate? boolean @ 是否不显示指示线
---@return integer[] @ 选择的牌的id列表，可能是空的
---@deprecated
function CompatAskFor:askForCard(player, minNum, maxNum, includeEquip, skillName, cancelable, pattern, prompt, expand_pile, no_indicate)
  if maxNum < 1 then
    return {}
  end
  cancelable = (cancelable == nil) and true or cancelable
  no_indicate = no_indicate or false
  pattern = pattern or (includeEquip and "." or ".|.|.|hand")
  prompt = prompt or ("#AskForCard:::" .. maxNum .. ":" .. minNum)

  local params = { ---@type askToDiscardParams
    min_num = minNum,
    max_num = maxNum,
    include_equip = includeEquip,
    skill_name = skillName,
    cancelable = cancelable,
    pattern = pattern,
    prompt = prompt,
    expand_pile = expand_pile,
    no_indicate = no_indicate
  }
  return self:askToChooseCards(player, params)
end

--- 询问玩家选择1张牌和若干名角色。
---
--- 返回两个值，第一个是选择的目标列表，第二个是选择的那张牌的id
---@param player ServerPlayer @ 要询问的玩家
---@param targets integer[] @ 选择目标的id范围
---@param minNum integer @ 选目标最小值
---@param maxNum integer @ 选目标最大值
---@param pattern? string @ 选牌规则
---@param prompt? string @ 提示信息
---@param cancelable? boolean @ 能否点取消
---@param no_indicate? boolean @ 是否不显示指示线
---@param targetTipName? string @ 引用的选择目标提示的函数名
---@param extra_data? table @额外信息
---@return integer[], integer?
function CompatAskFor:askForChooseCardAndPlayers(player, targets, minNum, maxNum, pattern, prompt, skillName, cancelable, no_indicate, targetTipName, extra_data)
  if maxNum < 1 then
    return {}
  end
  cancelable = (cancelable == nil) and true or cancelable
  no_indicate = no_indicate or false
  pattern = pattern or "."

  local params = { ---@type askToChooseCardAndPlayersParams
    targets = table.map(targets, Util.Id2PlayerMapper),
    min_num = minNum,
    max_num = maxNum,
    pattern = pattern,
    prompt = prompt or "",
    skill_name = skillName,
    cancelable = cancelable,
    extra_data = extra_data,
    target_tip_name = targetTipName,
    no_indicate = no_indicate
  }
  local selected, cardid = self:askToChooseCardAndPlayers(player, params)
  if #selected ~= 0 then
    selected = table.map(selected, Util.IdMapper)
  end
  return selected, cardid
end

return CompatAskFor
