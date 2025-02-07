local skill = fk.CreateSkill {
  name = "qixi",
}

skill:addEffect("viewas", nil, {
  anim_type = "control",
  pattern = "dismantlement",
  prompt = "#qixi",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("dismantlement")
    c.skillName = skill.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end
})

return skill
