local skill = fk.CreateSkill {
  name = "guicai",
}

skill:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#guicai-ask::" .. target.id
    local card = room:askForCard(player, 1, 1, false, skill.name, true, ".|.|.|hand", prompt)
    if #card > 0 then
      event:setCostData({cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(event:getCostData(self).cards[1]), player, data, skill.name)
  end,
})

return skill
