local skill = fk.CreateSkill {
  name = "fanjian",
}

skill:addEffect("active", nil, {
  anim_type = "offensive",
  prompt = "#fanjian-active",
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = room:askForChoice(target, {"spade", "heart", "club", "diamond"}, skill.name)
    local card = room:askForCardChosen(target, player, 'h', skill.name)
    room:obtainCard(target.id, card, true, fk.ReasonPrey)
    if Fk:getCardById(card):getSuitString() ~= choice and target:isAlive() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return skill
