local skill_name = "qicai"

local skill = fk.CreateSkill{
  name = skill_name,
  frequency = Skill.Compulsory,
}

skill:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(skill_name) and card and card.type == Card.TypeTrick
  end,
})

skill:addTest(function(room, me)
  local faraway = table.filter(room:getOtherPlayers(me), function(other) return me:distanceTo(other) > 1 end)

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, skill_name)
    -- 让顺手牵羊可以用一下
    for _, other in ipairs(room:getOtherPlayers(me, false)) do
      other:drawCards(1)
    end
  end)
  local snatch = Fk:cloneCard("snatch")

  for _, other in ipairs(faraway) do
    -- printf('%s', other)
    lu.assertTrue(me:canUseTo(snatch, other))
  end
end)

return skill
