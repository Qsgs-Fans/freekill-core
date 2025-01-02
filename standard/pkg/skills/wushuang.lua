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

return fk.CreateSkill({
  name = "wushuang",
  anim_type = "offensive",
}):addEffect(fk.TargetSpecified, nil, {
  can_trigger = function(self, event, target, player, data)
    return table.contains({ "slash", "duel" }, data.card.trueName)
  end,
  on_use = wushuang_spec.on_use
})
  :addEffect(fk.TargetConfirmed, nil, {
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == "duel"
  end,
  on_use = wushuang_spec.on_use
})
