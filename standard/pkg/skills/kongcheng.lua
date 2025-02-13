local skill = fk.CreateSkill{
  name = "kongcheng",
  frequency = Skill.Compulsory,
}

skill:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if to:hasSkill(skill.name) and to:isKongcheng() and card then
      return table.contains({"slash", "duel"}, card.trueName)
    end
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if not (player:hasSkill(skill.name) and player:isKongcheng()) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke("kongcheng")
    player.room:notifySkillInvoked(player, "kongcheng", "defensive")
  end,
})

skill:addTest(function(room, me)
  local comp2 = room.players[2]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "kongcheng")
  end)
  local slash = Fk:cloneCard("slash")
  local duel = Fk:cloneCard("duel")
  lu.assertFalse(comp2:canUseTo(slash, me))
  lu.assertFalse(comp2:canUseTo(duel, me))
  FkTest.runInRoom(function()
    me:drawCards(1)
  end)
  lu.assertTrue(comp2:canUseTo(slash, me))
  lu.assertTrue(comp2:canUseTo(duel, me))
end)

return skill
