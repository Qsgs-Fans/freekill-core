local exChooseSkill = fk.CreateSkill{
  name = "ex__choose_skill",
}

exChooseSkill:addEffect('active', {
  card_filter = function(self, player, to_select, selected)

    local b = ((#selected >= self.max_c_num) or (self.will_throw and player:prohibitDiscard(to_select)))
    b = (b or (self.pattern and (self.pattern ~= "") and not Exppattern:Parse(self.pattern):match(Fk:getCardById(to_select))))
    for _, id in ipairs(selected) do
      local L, c, t = Fk:getCardById(id):getNameLength() == Fk:getCardById(to_select):getNameLength(), Fk:getCardById(id), Fk:getCardById(to_select)
      local P, A, T, C, S, N = t.type == c.type, t.name == c.name, t.trueName == c.trueName, t.color == c.color, t.suit == c.suit, t:compareNumberWith(c)
      b = (((self.equalColor == false) and C) or (self.equalColor and not C) or ((self.equalNum == false) and N) or (self.equalNum and not N) or b)
      b = (((self.equalSuit == false) and S) or (self.equalSuit and not S) or ((self.equalType == false) and P) or (self.equalType and not P) or b)
      b = (((self.equalName == false) and A) or (self.equalName and not A) or ((self.equalTrueName == false) and T) or (self.equalTrueName and not T) or b)
      b = (((self.equalNameLength == false) and L) or (self.equalNameLength and not L) or b)
    end
    return ((table.contains(player:getCardIds("he"), to_select) or table.contains(self:getPile(player), to_select)) and not b)
  end,
  target_filter = function(self, player, to_select, selected, cards)

    local pids, s = table.connect(table.map(selected, Util.IdMapper), {to_select.id}), Card:getIdList(card)
    local d = ((not self.targetIdSets) or table.find(self.targetIdSets, function(tb) return fk.isSubOf(pids, tb) end))
    local f, t, o = player:distanceTo(to_select, nil, nil), to_select:distanceTo(player, nil, nil), to_select:getAttackRange()
    d = (d and (((not self.FromMeWithCardNum) or fk.compareNonNegativeNum(f, #s, self.FromMeWithCardNum)) and table.contains(self.targets, to_select.id)))
    d = (d and ((not self.ToMeWithCardNum) or fk.compareNonNegativeNum(t, #s, self.ToMeWithCardNum)) and (#selected < self.max_t_num))
    d = (d and ((not self.MaxHpWithCardNum) or fk.compareNum(to_select.maxHp, #s, self.MaxHpWithCardNum)))
    d = (d and ((not self.HpWithCardNum) or fk.compareNum(to_select.hp, #s, self.HpWithCardNum)))
    d = (d and ((not self.LostHpWithCardNum) or fk.compareNum(to_select:getLostHp(), #s, self.LostHpWithCardNum)))
    d = (d and ((not self.AreaCardNumWithCardNum) or fk.compareNum(#to_select:getCardIds('hej'), #s, self.AreaCardNumWithCardNum)))
    d = (d and ((not self.HandcardNumWithCardNum) or fk.compareNum(to_select:getHandcardNum(), #s, self.HandcardNumWithCardNum)))
    d = (d and ((not self.AtkRgWithCardNum) or fk.compareNum(o, #s, self.AtkRgWithCardNum)) and not (self.BlockPIdsByCIdstr and table.find(s, function(id)
        return (self.BlockPIdsByCIdstr[tostring(id)] and table.contains(self.BlockPIdsByCIdstr[tostring(id)], to_select.id)) end)))
    return (d and (not (self.UnlockPIdsByCIdstr and table.find(Fk:getAllCardIds(), function(id)
        return (self.UnlockPIdsByCIdstr[tostring(id)] and table.contains(self.UnlockPIdsByCIdstr[tostring(id)], to_select.id)) and not table.contains(s, id)
      end))) and ((not self.PossessCardNumWithCardNum) or fk.compareNum(#to_select:getCardIds('he'), #s, self.PossessCardNumWithCardNum)))
  end,
  feasible = function (self, player, selected, selected_cards, card)

    local r, m = ((not self.TargetNumWithCardNum) or fk.compareNum(m, #selected_cards, self.TargetNumWithCardNum)), #selected
    r = (r and ((not self.targetIdSets) or table.find(self.targetIdSets, function(tb) return table.isEqual(table.map(selected, Util.IdMapper), tb) end)))
    for _, p in ipairs(selected) do
      r = (r and ((not self.FromMeWithTargetNum) or fk.compareNonNegativeNum(player:distanceTo(p, nil, nil), m, self.FromMeWithTargetNum)))
      r = (r and ((not self.ToMeWithTargetNum) or fk.compareNonNegativeNum(p:distanceTo(player, nil, nil), m, self.ToMeWithTargetNum)))
      r = (r and ((not self.AtkRgWithTargetNum) or fk.compareNonNegativeNum(p:getAttackRange(), m, self.AtkRgWithTargetNum)))
    end
    return ((#selected_cards >= self.min_c_num) and (m >= self.min_t_num) and ((m == #selected_cards) or not self.equal) and r)
  end,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if self.targetTipName then
      local targetTip = Fk.target_tips[self.targetTipName]
      assert(targetTip)
      return targetTip.target_tip(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    end
  end,
  min_target_num = function(self) return self.min_t_num end,
  max_target_num = function(self) return self.max_t_num end,
  min_card_num = function(self) return self.min_c_num end,
  max_card_num = function(self) return self.max_c_num end,
})

exChooseSkill:addAI(Fk.Ltk.AI.newActiveStrategy { --摆了
  think = function(self, ai)
    local data = ai.data[4]
    local orig = Fk.skills[data.skillName] or exChooseSkill
    local strategy = ai:findStrategyOfSkill(Fk.Ltk.AI.ChooseCardsAndPlayersStrategy, orig.name)
    if not strategy then
      strategy = ai:findStrategyOfSkill(Fk.Ltk.AI.ChooseCardsAndPlayersStrategy, exChooseSkill.name)
      ---@cast strategy -nil
    end

    local cards, card_benefit = strategy:chooseCards(ai)
    local players, player_benefit = strategy:choosePlayers(ai)
    if cards then
      return { cards, players }, (card_benefit * player_benefit) or 0
    end
  end,
})

exChooseSkill:addAI(Fk.Ltk.AI.newChooseCardsAndPlayersStrategy { --摆了
  choose_cards = function (self, ai)
    local data = ai.data[4] -- extra_data
    local available_cards = ai:getEnabledCards()

    if ai.data[3] --[[ cancelable ]] or data.min_c_num == 0 then return {}, 0 end

    return table.random(available_cards, data.min_c_num), 0
  end,
  choose_players = function(self, ai)
    local data = ai.data[4] -- extra_data
    local available_players = ai:getEnabledTargets()

    if ai.data[3] --[[ cancelable ]] or data.min_t_num == 0 then return {}, 0 end

    return table.random(available_players, data.min_t_num), 0
  end
})

return exChooseSkill
