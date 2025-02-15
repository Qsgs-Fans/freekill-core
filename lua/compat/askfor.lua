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

  local params = { ---@type askToCardsParams
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
  return self:askToCards(player, params)
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
---@deprecated
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

--- 询问玩家选择X张牌和Y名角色。
---
--- 返回两个值，第一个是选择目标id列表，第二个是选择的牌id列表，第三个是否按了确定
---@param player ServerPlayer @ 要询问的玩家
---@param minCardNum integer @ 选卡牌最小值
---@param maxCardNum integer @ 选卡牌最大值
---@param targets integer[] @ 选择目标的id范围
---@param minTargetNum integer @ 选目标最小值
---@param maxTargetNum integer @ 选目标最大值
---@param pattern? string @ 选牌规则
---@param prompt? string @ 提示信息
---@param cancelable? boolean @ 能否点取消
---@param no_indicate? boolean @ 是否不显示指示线
---@param extra_data? table @额外信息
---@return integer[], integer[], boolean @ 第一个是选择目标id列表，第二个是选择的牌id列表，第三个是否按了确定
---@deprecated
function CompatAskFor:askForChooseCardsAndPlayers(player, minCardNum, maxCardNum, targets, minTargetNum, maxTargetNum, pattern, prompt, skillName, cancelable, no_indicate, targetTipName, extra_data)
  cancelable = (cancelable == nil) and true or cancelable
  no_indicate = no_indicate or false
  pattern = pattern or "."

  local params = { ---@type askToChooseCardsAndPlayersParams
    targets = table.map(targets, Util.Id2PlayerMapper),
    min_card_num = minCardNum,
    max_card_num = maxCardNum,
    min_num = minTargetNum,
    max_num = maxTargetNum,
    pattern = pattern,
    prompt = prompt or "",
    skill_name = skillName,
    cancelable = cancelable,
    extra_data = extra_data,
    target_tip_name = targetTipName,
    no_indicate = no_indicate
  }
  local selected, cards, bool = self:askToChooseCardsAndPlayers(player, params)
  if #selected ~= 0 then
    selected = table.map(selected, Util.IdMapper)
  end
  return selected, cards, bool
end

--- 询问将卡牌分配给任意角色。
---@param player ServerPlayer @ 要询问的玩家
---@param cards? integer[] @ 要分配的卡牌。默认拥有的所有牌
---@param targets? ServerPlayer[] @ 可以获得卡牌的角色。默认所有存活角色
---@param skillName? string @ 技能名，影响焦点信息。默认为“分配”
---@param minNum? integer @ 最少交出的卡牌数，默认0
---@param maxNum? integer @ 最多交出的卡牌数，默认所有牌
---@param prompt? string @ 询问提示信息
---@param expand_pile? string|integer[] @ 可选私人牌堆名称，如要分配你武将牌上的牌请填写
---@param skipMove? boolean @ 是否跳过移动。默认不跳过
---@param single_max? integer|table @ 限制每人能获得的最大牌数。输入整数或(以角色id为键以整数为值)的表
---@return table<integer, integer[]> @ 返回一个表，键为角色id，值为分配给其的牌id数组
---@deprecated
function CompatAskFor:askForYiji(player, cards, targets, skillName, minNum, maxNum, prompt, expand_pile, skipMove, single_max)
  targets = targets or self.alive_players
  cards = cards or player:getCardIds("he")
  skillName = skillName or "distribution_select_skill"
  minNum = minNum or 0
  maxNum = maxNum or #cards

  local params = { ---@type askToYijiParams
    targets = targets,
    min_num = minNum,
    max_num = maxNum,
    prompt = prompt or "",
    skill_name = skillName,
    expand_pile = expand_pile,
    skip = skipMove,
    single_max = single_max
  }

  return self:askToYiji(player, params)
end

--- 询问玩家选择一名武将。
---@param player ServerPlayer @ 询问目标
---@param generals string[] @ 可选武将
---@param n integer @ 可选数量，默认为1
---@param noConvert? boolean @ 可否变更，默认可
---@return string|string[] @ 选择的武将
---@deprecated
function CompatAskFor:askForGeneral(player, generals, n, noConvert)
  n = n or 1

  local params = { ---@type askToChooseGeneralParams
    generals = generals,
    n = n,
    no_convert = noConvert
  }
  return self:askToChooseGeneral(player, params)
end

--- 询问玩家若为神将、双势力需选择一个势力。
---@param players? ServerPlayer[] @ 询问目标
---@deprecated
function CompatAskFor:askForChooseKingdom(players)
  return self:askToChooseKingdom(players)
end

--- 询问chooser，选择target的一张牌。
---@param chooser ServerPlayer @ 要被询问的人
---@param target ServerPlayer @ 被选牌的人
---@param flag any @ 用"hej"三个字母的组合表示能选择哪些区域, h 手牌区, e - 装备区, j - 判定区
---@param reason string @ 原因，一般是技能名
---@param prompt? string @ 提示信息
---@return integer @ 选择的卡牌id
---@deprecated
function CompatAskFor:askForCardChosen(chooser, target, flag, reason, prompt)
  prompt = prompt or ""

  local params = { ---@type askToChooseCardParams
    target = target,
    flag = flag,
    skill_name = reason,
    prompt = prompt
  }

  return self:askToChooseCard(chooser, params)
end

--- 谋askForCardsChosen，需使用Fk:addPoxiMethod定义好方法
---
--- 选卡规则和返回值啥的全部自己想办法解决，data填入所有卡的列表（类似ui.card_data）
---
--- 注意一定要返回一个表，毕竟本质上是选卡函数
---@param player ServerPlayer @ 要被询问的人
---@param poxi_type string @ poxi关键词
---@param data any @ 牌堆信息
---@param extra_data any @ 额外信息
---@param cancelable? boolean @ 是否可取消
---@return integer[] @ 选择的牌ID数组
---@deprecated
function CompatAskFor:askForPoxi(player, poxi_type, data, extra_data, cancelable)
  cancelable = (cancelable == nil) and true or cancelable

  local params = { ---@type askToPoxiParams
    poxi_type = poxi_type,
    data = data,
    extra_data = extra_data,
    cancelable = cancelable
  }

  return self:askToPoxi(player, params)
end

--- 完全类似askForCardChosen，但是可以选择多张牌。
--- 相应的，返回的是id的数组而不是单个id。
---@param chooser ServerPlayer @ 要被询问的人
---@param target ServerPlayer @ 被选牌的人
---@param min integer @ 最小选牌数
---@param max integer @ 最大选牌数
---@param flag any @ 用"hej"三个字母的组合表示能选择哪些区域, h 手牌区, e - 装备区, j - 判定区
---可以通过flag.card_data = {{牌堆1名, 牌堆1ID表},...}来定制能选择的牌
---@param reason string @ 原因，一般是技能名
---@param prompt? string @ 提示信息
---@return integer[] @ 选择的id
---@deprecated
function CompatAskFor:askForCardsChosen(chooser, target, min, max, flag, reason, prompt)
  prompt = prompt or ""

  local params = { ---@type askToChooseCardsParams
    min = min,
    max = max,
    target = target,
    flag = flag,
    skill_name = reason,
    prompt = prompt
  }

  return self:askToChooseCards(chooser, params)
end


return CompatAskFor
