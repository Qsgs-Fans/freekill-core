local skill = fk.CreateSkill{
  name = "jiuyuan$",
  frequency = Skill.Compulsory,
}

skill:addEffect(fk.PreHpRecover, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "peach" and
      data.recoverBy and data.recoverBy.kingdom == "wu" and data.recoverBy ~= player
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

return skill
