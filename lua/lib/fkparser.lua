-- FreeKill's fkparse interface
-- fkparse (FreeKill parser), a game code generator
-- For license information, check generated lua files.

-- In most cases, fk's basic modules are loaded before extension calls
-- "require 'fkparser'", so we needn't to import lua modules here.

local string2suit = {
  spade = Card.Spade,
  club = Card.Club,
  heart = Card.Heart,
  diamond = Card.Diamond,
  no_suit = Card.NoSuit,
  no_suit_black = Card.NoSuitBlack,
  no_suit_red = Card.NoSuitRed,
}

local fkp = { functions = {} }

fkp.functions.prepend = function(arr, e) table.insert(arr, 1, e) end
fkp.functions.append = function(arr, e) table.insert(arr, e) end
fkp.functions.drawCards = function(p, n) p:drawCards(n) end
fkp.functions.loseHp = function(p, n) p.room:loseHp(p, n) end
fkp.functions.loseMaxHp = function(p, n) p.room:changeMaxHp(p, -n) end
fkp.functions.damage = function(from, to, n, nature, card, reason)
  local damage = {}
  damage.from = from
  damage.to = to
  damage.damage = n
  damage.damageType = nature
  damage.card = card
  damage.skillName = reason
  to.room:damage(damage)
end

fkp.functions.recover = function(player, int, who, card)
  local recover = {}
  recover.who = player
  recover.num = int
  recover.recoverBy = who
  recover.card = card
  player.room:recover(recover)
end

fkp.functions.recoverMaxHp = function(p, n) p.room:changeMaxHp(p, n) end
fkp.functions.acquireSkill = function(player, skill)
  player.room:handleAddLoseSkills(player, skill)
end

fkp.functions.loseSkill = function(player, skill)
  player.room:handleAddLoseSkills(player, "-" .. skill)
end

fkp.functions.addMark = function(player, mark, count, hidden)
  local room = player.room
  if hidden then
    mark = string.gsub(mark, "@", "_")
  end

  room:addPlayerMark(player, mark, count)
end

fkp.functions.loseMark = function(player, mark, count, hidden)
  local room = player.room
  if hidden then
    mark = string.gsub(mark, "@", "_")
  end

  room:removePlayerMark(player, mark, count)
end

fkp.functions.getMark = function(player, mark, hidden)
  if hidden then
    mark = string.gsub(mark, "@", "_")
  end

  return player:getMark(mark)
end

