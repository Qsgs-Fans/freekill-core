local sk = fk.CreateSkill{
  name = "paoxiao",
  frequency = Skill.Compulsory,
}

sk:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    if player:hasSkill(sk.name) and card and card.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return true
    end
  end,
})
sk:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(sk.name) and
      data.card.trueName == "slash" and
      player:usedCardTimes("slash", Player.HistoryPhase) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke("paoxiao")
    player.room:doAnimate("InvokeSkill", {
      name = "paoxiao",
      player = player.id,
      skill_type = sk.name,
    })
  end,
})

return sk
