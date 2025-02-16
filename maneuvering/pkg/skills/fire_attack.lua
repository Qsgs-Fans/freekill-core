local skill_name = "fire_attack_skill"

local skill = fk.CreateSkill {
  name = skill_name,
}

skill:addEffect("active", {
  prompt = "#fire_attack_skill",
  can_use = Util.CanUse,
  target_num = 1,
  mod_target_filter = function(self, _, to_select, _, _, _)
    return not to_select:isKongcheng()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    if to:isKongcheng() then return end

    local params = { ---@type AskToCardsParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill_name,
      cancelable = false,
      pattern = ".|.|.|hand",
      prompt = "#fire_attack-show:" .. from.id
    }
    local showCard = room:askToCards(to, params)[1]
    to:showCards(showCard)

    showCard = Fk:getCardById(showCard)
    params = { ---@type AskToDiscardParams
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill_name,
      cancelable = true,
      pattern = ".|.|" .. showCard:getSuitString(),
      prompt = "#fire_attack-discard:" .. to.id .. "::" .. showCard:getSuitString()
    }
    local cards = room:askToDiscard(from, params)
    if #cards > 0 and not to.dead then
      room:damage({
        from = from,
        to = to,
        card = effect.card,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = skill_name,
      })
    end
  end,
})

return skill
