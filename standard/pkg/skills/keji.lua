local skill = fk.CreateSkill{
  name = "keji",
}

skill:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and data.to == Player.Discard then
      local room = player.room
      local logic = room.logic
      local play_ids = logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data.phase == Player.Play and e.end_id then
          -- table.insert(play_ids, {e.id, e.end_id})
          return true
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      ---@param e GameEvent.UseCard | GameEvent.RespondCard
      local function playCheck (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        return in_play and e.data.from == player and e.data.card.trueName == "slash"
      end
      return #logic:getEventsOfScope(GameEvent.UseCard, 1, playCheck, Player.HistoryTurn) == 0
      and #logic:getEventsOfScope(GameEvent.RespondCard, 1, playCheck, Player.HistoryTurn) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player:skip(Player.Discard)
  end,
})

skill:addTest(function(room, me)
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, skill.name)
  end)

  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    me:drawCards(10)
    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
      phase_table = { Player.Discard }
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 10)
end)

return skill
