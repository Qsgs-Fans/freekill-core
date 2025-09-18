local silverLionSkill = fk.CreateSkill {
  name = "#silver_lion_skill",
  tags = { Skill.Compulsory },
  attached_equip = "silver_lion",
}

silverLionSkill:addEffect(fk.DetermineDamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(silverLionSkill.name) and data.damage > 1
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1 - data.damage)
  end,
})
silverLionSkill:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead or not player:isWounded() or not Fk.skills[silverLionSkill.name]:isEffectable(player) then return end
    if data.extra_data and data.extra_data.silver_lion_equips then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(data.extra_data.silver_lion_equips, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = silverLionSkill.name,
    }
  end,
})

-- TODO:幽默虚拟装备，信息在移动前就移除了
silverLionSkill:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player == player.room.players[1]
  end,
  on_refresh = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from and not move.from.dead then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            local c = move.from:getVirtualEquip(info.cardId) or Fk:getCardById(info.cardId) ---@type EquipCard
            if table.contains(c:getEquipSkills(move.from), Fk.skills[silverLionSkill.name]) then
              table.insert(ids, info.cardId)
            end
          end
        end
      end
    end
    if #ids > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.silver_lion_equips = ids
    end
  end,
})

silverLionSkill:addTest(function (room, me)
  local card = room:printCard("silver_lion")
  FkTest.runInRoom(function ()
    room:useCard{
      from = me,
      tos = {me},
      card = card,
    }
    room:damage{
      to = me,
      damage = 2,
    }
  end)
  lu.assertEquals(me.hp, 3)
  FkTest.runInRoom(function ()
    room:throwCard(card, nil, me)
  end)
  lu.assertEquals(me.hp, 4)
end)

return silverLionSkill
