local skill = fk.CreateSkill {
  name = "peach_skill",
}

skill:addEffect("active", {
  prompt = "#peach_skill",
  mod_target_filter = function(self, player, to_select)
    return to_select:isWounded()
  end,
  can_use = Util.CanUseToSelf,
  on_use = function(self, room, use)
    if not use.tos or #use.tos == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    if effect.to:isWounded() and not effect.to.dead then
      room:recover{
        who = effect.to,
        num = 1,
        card = effect.card,
        recoverBy = effect.from,
        skillName = skill.name,
      }
    end
  end,
})

return skill
