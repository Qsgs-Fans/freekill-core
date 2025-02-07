local skill = fk.CreateSkill {
  name = "wusheng",
}

skill:addEffect("viewas", nil, {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#wusheng",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = skill.name
    c:addSubcard(cards[1])
    return c
  end,
})

return skill
