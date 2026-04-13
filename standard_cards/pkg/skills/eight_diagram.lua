local skill = fk.CreateSkill {
  name = "#eight_diagram_skill",
  attached_equip = "eight_diagram",
}

---@type AskForCardFunc
local spec = function(self, event, target, player, data)
  if not player.room:askToSkillInvoke(player, { skill_name = self.name }) then return false
  end
  local eight_diagrams = table.filter(player:getEquipments(Card.SubtypeArmor), function(id)
      return ((player:getVirtualEquip(id) and player:getVirtualEquip(id).name or Fk:getCardById(id).name) == skill.attached_equip)
    end)
  for _, id in ipairs(eight_diagrams) do Fk:getCardById(id):addMark('using')
  end

  local room = player.room
  local judgeData = {
    who = player,
    reason = skill.name,
    pattern = ".|.|red",
  }
  room:judge(judgeData)

  for _, id in ipairs(eight_diagrams) do
    if Fk:getCardById(id):getMark('using') > 0 then Fk:getCardById(id):removeMark('using') --setMark('using', 0)
    end
  end
   
  event:setCostData(self, {extra_data = judgeData})
  return true
end
--[[local spec = function (self, event, target, player, data)
    local room = player.room
    local judgeData = {
      who = player,
      reason = skill.name,
      pattern = ".|.|red",
    }
    room:judge(judgeData)
    if judgeData:matchPattern() then
      local new_card = Fk:cloneCard('jink')
      new_card.skillName = "eight_diagram"
      local result = {
        from = player,
        card = new_card,
      }
      if event:isInstanceOf(fk.AskForCardUse) then
        result.tos = {}
      end
      data.result = result

      return true
    end
  end]]--
skill:addEffect(fk.AskForCardUse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none") and
      player:canJudge() and not player:prohibitUse(Fk:cloneCard("jink")) --not player:prohibitUse(Fk:cloneCard("jink"))
  end,
  on_cost = spec,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self).extra_data:matchPattern() then
      local new_card = Fk:cloneCard('jink')
      new_card.skillName = "eight_diagram"
      local result = {
        from = player,
        card = new_card,
        tos = {},
      }
      data.result = result
    end
  end,
})
skill:addEffect(fk.AskForCardResponse, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none") and
      player:canJudge() and not player:prohibitResponse(Fk:cloneCard("jink")) --not player:prohibitResponse(Fk:cloneCard("jink"))
  end,
  on_cost = spec,
  on_use = function(self, event, target, player, data)
    if event:getCostData(self).extra_data:matchPattern() then
      local new_card = Fk:cloneCard('jink')
      new_card.skillName = "eight_diagram"
      local result = {
        from = player,
        card = new_card,
      }
      data.result = result
    end
  end,
})

---[[
skill:addTest(function(room, me)
  local eight_diagram = room:printCard("eight_diagram")
  local comp2 = room.players[2]

  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = eight_diagram,
    }
    room:moveCardTo(room:printCard("slash", Card.Heart), Card.DrawPile)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash"),
    }
  end)
  lu.assertEquals(me.hp, 4)
  FkTest.setNextReplies(me, { "1", "1", "" })
  FkTest.runInRoom(function()
    room:moveCardTo(room:printCard("slash", Card.Diamond), Card.DrawPile)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("archery_attack"),
    }
    room:moveCardTo(room:printCard("slash", Card.Spade), Card.DrawPile)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash"),
    }
  end)
  lu.assertEquals(me.hp, 3)
end)
--]]

skill:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    return ai:getBenefitOfEvents(function(logic)
      logic:judge({
        who = ai.player,
        reason = skill.name,
        pattern = ".|.|red",
      })
    end) >= 0
  end,
})

return skill
