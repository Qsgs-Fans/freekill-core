local skill = fk.CreateSkill {
  name = "#nioh_shield_skill",
  attached_equip = "nioh_shield",
  frequency = Skill.Compulsory,
}

skill:addEffect(fk.PreCardEffect, {
  can_trigger = function(self, event, target, player, data)
    return data.to == player and player:hasSkill(skill.name) and
    data.card.trueName == "slash" and data.card.color == Card.Black
  end,
  on_use = Util.TrueFunc,
})

return skill
