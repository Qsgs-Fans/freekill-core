local skill = fk.CreateSkill{
  name = "default_equip_skill",
}

skill:addEffect("active", {
  prompt = function(self, player, selected_cards, _)
    if not selected_cards or #selected_cards == 0 then return " " end
    return "#default_equip_skill:::" .. Fk:getCardById(selected_cards[1]).name
  end,
  mod_target_filter = function(self, player, to_select, selected, card, distance_limited)
    return #to_select:getAvailableEquipSlots(card.sub_type) > 0
  end,
  can_use = Util.SelfCanUseCard,
  on_use = function(self, room, use)
    if not use.tos or #use.tos == 0 then
      use.tos = { use.from }
    end
  end
})

return skill
