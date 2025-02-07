local skill = fk.CreateSkill {
  name = "jijiang$",
}

skill:addEffect("viewas", nil, {
  anim_type = "offensive",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = skill.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    if use.tos then
      room:doIndicate(player.id, TargetGroup:getRealTargets(use.tos))
    end

    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "shu" then
        local cardResponded = room:askForResponse(p, "slash", "slash", "#jijiang-ask:" .. player.id, true)
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })

          use.card = cardResponded
          return
        end
      end
    end

    room:setPlayerMark(player, "jijiang_failed-phase", 1)
    return skill.name
  end,
  enabled_at_play = function(self, player)
    return player:getMark("jijiang_failed-phase") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p.kingdom == "shu" and p ~= player
      end)
  end,
  enabled_at_response = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p.kingdom == "shu" and p ~= player
    end)
  end,
})

return skill
