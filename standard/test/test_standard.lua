TestStandard = { setup = InitRoom, tearDown = ClearRoom }

function TestStandard:testJianxiong()
  local room = LRoom
  local me, comp2 = room.players[1], room.players[2]
  RunInRoom(function() room:handleAddLoseSkills(me, "jianxiong") end)

  local slash = Fk:getCardById(1)
  SetNextReplies(me, { "__cancel", "1" })
  RunInRoom(function()
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  -- p(me:toJsonObject())
  lu.assertEquals(me:getCardIds("h")[1], 1)
end

function TestStandard:testFanKui()
  local room = LRoom
  local me, comp2 = room.players[1], room.players[2]
  RunInRoom(function() room:handleAddLoseSkills(me, "fankui") end)

  -- 空牌的情况
  local slash = Fk:getCardById(1)
  SetNextReplies(me, { "__cancel" })
  RunInRoom(function()
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(#me:getCardIds("h"), 0)

  -- 有牌的情况
  SetNextReplies(me, { "__cancel", "1", "3" })
  RunInRoom(function()
    room:obtainCard(comp2, { 3 })
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(me:getCardIds("h")[1], 3)
end

function TestStandard:testGangLie()
  local room = LRoom ---@type Room
  local me, comp2 = room.players[1], room.players[2]
  RunInRoom(function()
    room:handleAddLoseSkills(me, "ganglie")
  end)

  -- 第一段：测试我发动刚烈，AI点取消
  local slash = Fk:getCardById(1)
  SetNextReplies(me, { "__cancel", "1" })
  SetNextReplies(comp2, { "__cancel" })
  local origin_hp = comp2.hp
  RunInRoom(function()
    room:obtainCard(comp2, { 3, 4 })

    room:moveCardTo(2, Card.DrawPile) -- 控顶
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp - 1)
  lu.assertEquals(#comp2:getCardIds("h"), 2)

  -- 第二段：测试我发动刚烈，AI丢二
  origin_hp = comp2.hp
  SetNextReplies(me, { "__cancel", "1" })
  SetNextReplies(comp2, { json.encode {
    card = { skill = "discard_skill", subcards = { 3, 4 } },
    targets = {}
  } })
  RunInRoom(function()
    room:moveCardTo(2, Card.DrawPile) -- 再控顶
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp)
  lu.assertEquals(#comp2:getCardIds("h"), 0)

  -- 第三段：测试我发动刚烈，判定判红桃
  origin_hp = comp2.hp
  SetNextReplies(me, { "__cancel", "1" })
  SetNextReplies(comp2, { "__cancel" })
  RunInRoom(function()
    room:obtainCard(comp2, { 3, 4 })

    room:moveCardTo(24, Card.DrawPile) -- 控顶
    room:useCard{
      from = comp2.id,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp)
  lu.assertEquals(#comp2:getCardIds("h"), 2)
end

function TestStandard:testLuoYi()
  local room = LRoom ---@type Room
  local me, comp2 = room.players[1], room.players[2]
  RunInRoom(function()
    room:handleAddLoseSkills(me, "luoyi")
  end)
  local slash = Fk:getCardById(1)
  SetNextReplies(me, { "1", json.encode {
    card = 1,
    targets = { comp2.id }
  } })
  SetNextReplies(comp2, { "__cancel" })

  local origin_hp = comp2.hp
  RunInRoom(function()
    room:obtainCard(me, 1)
    GameEvent.Turn:create(me):exec()
  end)
  -- p(me:getCardIds("h"))
  lu.assertEquals(#me:getCardIds("h"), 1)
  lu.assertEquals(comp2.hp, origin_hp - 2)

  -- 测标记持续时间
  origin_hp = comp2.hp
  RunInRoom(function()
    room:useCard{
      from = me.id,
      tos = { { comp2.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp - 1)
end

function TestStandard:testTianDu()
  local room = LRoom ---@type Room
  local me = room.players[1]

  RunInRoom(function()
    room:handleAddLoseSkills(me, "tiandu")
  end)
  SetNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" }) -- 试图领取所有人的判定牌
  RunInRoom(function()
    for _, p in ipairs(room.players) do
      room:judge{
        who = p,
        pattern = ".",
        reason = "test"
      }
    end
  end)
  lu.assertEquals(#me:getCardIds("h"), 1)
end

function TestStandard:testLuoShen()
  local room = LRoom ---@type Room
  local me = room.players[1]

  RunInRoom(function()
    room:handleAddLoseSkills(me, "luoshen")
  end)
  local red = table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).color == Card.Red
  end)
  local blacks = table.filter(room.draw_pile, function(cid)
    return Fk:getCardById(cid).color == Card.Black
  end)
  local rnd = 5
  SetNextReplies(me, { "1", "1", "1", "1", "1", "1" }) -- 除了第一个1以外后面全是潜在的“重复流程”
  -- 每次往红牌顶上塞若干个黑牌
  RunInRoom(function()
    room:throwCard(me:getCardIds("h"), nil, me, me)
    -- 控顶
    room:moveCardTo(red, Card.DrawPile)
    if rnd > 0 then room:moveCardTo(table.slice(blacks, 1, rnd + 1), Card.DrawPile) end

    GameEvent.Turn:create(me, { phase_table = { Player.Start } }):exec()
  end)
  lu.assertEquals(#me:getCardIds("h"), rnd)
end

function TestStandard:testKongCheng()
  local room = LRoom ---@type Room
  local me, comp2 = room.players[1], room.players[2]

  RunInRoom(function()
    room:handleAddLoseSkills(me, "kongcheng")
  end)
  local slash = Fk:cloneCard("slash")
  local duel = Fk:cloneCard("duel")
  lu.assertFalse(comp2:canUseTo(slash, me))
  lu.assertFalse(comp2:canUseTo(duel, me))
  RunInRoom(function()
    me:drawCards(1)
  end)
  lu.assertTrue(comp2:canUseTo(slash, me))
  lu.assertTrue(comp2:canUseTo(duel, me))
end

function TestStandard:testMashu()
  local room = LRoom ---@type Room
  local me = room.players[1]

  local origin = table.map(room:getOtherPlayers(me), function(other) return me:distanceTo(other) end)

  RunInRoom(function()
    room:handleAddLoseSkills(me, "mashu")
  end)

  for i, other in ipairs(room:getOtherPlayers(me)) do
    lu.assertEquals(me:distanceTo(other), math.max(origin[i] - 1, 1))
  end
end

function TestStandard:testJiZhi()
  local room = LRoom ---@type Room
  local me, comp2 = room.players[1], room.players[2]

  RunInRoom(function()
    room:handleAddLoseSkills(me, "jizhi")
  end)

  local slash = Fk:getCardById(1)
  local god_salvation = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "god_salvation"
  end))

  SetNextReplies(me, { "1", "1" })
  RunInRoom(function()
    room:moveCardTo({2, 3, 4, 5}, Card.DrawPile) -- 都是杀……吧？
    room:useCard{
      from = me.id,
      tos = { { comp2.id } },
      card = slash,
    }
  end)
  lu.assertEquals(#me:getCardIds("h"), 0)
  RunInRoom(function()
    room:useCard{
      from = me.id,
      tos = { { comp2.id } },
      card = god_salvation,
    }
  end)
  lu.assertEquals(#me:getCardIds("h"), 1)
end

function TestStandard:testQiCai()
  local room = LRoom ---@type Room
  local me = room.players[1]

  local faraway = table.filter(room:getOtherPlayers(me), function(other) return me:distanceTo(other) > 1 end)

  RunInRoom(function()
    room:handleAddLoseSkills(me, "qicai")
    -- 让顺手牵羊可以用一下
    for _, other in ipairs(room:getOtherPlayers(me, false)) do
      other:drawCards(1)
    end
  end)
  local snatch = Fk:cloneCard("snatch")

  for _, other in ipairs(faraway) do
    -- printf('%s', other)
    lu.assertTrue(me:canUseTo(snatch, other))
  end
end

function TestStandard:testKeJi()
  local room = LRoom ---@type Room
  local me = room.players[1]
  RunInRoom(function()
    room:handleAddLoseSkills(me, "keji")
  end)

  SetNextReplies(me, { "1" })
  RunInRoom(function()
    me:drawCards(10)
    GameEvent.Turn:create(me, { phase_table = { Player.Discard } }):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 10)
end

function TestStandard:testYingzi()
  local room = LRoom ---@type Room
  local me = room.players[1]
  RunInRoom(function()
    room:handleAddLoseSkills(me, "yingzi")
  end)

  SetNextReplies(me, { "1" })
  RunInRoom(function()
    GameEvent.Turn:create(me, { phase_table = { Player.Draw } }):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 3)
end

function TestStandard:testQianXun()
  local room = LRoom ---@type Room
  local me, comp2 = room.players[1], room.players[2]

  local snatch = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "snatch"
  end))
  local indulgence = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "indulgence"
  end))

  RunInRoom(function()
    -- 让顺手牵羊可以用一下
    me:drawCards(1)
  end)

  lu.assertTrue(comp2:canUseTo(snatch, me))
  lu.assertTrue(comp2:canUseTo(indulgence, me))

  RunInRoom(function()
    room:handleAddLoseSkills(me, "qianxun")
  end)

  lu.assertFalse(comp2:canUseTo(snatch, me))
  lu.assertFalse(comp2:canUseTo(indulgence, me))
end

function TestStandard:testLianYing()
  local room = LRoom ---@type Room
  local me = room.players[1]

  RunInRoom(function()
    room:handleAddLoseSkills(me, "lianying")
  end)
  SetNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" })
  RunInRoom(function()
    me:drawCards(3)
    room:throwCard(me:getCardIds("h"), nil, me, me)
  end)
  lu.assertEquals(#me:getCardIds("h"), 1)
end

function TestStandard:testXiaoJi()
  local room = LRoom ---@type Room
  local me = room.players[1]

  RunInRoom(function()
    room:handleAddLoseSkills(me, "xiaoji")
  end)
  SetNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" })

  local nioh = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "nioh_shield"
  end))

  local spear = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "spear"
  end))

  RunInRoom(function()
    room:useCard{
      from = me.id,
      tos = {{me.id}},
      card = nioh
    }
    room:useCard{
      from = me.id,
      tos = {{me.id}},
      card = spear
    }
    room:throwCard(me:getCardIds("he"), nil, me, me)
  end)
  lu.assertEquals(#me:getCardIds("h"), 4)
end

function TestStandard:testBiYue()
  local room = LRoom ---@type Room
  local me = room.players[1]
  RunInRoom(function()
    room:handleAddLoseSkills(me, "biyue")
  end)

  SetNextReplies(me, { "1" })
  RunInRoom(function()
    GameEvent.Turn:create(me, { phase_table = { Player.Finish } }):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 1)
end
