local skill = fk.CreateSkill {
  name = "rende",
}

skill:addEffect("rende", nil, {
  anim_type = "support",
  prompt = "#rende-active",
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    local cards = effect.cards
    local marks = player:getMark("_rende_cards-phase")
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, skill.name, nil, false, player.id)
    room:addPlayerMark(player, "_rende_cards-phase", #cards)
    if marks < 2 and marks + #cards >= 2 and not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name,
      }
    end
  end,
})

return skill
