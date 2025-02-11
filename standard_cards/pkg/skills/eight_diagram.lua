local skill = fk.CreateSkill {
  name = "#eight_diagram_skill",
  attached_equip = "eight_diagram",
}

local eight_diagram_on_use = function (self, event, target, player, data)
  local room = player.room
  local to = data.to
  local ride_tab = table.filter(to:getCardIds("e"), function (id)
    local card = Fk:getCardById(id)
    return card.sub_type == Card.SubtypeDefensiveRide or card.sub_type == Card.SubtypeOffensiveRide
  end)
  if #ride_tab == 0 then return end
  local id = room:askForCardChosen(player, to, {
    card_data = {
      { "equip_horse", ride_tab }
    }
  }, self.name)
  room:throwCard({id}, skill.name, to, player)
end
skill:addEffect(fk.AskForCardUse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      not player:prohibitUse(Fk:cloneCard("jink"))
  end,
  on_use = eight_diagram_on_use,
})
skill:addEffect(fk.AskForCardResponse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      not player:prohibitResponse(Fk:cloneCard("jink"))
  end,
  on_use = eight_diagram_on_use,
})

return skill
