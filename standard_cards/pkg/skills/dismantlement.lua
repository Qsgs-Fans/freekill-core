local skill = fk.CreateSkill {
  name = "dismantlement_skill",
}

skill:addEffect("cardskill", {
  prompt = "#dismantlement_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select ~= player and not to_select:isAllNude()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local ptn = '.|.|.|.|.|.|' .. table.concat(table.filter(effect.to:getCardIds('hej'), function(id)
        return not (effect.from:cardVisible(id) and effect.from:prohibitDiscard(id))
      end), ',')
    if effect.from.dead or effect.to.dead or (ptn == '.|.|.|.|.|.|') then return end --or effect.to:isAllNude()
    effect.extra_data = effect.extra_data or {}
    local cid = room:askToChooseCard(effect.from, {
      target = effect.to,
      flag = "hej",
      skill_name = skill.name,
    })
    local ids = room:askToChoosePatternCards(effect.from, { target = effect.to, flag = "hej", skill_name = skill.name, min = 1, max = 1, pattern = ptn })
    effect.extra_data.dismantlement_card = ids[1]
    room:throwCard(ids, skill.name, effect.to, effect.from)
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.44,
  use_value = 5.6,
  use_priority = 4.4,

  on_effect = function(self, logic, effect)
    local ret, benefit = effect.from.ai:askToChooseCards({
      cards = effect.to:getCardIds("hej"),
      skill_name = skill.name,
      data = {
        to_place = Card.DiscardPile,
        reason = fk.ReasonDiscard,
        proposer = effect.from,
      },
    })
    logic:throwCard(ret[1], skill.name, effect.to, effect.from)
  end,
  }
)

return skill
