local skill = fk.CreateSkill {
  name = "wushuang",
  frequency = Skill.Compulsory,
}

local wushuang_spec = {
  on_use = function(self, event, target, player, data)
    data.fixedResponseTimes = data.fixedResponseTimes or {}
    if data.card.trueName == "slash" then
      data.fixedResponseTimes["jink"] = 2
    else
      data.fixedResponseTimes["slash"] = 2
      data.fixedAddTimesResponsors = data.fixedAddTimesResponsors or {}
      table.insert(data.fixedAddTimesResponsors, (event == fk.TargetSpecified) and data.to or data.from)
    end
  end,
}

skill:addEffect(fk.TargetSpecified, nil, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      table.contains({ "slash", "duel" }, data.card.trueName)
  end,
  on_use = wushuang_spec.on_use
})
skill:addEffect(fk.TargetConfirmed, nil, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "duel"
  end,
  on_use = wushuang_spec.on_use
})

return skill
