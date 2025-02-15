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

  local params = { ---@type AskToDiscardParams
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

  local params = { ---@type AskToChoosePlayersParams
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

  local params = { ---@type AskToCardsParams
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

  local params = { ---@type AskToChooseCardAndPlayersParams
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

  local params = { ---@type AskToChooseCardsAndPlayersParams
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

  local params = { ---@type AskToYijiParams
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

  local params = { ---@type AskToChooseGeneralParams
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

  local params = { ---@type AskToChooseCardParams
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

  local params = { ---@type AskToPoxiParams
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

  local params = { ---@type AskToChooseCardsParams
    min = min,
    max = max,
    target = target,
    flag = flag,
    skill_name = reason,
    prompt = prompt
  }

  return self:askToChooseCards(chooser, params)
end

--- 询问一名玩家从众多选项中选择一个。
---@param player ServerPlayer @ 要询问的玩家
---@param choices string[] @ 可选选项列表
---@param skill_name? string @ 技能名
---@param prompt? string @ 提示信息
---@param detailed? boolean @ 选项详细描述
---@param all_choices? string[] @ 所有选项（不可选变灰）
---@return string @ 选择的选项
---@deprecated
function CompatAskFor:askForChoice(player, choices, skill_name, prompt, detailed, all_choices)
  local params = { ---@type AskToChoiceParams
    choices = choices,
    skill_name = skill_name,
    prompt = prompt,
    detailed = detailed,
    all_choices = all_choices
  }

  return self:askToChoice(player, params)
end

--- 询问一名玩家从众多选项中勾选任意项。
---@param player ServerPlayer @ 要询问的玩家
---@param choices string[] @ 可选选项列表
---@param minNum number @ 最少选择项数
---@param maxNum number @ 最多选择项数
---@param skill_name? string @ 技能名
---@param prompt? string @ 提示信息
---@param cancelable? boolean @ 是否可取消
---@param detailed? boolean @ 选项详细描述
---@param all_choices? string[] @ 所有选项（不可选变灰）
---@return string[] @ 选择的选项
---@deprecated
function CompatAskFor:CompatAskFor(player, choices, minNum, maxNum, skill_name, prompt, cancelable, detailed, all_choices)
  cancelable = (cancelable == nil) and true or cancelable
  local params = { ---@type AskToChoiceParams
    choices = choices,
    min_num = minNum,
    max_num = maxNum,
    skill_name = skill_name,
    prompt = prompt,
    detailed = detailed,
    all_choices = all_choices
  }

  return self:askToChoices(player, params)
end

--- 询问玩家是否发动技能。
---@param player ServerPlayer @ 要询问的玩家
---@param skill_name string @ 技能名
---@param data? any @ 未使用
---@param prompt? string @ 提示信息
---@return boolean
---@deprecated
function CompatAskFor:askForSkillInvoke(player, skill_name, data, prompt)
  local params = { ---@type AskToSkillInvokeParams
    skill_name = skill_name,
    prompt = prompt,
  }

  return self:askToSkillInvoke(player, params)
end

--- 询问玩家在自定义大小的框中排列卡牌（观星、交换、拖拽选牌）
---@param player ServerPlayer @ 要询问的玩家
---@param skillname string @ 烧条技能名
---@param cardMap any @ { "牌堆1卡表", "牌堆2卡表", …… }
---@param prompt? string @ 操作提示
---@param box_size? integer @ 数值对应卡牌平铺张数的最大值，为0则有单个卡位，每张卡占100单位长度，默认为7
---@param max_limit? integer[] @ 每一行牌上限 { 第一行, 第二行，…… }，不填写则不限
---@param min_limit? integer[] @ 每一行牌下限 { 第一行, 第二行，…… }，不填写则不限
---@param free_arrange? boolean @ 是否允许自由排列第一行卡的位置，默认不能
---@param pattern? string @ 控制第一行卡牌是否可以操作，不填写默认均可操作
---@param poxi_type? string @ 控制每张卡牌是否可以操作、确定键是否可以点击，不填写默认均可操作
---@param default_choice? table[] @ 超时的默认响应值，在带poxi_type时需要填写
---@return table[] @ 排列后的牌堆结果
---@deprecated
function CompatAskFor:askForArrangeCards(player, skillname, cardMap, prompt, free_arrange, box_size, max_limit, min_limit, pattern, poxi_type, default_choice)
  prompt = prompt or ""
  local areaNames = {}
  if type(cardMap[1]) == "number" then
    cardMap = {cardMap}
  else
    for i = #cardMap, 1, -1 do
      if type(cardMap[i]) == "string" then
        table.insert(areaNames, 1, cardMap[i])
        table.remove(cardMap, i)
      end
    end
  end
  if #areaNames == 0 then
    areaNames = {skillname, "toObtain"}
  end
  box_size = box_size or 7
  max_limit = max_limit or {#cardMap[1], #cardMap > 1 and #cardMap[2] or #cardMap[1]}
  min_limit = min_limit or {0, 0}
  for _ = #cardMap + 1, #min_limit, 1 do
    table.insert(cardMap, {})
  end
  pattern = pattern or "."
  poxi_type = poxi_type or ""
  local params = { ---@type AskToArrangeCardsParams
    skill_name = skillname,
    card_map = cardMap,
    prompt = prompt,
    free_arrange = free_arrange,
    box_size = box_size,
    max_limit = max_limit,
    min_limit = min_limit,
    pattern = pattern,
    poxi_type = poxi_type,
    default_choice = default_choice
  }

  return self:askToArrangeCards(player, params)
end

-- TODO: guanxing type
--- 询问玩家对若干牌进行观星。
---
--- 观星完成后，相关的牌会被置于牌堆顶或者牌堆底。所以这些cards最好不要来自牌堆，一般先用getNCards从牌堆拿出一些牌。
---@param player ServerPlayer @ 要询问的玩家
---@param cards integer[] @ 可以被观星的卡牌id列表
---@param top_limit? integer[] @ 置于牌堆顶的牌的限制(下限,上限)，不填写则不限
---@param bottom_limit? integer[] @ 置于牌堆底的牌的限制(下限,上限)，不填写则不限
---@param customNotify? string @ 自定义读条操作提示
---param prompt? string @ 观星框的标题(暂时雪藏)
---@param noPut? boolean @ 是否进行放置牌操作
---@param areaNames? string[] @ 左侧提示信息
---@return table<"top"|"bottom", integer[]> @ 左侧提示信息
function CompatAskFor:askForGuanxing(player, cards, top_limit, bottom_limit, customNotify, noPut, areaNames)
  -- 这一大堆都是来提前报错的
  local leng = #cards
  top_limit = top_limit or { 0, leng }
  bottom_limit = bottom_limit or { 0, leng }
  if #top_limit > 0 then
    assert(top_limit[1] >= 0 and top_limit[2] >= 0, "limits error: The lower limit should be greater than 0")
    assert(top_limit[1] <= top_limit[2], "limits error: The upper limit should be less than the lower limit")
  end
  if #bottom_limit > 0 then
    assert(bottom_limit[1] >= 0 and bottom_limit[2] >= 0, "limits error: The lower limit should be greater than 0")
    assert(bottom_limit[1] <= bottom_limit[2], "limits error: The upper limit should be less than the lower limit")
  end
  if #top_limit > 0 and #bottom_limit > 0 then
    assert(leng >= top_limit[1] + bottom_limit[1] and leng <= top_limit[2] + bottom_limit[2], "limits Error: No enough space")
  end
  if areaNames then
    assert(#areaNames == 2, "areaNames error: Should have 2 elements")
  else
    areaNames =  { "Top", "Bottom" }
  end
  local params = { ---@type AskToGuanxingParams
    cards = cards,
    top_limit = top_limit,
    bottom_limit = bottom_limit,
    skill_name = customNotify,
    skip = noPut,
    area_names = areaNames
  }

  return self:askToGuanxing(player, params)
end

--- 询问玩家任意交换几堆牌堆。
---
---@param player ServerPlayer @ 要询问的玩家
---@param piles integer[][] @ 卡牌id列表的列表，也就是……几堆牌堆的集合
---@param piles_name string[] @ 牌堆名，不足部分替换为“牌堆1、牌堆2...”
---@param customNotify? string @ 自定义读条操作提示
---@return integer[][] @ 交换后的结果
function CompatAskFor:askForExchange(player, piles, piles_name, customNotify)
  piles_name = piles_name or Util.DummyTable
  local x = #piles - #piles_name
  if x > 0 then
    for i = 1, x, 1 do
      table.insert(piles_name, Fk:translate("Pile") .. i)
    end
  elseif x < 0 then
    piles_name = table.slice(piles_name, 1, #piles + 1)
  end
  local params = { ---@type AskToExchangeParams
    piles = piles,
    piles_name = piles_name,
    skill_name = customNotify,
  }

  return self:askToExchange(player, params)
end


return CompatAskFor