--- 判断列表A与列表B是否作为有序多元组（均从下标1开始访问且不考察其它类型的索引）相等
---@param A table @ 前表
---@param B table @ 后表
---@return boolean @ 若参量类型不符则返回false。注：若某些元是表，则比对的是引用（类似指针）而非内容
function fkp.functions.isSequentiallyEqual(A, B)
  if (type(A) ~= 'table') or (type(B) ~= 'table') or (#A ~= #B) then return false
  elseif #A < 1 then return true
  end
  local e = true
  for i = 1, #A do e = (e and (A[i] == B[i]))
  end
  return e
end

--- 获取与给定列表作为有序多元组（均从下标1开始访问且不考察其它类型的索引）相等的“首个”键值在表A中的索引
---@param A table @ 前表
---@param Tuple table @ 列表
---@return any @ 返回“首个”符合要求的索引，未找到或参量类型不符则返回nil。注：若表A的某些键值的元或列表B的某些元是表，则比对的是引用（类似指针）而非内容
function fkp.functions.keyOfTuple(A, Tuple)
  if (type(A) ~= 'table') or (type(Tuple) ~= 'table') then return nil
  end
  for key, v in ipairs(A) do
    if fkp.functions.isSequentiallyEqual(v, Tuple) then return key
    end
  end
  return nil
end

--- 判断一组在胜负判断中视为未离场的角色是否连续相邻
---@param players Player[] @ 待判断的角色table
---@param ignoreRemoved? boolean @ 忽略被移除
---@param ignoreRest? boolean @ 是否忽略休整
---@return boolean|nil @ 若参量类型不符则返回nil
function fkp.functions.continuouslyNear(players, ignoreRemoved, ignoreRest)
  if type(players) ~= 'table' then return nil
  end
  local bottom1, b2, nm, ns  = false, false, not ignoreRemoved, not ignoreRest
  for _, p in ipairs(players) do
    b2 = b2 or (nm and p:isRemoved()) or (ns and (p.rest > 0)) or (bottom1 and not table.contains(players, p:getNextAlive(ignoreRemoved, 1, ignoreRest)))
    bottom1 = (bottom1 or not table.contains(players, p:getNextAlive(ignoreRemoved, 1, ignoreRest)))
  end
  return ((#players < 2) or not b2)
end

-- 获取有伤害值基数的所有<…牌>的trueName（牌名对应的内部名）或name，常用于生成pattern，也可用于实现类似神杀的getSlashNames功能
---@param card_type string @ 牌的类型：b 基本牌，t - 普通锦囊牌，d - 延时锦囊牌
---@param true_name? boolean @ 是否仅获取牌名（即不区分【杀】等的具体种类）对应的内部名，默认不获取
---@param is_derived? boolean @ 是否包括衍生牌，默认不包括
---@param DisabledPacks? boolean @ 是否包括已禁用的扩展包的卡牌，默认不包括
---@return string[] @ 返回{trueName或name}列表
fkp.functions.getDamageCardNames = function(card_type, true_name, is_derived, DisabledPacks)
  local names, normal_trick, delayed_trick  = {}, {}, {}
  for _, ca in ipairs(Fk.cards) do
    local b = ((DisabledPacks or not table.contains(Fk:currentRoom().disabled_packs, ca.package.name)) and (is_derived or not ca.is_derived))
    if b and ca.damage_type and (ca.type == Card.TypeBasic) and card_type:find("b") then table.insertIfNeed(names, true_name and ca.trueName or ca.name)
    elseif b and ca.damage_type and (ca.sub_type == Card.SubtypeDelayedTrick) then table.insertIfNeed(delayed_trick, true_name and ca.trueName or ca.name)
    elseif b and ca.damage_type and (ca.type == Card.TypeTrick) then table.insertIfNeed(normal_trick, true_name and ca.trueName or ca.name)
    end --and ca.is_damage_card then不会算闪电等；换言之，is_damage_card不是指“有伤害值基数”而是指“有伤害值基数且不为延时锦囊牌”
  end
  if card_type:find("t") then table.insertTable(names, normal_trick)
  end
  if card_type:find("d") then table.insertTable(names, delayed_trick)
  end
  return names
end

-- 获取牌名汉字数在给定集合内的所有<…牌>的trueName（牌名对应的内部名）或name，常用于生成pattern，也可实现包括已禁用的getBasicCardNames等功能（基本牌即牌名字数为1的牌）
---@param lengthTuple table<integer> @ 牌名汉字数须在此范围内（通常不超过7，故可用数组表示）。注：新月没有规则集中的特殊坐骑牌子类别，此处直接判断牌名（六龙骖驾）
---@param card_type string @ 牌的类型：b 基本牌，t - 普通锦囊牌，d - 延时锦囊牌，w - 武器牌，a - 防具牌，f - 防御坐骑牌，o - 进攻坐骑牌，l - 特殊坐骑牌，s - 宝物牌
---@param ol_rule? boolean @ OL服和谐【借刀杀人】，默认不和谐
---@param true_name? boolean @ 是否仅获取牌名（即不区分【杀】、【无懈可击】等的具体种类）对应的内部名，默认不获取。注：对牌名汉字数的判断恒ignoreSpecies，不受此值影响
---@param is_derived? boolean @ 是否包括衍生牌，默认不包括
---@param DisabledPacks? boolean @ 是否包括已禁用的扩展包的卡牌，默认不包括
---@param PassiveCards? boolean @ 是否包括【闪】、【金蝉脱壳】及【无懈可击】等仅能以牌为使用目标的卡牌，默认包括
---@return string[] @ 返回{trueName或name}列表
fkp.functions.getCardNamesByTrueNameLength = function(lengthTuple, card_type, ol_rule, true_name, is_derived, DisabledPacks, PassiveCards)
  local names, normal_trick, delayed_trick, weapon, armor, defensiveRide, offensiveRide, specialRide, treasure  = {}, {}, {}, {}, {}, {}, {}, {}, {}
  for _, ca in ipairs(Fk.cards) do
    local b = ((DisabledPacks or not table.contains(Fk:currentRoom().disabled_packs, ca.package.name)) and ((PassiveCards ~= false) or not ca.is_passive))
    b = (b and (is_derived or not ca.is_derived) and table.contains(lengthTuple, ca:getNameLength(ol_rule)))
    if b and (ca.type == Card.TypeBasic) and card_type:find("b") then table.insertIfNeed(names, true_name and ca.trueName or ca.name)
    elseif b and (ca.sub_type == Card.SubtypeDelayedTrick) then table.insertIfNeed(delayed_trick, true_name and ca.trueName or ca.name)
    elseif b and (ca.type == Card.TypeTrick) then table.insertIfNeed(normal_trick, true_name and ca.trueName or ca.name)
    elseif b and (ca.sub_type == Card.SubtypeWeapon) then table.insertIfNeed(weapon, true_name and ca.trueName or ca.name)
    elseif b and (ca.sub_type == Card.SubtypeArmor) then table.insertIfNeed(armor, true_name and ca.trueName or ca.name)
    elseif b and (ca.name == "liulongcanjia") then table.insertIfNeed(specialRide, "liulongcanjia")
    elseif b and (ca.sub_type == Card.SubtypeDefensiveRide) then table.insertIfNeed(defensiveRide, true_name and ca.trueName or ca.name)
    elseif b and (ca.sub_type == Card.SubtypeOffensiveRide) then table.insertIfNeed(offensiveRide, true_name and ca.trueName or ca.name)
    elseif b and (ca.sub_type == Card.SubtypeTreasure) then table.insertIfNeed(treasure, true_name and ca.trueName or ca.name)
    end
  end
  if card_type:find("t") then table.insertTable(names, normal_trick)
  end
  if card_type:find("d") then table.insertTable(names, delayed_trick)
  end
  if card_type:find("w") then table.insertTable(names, weapon)
  end
  if card_type:find("a") then table.insertTable(names, armor)
  end
  if card_type:find("f") then table.insertTable(names, defensiveRide)
  end
  if card_type:find("o") then table.insertTable(names, offensiveRide)
  end
  if card_type:find("l") then table.insertTable(names, specialRide)
  end
  if card_type:find("s") then table.insertTable(names, treasure)
  end
  return names
end

fkp.functions.judge = function(player, reason, pattern, good, play_animation)
  local judge = {}
  judge.who = player
  judge.reason = reason
  judge.pattern = pattern
  -- judge.good = good
  -- judge.play_animation = play_animation
  player.room:judge(judge)
  return judge.card
end

fkp.functions.retrial = function(card, player, judge, skill_name, exchange)
  local room = player.room
  return room:retrial(card, player, judge, skill_name, exchange)
end

fkp.functions.hasSkill = function(p, s) return p:hasSkill(s) end
fkp.functions.turnOver = function(p) p:turnOver() end
fkp.functions.distanceTo = function(p1, p2) return p1:distanceTo(p2) end
fkp.functions.getCards = function(p, area)
  return table.map(p:getCardIds(area), function(id) return Fk:getCardById(id) end)
end

-- interactive methods

fkp.functions.buildPrompt = function(base, src, dest, arg, arg2)
  if src == nil then
    src = ""
  else
    src = src.id
  end
  if dest == nil then
    dest = ""
  else
    dest = dest.id
  end
  if arg == nil then arg = "" end
  if arg2 == nil then arg2 = "" end

  local prompt_tab = {src, dest, arg, arg2}
  if arg2 == "" then
    table.remove(prompt_tab, 4)
    if arg == "" then
      table.remove(prompt_tab, 3)
      if dest == "" then
        table.remove(prompt_tab, 2)
        if src == "" then
          table.remove(prompt_tab, 1)
        end
      end
    end
  end

  for _, str in ipairs(prompt_tab) do
    base = base .. ":" .. str
  end

  return base
end

fkp.functions.askForChoice = function(player, choices, reason)
  return player.room:askForChoice(player, choices, reason)
end

fkp.functions.askForPlayerChosen = function(player, targets, reason, prompt, optional, notify)
  return player.room:askForChoosePlayers(player, targets, 1, 1, prompt, reason)
end

fkp.functions.askForSkillInvoke = function(player, skill)
  return player:askForSkillInvoke(skill)
end

fkp.functions.askRespondForCard = function(player, pattern, prompt, isRetrial, skill_name)
  return player.room:askForResponse(player, skill_name, pattern, prompt, true)
end

-- skill prototypes
--------------------------------------------

fkp.CreateTriggerSkill = function(spec)
  local eve = {}
  local refresh_eve = {}
  local specs = spec.specs
  local re_specs = spec.refresh_specs
  for event, _ in pairs(specs) do
    table.insert(eve, event)
  end
  for event, _ in pairs(re_specs) do
    table.insert(refresh_eve, event)
  end
  return fk.CreateTriggerSkill{
    name = spec.name,
    frequency = spec.frequency or Skill.NotFrequent,
    events = eve,
    can_trigger = function(self, event, target, player, data)
      local func = specs[event] and specs[event][1] or nil
      if not func then
        return TriggerSkill.triggerable(self, event, target, player, data)
      end
      return func(self, target, player, data)
    end,
    on_trigger = function(self, event, target, player, data)
      local func = specs[event] and specs[event][4] or nil
      if not func then
        return TriggerSkill.trigger(self, event, target, player, data)
      end
      return func(self, target, player, data)
    end,
    on_cost = function(self, event, target, player, data)
      local func = specs[event] and specs[event][3] or nil
      if not func then
        return TriggerSkill.cost(self, event, target, player, data)
      end
      return func(self, target, player, data)
    end,
    on_use = function(self, event, target, player, data)
      local func = specs[event] and specs[event][2] or nil
      if not func then
        return TriggerSkill.use(self, event, target, player, data)
      end
      return func(self, target, player, data)
    end,

    refresh_events = refresh_eve,
    can_refresh = function(self, event, target, player, data)
      local func = re_specs[event] and re_specs[event][1] or nil
      if not func then
        return TriggerSkill.canRefresh(self, event, target, player, data)
      end
      return func(self, target, player, data)
    end,
    on_refresh = function(self, event, target, player, data)
      local func = re_specs[event] and re_specs[event][2] or nil
      if not func then
        return TriggerSkill.refresh(self, event, target, player, data)
      end
      return func(self, target, player, data)
    end,
  }
end

fkp.CreateActiveSkill = function(spec)
  return fk.CreateActiveSkill{
    name = spec.name,
    can_use = spec.can_use,
    card_filter = function(self, to_select, selected)
      local card = Fk:getCardById(to_select)
      local clist = {}
      for _, id in ipairs(selected) do
        table.insert(clist, Fk:getCardById(id))
      end
      return spec.card_filter(self, clist, card)
    end,
    target_filter = function(self, to_select, selected, cards)
      local room = Fk:currentRoom()
      local target = room:getPlayerById(to_select)
      local plist = {}
      for _, id in ipairs(selected) do
        table.insert(plist, room:getPlayerById(id))
      end
      local clist = {}
      for _, id in ipairs(cards) do
        table.insert(clist, Fk:getCardById(id))
      end
      return spec.target_filter(self, plist, target, clist)
    end,
    feasible = function(self, targets, cards)
      local room = Fk:currentRoom()
      local plist = {}
      for _, id in ipairs(targets) do
        table.insert(plist, room:getPlayerById(id))
      end
      local clist = {}
      for _, id in ipairs(cards) do
        table.insert(clist, Fk:getCardById(id))
      end
      return spec.feasible(self, plist, clist)
    end,
    on_use = function(self, room, use)
      local cards = use.cards
      local from = use.from
      local targets = use.tos
      local source = room:getPlayerById(from)
      local plist = {}
      for _, id in ipairs(targets) do
        table.insert(plist, room:getPlayerById(id))
      end
      local clist = {}
      for _, id in ipairs(cards) do
        table.insert(clist, Fk:getCardById(id))
      end
      return spec.on_use(self, source, plist, clist)
    end,
    on_effect = function(self, room, effect)
      -- TODO: active skill for card!
    end,
  }
end

fkp.functions.newVirtualCard = function(number, suit, name, subcards, skill)
  subcards = subcards or Util.DummyTable
  local ret = Fk:cloneCard(name, string2suit[suit], number)
  if not ret then
    ret = Fk:cloneCard("slash", string2suit[suit], number)
  end
  ret.skillName = skill
  ret:addSubcards(subcards)
  return ret
end

fkp.functions.buildPattern = function(names, suits, numbers)
  if not names then names = {"."} end
  if not suits then suits = {"."} end
  if not numbers then numbers = {"."} end

  names = table.concat(names, ",")
  suits = table.concat(suits, ",")
  numbers = table.concat(numbers, ",")
  return string.format("%s|%s|%s", names, numbers, suits)
end

fkp.CreateViewAsSkill = function(spec)
  return fk.CreateViewAsSkill{
    name = spec.name,
    card_filter = function(self, to_select, selected)
      local card = Fk:getCardById(to_select)
      local clist = {}
      for _, id in ipairs(selected) do
        table.insert(clist, Fk:getCardById(id))
      end
      return spec.card_filter(self, clist, card)
    end,
    view_as = function(self, cards)
      local clist = {}
      for _, c in ipairs(cards) do
        table.insert(clist, Fk:getCardById(c))
      end
      if spec.feasible(self, clist) then
        return spec.view_as(self, clist)
      end
      return nil
    end,
    enabled_at_play = spec.can_use,
    enabled_at_response = spec.can_response,
    pattern = table.concat(spec.response_patterns, ";"),
  }
end

fkp.CreateTargetModSkill = function(_spec)
  local spec = { name = _spec.name }
  local function getVCardFromActiveSkill(skill)
    if not string.find(skill.name, "_skill") then return 0 end
    local str = string.gsub(skill.name, "_skill", "")
    return Fk:cloneCard(str)
  end
  if _spec.residue_func then
    spec.residue_func = function(self, target, skill, scope, card)
      return _spec.residue_func(self, target, card or getVCardFromActiveSkill(skill))
    end
  end
  if _spec.distance_limit_func then
    spec.distance_limit_func = function(self, target, skill, card)
      return _spec.distance_limit_func(self, target, card or getVCardFromActiveSkill(skill))
    end
  end
  if _spec.extra_target_func then
    spec.extra_target_func = function(self, target, skill, card)
      return _spec.extra_target_func(self, target, card or getVCardFromActiveSkill(skill))
    end
  end
  return fk.CreateTargetModSkill(spec)
end

fkp.CreateFilterSkill = fk.CreateFilterSkill
fkp.CreateProhibitSkill = fk.CreateProhibitSkill
fkp.CreateDistanceSkill = fk.CreateDistanceSkill
fkp.CreateMaxCardsSkill = fk.CreateMaxCardsSkill
fkp.CreateAttackRangeSkill = fk.CreateAttackRangeSkill

return fkp
