local skill = fk.CreateSkill({
  name = "jianxiong",
  anim_type = "masochism",
})

skill:addEffect(fk.Damaged, nil, {
  can_trigger = function(self, event, target, player, data)
    return data.card and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
})

skill:addTest(function()
  local room = FkTest.room
  local me, comp2 = room.players[1], room.players[2] ---@type ServerPlayer, ServerPlayer
  FkTest.runInRoom(function() room:handleAddLoseSkills(me, "jianxiong") end)

  local slash = Fk:getCardById(1)
  FkTest.setNextReplies(me, { "__cancel", "1" })
  FkTest.runInRoom(function()
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  -- p(me:toJsonObject())
  lu.assertEquals(me:getCardIds("h")[1], 1)
end)

return skill
