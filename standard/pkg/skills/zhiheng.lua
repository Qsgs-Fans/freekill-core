local zhiheng = fk.CreateSkill {
  name = "zhiheng",
}

zhiheng:addLoseEffect(function (self, player, is_death)
  local hd = table.contains((player.deputyGeneral == "anjiang") and Fk.generals[player:getMark("__heg_deputy")]:getSkillNameList() or {}, self.name)
  hd = (hd or table.contains((player.general == "anjiang") and Fk.generals[player:getMark("__heg_general")]:getSkillNameList() or {}, self.name))
  if (player.phase == Player.Play) and not (is_death or hd) then player:setMark('zhihengUsdLst-phase', player:usedEffectTimes(self.name, Player.HistoryPhase))
  end
end)

zhiheng:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#zhiheng-active",
  max_phase_use_time = function(self, player) --= 1,
    return (1 + player:getMark('zhihengUsdLst-phase'))
  end,
  target_num = 0,
  min_card_num = 1,
  card_filter = function(self, player, to_select)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local from = effect.from
    room:throwCard(effect.cards, zhiheng.name, from, from)
    if from:isAlive() then
      from:drawCards(#effect.cards, zhiheng.name)
    end
  end,
})

zhiheng:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local player = ai.player
    local cards = ai:getEnabledCards()

    -- cards = ai:getChoiceCardsByKeepValue(cards, #cards, function(value) return value < 45 end)

    return { cards }, ai:getBenefitOfEvents(function(logic)
      logic:throwCard(cards, self.skill_name, player, player)
      logic:drawCards(player, #cards, self.skill_name)
    end)
  end,
})

return zhiheng
