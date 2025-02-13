local skill = fk.CreateSkill {
  name = "god_salvation_skill",
}

skill:addEffect("active", {
  prompt = "#god_salvation_skill",
  can_use = Util.GlobalCanUse,
  on_use = function (self, room, cardUseEvent)
    return Util.AoeCardOnUse(self, cardUseEvent.from, cardUseEvent, true)
  end,
  mod_target_filter = Util.TrueFunc,
  about_to_effect = function(self, room, effect)
    if not effect.to:isWounded() then
      return true
    end
  end,
  on_effect = function(self, room, effect)
    if effect.to:isWounded() and not effect.to.dead then
      room:recover({
        who = effect.to,
        num = 1,
        recoverBy = effect.from,
        card = effect.card,
        skillName = self.name,
      })
    end
  end,
})

return skill
