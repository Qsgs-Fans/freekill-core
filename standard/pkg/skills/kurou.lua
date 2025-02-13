local skill = fk.CreateSkill {
  name = "kurou",
}

skill:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#kurou-active",
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local from = effect.from
    room:loseHp(from, 1, skill.name)
    if from:isAlive() then
      from:drawCards(2, skill.name)
    end
  end
})

skill:addTest(function(room, me)
  FkTest.setNextReplies(me, {
    json.encode {
      card = { skill = "kurou", subcards = {} },
    },
    "",
  })
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "kurou")
    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
      phase_table = { Player.Play }
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)
  lu.assertEquals(#me:getCardIds("h"), 2)
  lu.assertEquals(me.hp, 3)
end)

return skill
