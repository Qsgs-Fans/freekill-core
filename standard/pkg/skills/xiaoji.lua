return fk.CreateSkill({
  name = "xiaoji",
  anim_type = "drawcard",
}):addEffect(fk.AfterCardsMove, nil, {
  can_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local i = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            i = i + 1
          end
        end
      end
    end
    self.cancel_cost = false
    for _ = 1, i do
      if self.cancel_cost or not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}):addTest(function()
  local room = FkTest.room ---@type Room
  local me = room.players[1]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "xiaoji")
  end)
  FkTest.setNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" })

  local nioh = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "nioh_shield"
  end))

  local spear = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "spear"
  end))

  FkTest.runInRoom(function()
    room:useCard{
      from = me,
      tos = {{me.id}},
      card = nioh
    }
    room:useCard{
      from = me,
      tos = {{me.id}},
      card = spear
    }
    room:throwCard(me:getCardIds("he"), nil, me, me)
  end)
  lu.assertEquals(#me:getCardIds("h"), 4)
end)
