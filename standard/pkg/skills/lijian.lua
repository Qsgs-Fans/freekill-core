local lijian = fk.CreateSkill {
  name = "lijian",
}

lijian:addLoseEffect(function (self, player, is_death)
  local hd = table.contains((player.deputyGeneral == "anjiang") and Fk.generals[player:getMark("__heg_deputy")]:getSkillNameList() or {}, self.name)
  hd = (hd or table.contains((player.general == "anjiang") and Fk.generals[player:getMark("__heg_general")]:getSkillNameList() or {}, self.name))
  if (player.phase == Player.Play) and not (is_death or hd) then player:setMark('lijianUsdLst-phase', player:usedEffectTimes(self.name, Player.HistoryPhase))
  end
end)

lijian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#lijian-active",
  max_phase_use_time = function(self, player) --= 1,
    return (1 + player:getMark('lijianUsdLst-phase'))
  end,
  card_num = 1,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards) --= function(self, player, to_select, selected)
    if #selected < 2 and to_select ~= player and to_select:isMale() then
      if #selected == 0 then
        return true
      else
        local Duel = Fk:cloneCard("duel")
        Duel.fake_subcards = selected_cards
        return to_select:canUseTo(Duel, selected[1]) --canUseTo(Fk:cloneCard("duel"), selected[1])
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, lijian.name, player, player)
    local duel = Fk:cloneCard("duel")
    duel.skillName = lijian.name
    local new_use = { ---@type UseCardDataSpec
      from = effect.tos[2],
      tos = { effect.tos[1] },
      card = duel,
      prohibitedCardNames = { "nullification" },
    }
    room:useCard(new_use)
  end,
  target_tip = function(self, _, to_select, selected, _, _, selectable, _)
    if not selectable then return end
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "lijian_tip_1"
    else
      return "lijian_tip_2"
    end
  end,
})

return lijian
