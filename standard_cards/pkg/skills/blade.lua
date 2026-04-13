local skill = fk.CreateSkill {
  name = "#blade_skill",
  attached_equip = "blade",
}

skill:addEffect(fk.CardEffectCancelledOut, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and data.from == player and data.card.trueName == "slash" and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local blades = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return ((player:getVirtualEquip(id) and player:getVirtualEquip(id).name or Fk:getCardById(id).name) == skill.attached_equip)
      end)
    for _, id in ipairs(blades) do Fk:getCardById(id):addMark('using')
    end
    local params = { ---@type AskToUseCardParams
      skill_name = "slash",
      pattern = "slash",
      prompt = "#blade_slash:" .. data.to.id,
      cancelable = true,
      extra_data = {
        must_targets = {data.to.id},
        exclusive_targets = {data.to.id},
        bypass_distances = true,
        bypass_times = true,
      }
    }
    local use = room:askToUseCard(player, params)
    for _, id in ipairs(blades) do --这里按2017版规则集的精神来写，〖丈八蛇矛〗等同理
      if Fk:getCardById(id):getMark('using') > 0 then Fk:getCardById(id):removeMark('using') --setMark('using', 0)
      end
    end
    if use then
      use.extraUse = true
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

return skill
