local liuli = fk.CreateSkill{
  name = "liuli",
}

liuli:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data) --暂不改
    return target == player and player:hasSkill(liuli.name) and not data.cancelled and data.card.trueName == "slash" and
      table.find(player.room.alive_players, function (p)
        return player:inMyAttackRange(p) and p ~= data.from and not data.from:isProhibited(p, data.card)
      end) and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data);
    local room, others, fsc, targets, BlockPIdsByCIdstr = player.room, player.room:getOtherPlayers(player), data.card.fake_subcards, {}, {}
    for _, id in ipairs(player:getCardIds('he')) do
      data.card.fake_subcards, BlockPIdsByCIdstr[tostring(id)] = table.connect(fsc, {id}), table.map(others, Util.IdMapper)
      for _, Sp in ipairs(others) do
        if player:inMyAttackRange(Sp, 0, {id}) and (Sp ~= data.from) and not data.from:isProhibited(Sp, data.card) then
          table.removeOne(BlockPIdsByCIdstr[tostring(id)], Sp.id)
          table.insertIfNeed(targets, Sp)
        end
      end
    end
    data.card.fake_subcards = fsc
    local tos, cards = room:askToChooseCardsToMoveAndPlayers(player, { --room:askToChooseCardsAndPlayers
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      targets = targets,
      pattern = ".",
      skill_name = liuli.name,
      prompt = "#liuli-target",
      cancelable = true,
      will_throw = true,
      BlockPIdsByCIdstr = table.clone(BlockPIdsByCIdstr), --双将同疾
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:throwCard(event:getCostData(self).cards, liuli.name, player, player)
    if data:cancelCurrentTarget() then
      data:addTarget(to)
    end
  end,
})

return liuli
