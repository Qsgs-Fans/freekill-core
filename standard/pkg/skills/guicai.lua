local guicai = fk.CreateSkill {
  name = "guicai",
}

guicai:addEffect(fk.AskForRetrial, {
  guicai = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guicai.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#guicai-ask::" .. target.id
    local card = room:askToCards(player, { min_num = 1, max_num = 1, include_equip = false, skill_name = guicai.name, cancelable = true, pattern = ".|.|.|hand", prompt = prompt })
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data.cards[1]), player, data, guicai.name)
  end,
})

return guicai
