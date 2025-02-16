local tuxi = fk.CreateSkill {
  name = "tuxi",
}

tuxi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuxi.name) and player.phase == Player.Draw and
      table.find(player.room:getOtherPlayers(player), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng()
    end)

    local result = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 2, prompt = "#tuxi-ask", skill_name = tuxi.name })
    if #result > 0 then
      room:sortByAction(result)
      self.cost_data = {tos = result}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:skip(Player.Draw)
    for _, p in ipairs(self.cost_data.tos) do
      if player.dead then break end
      if not p.dead and not p:isKongcheng() then
        local c = room:askToChooseCard(player, { target = p, flag = "h", skill_name = tuxi.name })
        room:obtainCard(player.id, c, false, fk.ReasonPrey)
      end
    end
  end,
})

return tuxi
