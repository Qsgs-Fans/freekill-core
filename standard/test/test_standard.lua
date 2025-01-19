TestStandard = { setup = FkTest.initRoom, tearDown = FkTest.clearRoom }

-- 暂且在这里读取SkillSkel中包含的测试函数，命名规则另说
-- 后面再好好改改测试代码的实现规则
for _, pname in ipairs(Fk.package_names) do
  local pack = Fk.packages[pname]
  for _, skel in ipairs(pack.skill_skels) do
    for i, fn in ipairs(skel.tests) do
      TestStandard[string.format('test%s%d', skel.name, i)] = fn
    end
  end
end

function TestStandard:testFanKui()
  local room = FkTest.room
  local me, comp2 = room.players[1], room.players[2] ---@type ServerPlayer, ServerPlayer
  FkTest.runInRoom(function() room:handleAddLoseSkills(me, "fankui") end)

  -- 空牌的情况
  local slash = Fk:getCardById(1)
  FkTest.setNextReplies(me, { "__cancel" })
  FkTest.runInRoom(function()
    room:useCard{
      from = comp2,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(#me:getCardIds("h"), 0)

  -- 有牌的情况
  FkTest.setNextReplies(me, { "__cancel", "1", "3" })
  FkTest.runInRoom(function()
    room:obtainCard(comp2, { 3 })
    room:useCard{
      from = comp2,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(me:getCardIds("h")[1], 3)
end

function TestStandard:testGangLie()
  local room = FkTest.room ---@type Room
  local me, comp2 = room.players[1], room.players[2] ---@type ServerPlayer, ServerPlayer
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "ganglie")
  end)

  -- 第一段：测试我发动刚烈，AI点取消
  local slash = Fk:getCardById(1)
  FkTest.setNextReplies(me, { "__cancel", "1" })
  FkTest.setNextReplies(comp2, { "__cancel" })
  local origin_hp = comp2.hp
  FkTest.runInRoom(function()
    room:obtainCard(comp2, { 3, 4 })

    room:moveCardTo(2, Card.DrawPile) -- 控顶
    room:useCard{
      from = comp2,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp - 1)
  lu.assertEquals(#comp2:getCardIds("h"), 2)

  -- 第二段：测试我发动刚烈，AI丢二
  origin_hp = comp2.hp
  FkTest.setNextReplies(me, { "__cancel", "1" })
  FkTest.setNextReplies(comp2, { json.encode {
    card = { skill = "discard_skill", subcards = { 3, 4 } },
    targets = {}
  } })
  FkTest.runInRoom(function()
    room:moveCardTo(2, Card.DrawPile) -- 再控顶
    room:useCard{
      from = comp2,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp)
  lu.assertEquals(#comp2:getCardIds("h"), 0)

  -- 第三段：测试我发动刚烈，判定判红桃
  origin_hp = comp2.hp
  FkTest.setNextReplies(me, { "__cancel", "1" })
  FkTest.setNextReplies(comp2, { "__cancel" })
  FkTest.runInRoom(function()
    room:obtainCard(comp2, { 3, 4 })

    room:moveCardTo(24, Card.DrawPile) -- 控顶
    room:useCard{
      from = comp2,
      tos = { { me.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp)
  lu.assertEquals(#comp2:getCardIds("h"), 2)
end

function TestStandard:testLuoYi()
  local room = FkTest.room ---@type Room
  local me, comp2 = room.players[1], room.players[2] ---@type ServerPlayer, ServerPlayer
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "luoyi")
  end)
  local slash = Fk:getCardById(1)
  FkTest.setNextReplies(me, { "1", json.encode {
    card = 1,
    targets = { comp2.id }
  } })
  FkTest.setNextReplies(comp2, { "__cancel" })

  local origin_hp = comp2.hp
  FkTest.runInRoom(function()
    room:obtainCard(me, 1)
    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)
  -- p(me:getCardIds("h"))
  lu.assertEquals(#me:getCardIds("h"), 1)
  lu.assertEquals(comp2.hp, origin_hp - 2)

  -- 测标记持续时间
  origin_hp = comp2.hp
  FkTest.runInRoom(function()
    room:useCard{
      from = me,
      tos = { { comp2.id } },
      card = slash,
    }
  end)
  lu.assertEquals(comp2.hp, origin_hp - 1)
end

function TestStandard:testTianDu()
  local room = FkTest.room ---@type Room
  local me = room.players[1]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "tiandu")
  end)
  FkTest.setNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" }) -- 试图领取所有人的判定牌
  FkTest.runInRoom(function()
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
  local room = FkTest.room ---@type Room
  local me = room.players[1]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "luoshen")
  end)
  local red = table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).color == Card.Red
  end)
  local blacks = table.filter(room.draw_pile, function(cid)
    return Fk:getCardById(cid).color == Card.Black
  end)
  local rnd = 5
  FkTest.setNextReplies(me, { "1", "1", "1", "1", "1", "1" }) -- 除了第一个1以外后面全是潜在的“重复流程”
  -- 每次往红牌顶上塞若干个黑牌
  FkTest.runInRoom(function()
    room:throwCard(me:getCardIds("h"), nil, me, me)
    -- 控顶
    room:moveCardTo(red, Card.DrawPile)
    if rnd > 0 then room:moveCardTo(table.slice(blacks, 1, rnd + 1), Card.DrawPile) end

    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
      phase_table = { Player.Start }
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)
  lu.assertEquals(#me:getCardIds("h"), rnd)
end

function TestStandard:testKongCheng()
  local room = FkTest.room ---@type Room
  local me, comp2 = room.players[1], room.players[2]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "kongcheng")
  end)
  local slash = Fk:cloneCard("slash")
  local duel = Fk:cloneCard("duel")
  lu.assertFalse(comp2:canUseTo(slash, me))
  lu.assertFalse(comp2:canUseTo(duel, me))
  FkTest.runInRoom(function()
    me:drawCards(1)
  end)
  lu.assertTrue(comp2:canUseTo(slash, me))
  lu.assertTrue(comp2:canUseTo(duel, me))
end

function TestStandard:testMashu()
  local room = FkTest.room ---@type Room
  local me = room.players[1] ---@type ServerPlayer

  local origin = table.map(room:getOtherPlayers(me), function(other) return me:distanceTo(other) end)

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "mashu")
  end)

  for i, other in ipairs(room:getOtherPlayers(me)) do
    lu.assertEquals(me:distanceTo(other), math.max(origin[i] - 1, 1))
  end
end

function TestStandard:testJiZhi()
  local room = FkTest.room ---@type Room
  local me, comp2 = room.players[1], room.players[2]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "jizhi")
  end)

  local slash = Fk:getCardById(1)
  local god_salvation = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "god_salvation"
  end))

  FkTest.setNextReplies(me, { "1", "1" })
  FkTest.runInRoom(function()
    room:moveCardTo({2, 3, 4, 5}, Card.DrawPile) -- 都是杀……吧？
    room:useCard{
      from = me,
      tos = { { comp2.id } },
      card = slash,
    }
  end)
  lu.assertEquals(#me:getCardIds("h"), 0)
  FkTest.runInRoom(function()
    room:useCard{
      from = me,
      tos = { { comp2.id } },
      card = god_salvation,
    }
  end)
  lu.assertEquals(#me:getCardIds("h"), 1)
end

function TestStandard:testQiCai()
  local room = FkTest.room ---@type Room
  local me = room.players[1]

  local faraway = table.filter(room:getOtherPlayers(me), function(other) return me:distanceTo(other) > 1 end)

  FkTest.runInRoom(function()
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
  local room = FkTest.room ---@type Room
  local me = room.players[1]
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "keji")
  end)

  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    me:drawCards(10)
    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
      phase_table = { Player.Discard }
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 10)
end

function TestStandard:testYingzi()
  local room = FkTest.room ---@type Room
  local me = room.players[1]
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "yingzi")
  end)

  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
      phase_table = { Player.Draw }
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 3)
end

function TestStandard:testQianXun()
  local room = FkTest.room ---@type Room
  local me, comp2 = room.players[1], room.players[2]

  local snatch = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "snatch"
  end))
  local indulgence = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "indulgence"
  end))

  FkTest.runInRoom(function()
    -- 让顺手牵羊可以用一下
    me:drawCards(1)
  end)

  lu.assertTrue(comp2:canUseTo(snatch, me))
  lu.assertTrue(comp2:canUseTo(indulgence, me))

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "qianxun")
  end)

  lu.assertFalse(comp2:canUseTo(snatch, me))
  lu.assertFalse(comp2:canUseTo(indulgence, me))
end

function TestStandard:testLianYing()
  local room = FkTest.room ---@type Room
  local me = room.players[1]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "lianying")
  end)
  FkTest.setNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" })
  FkTest.runInRoom(function()
    me:drawCards(3)
    room:throwCard(me:getCardIds("h"), nil, me, me)
  end)
  lu.assertEquals(#me:getCardIds("h"), 1)
end

function TestStandard:testXiaoJi()
  local room = FkTest.room ---@type Room
  local me = room.players[1]

  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "xiaoji")
  end)
  FkTest.setNextReplies(me, { "1", "1", "1", "1", "1", "1", "1", "1" })

  local nioh = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "nioh_shield"
  end))

  local spear = Fk:getCardById(table.find(room.draw_pile, function(cid)
    return Fk:getCardById(cid).trueName == "spear"
  end))

  FkTest.runInRoom(function()
    room:useCard{
      from = me,
      tos = {{me.id}},
      card = nioh
    }
    room:useCard{
      from = me,
      tos = {{me.id}},
      card = spear
    }
    room:throwCard(me:getCardIds("he"), nil, me, me)
  end)
  lu.assertEquals(#me:getCardIds("h"), 4)
end

function TestStandard:testBiYue()
  local room = FkTest.room ---@type Room
  local me = room.players[1]
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, "biyue")
  end)

  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    local data = { ---@type TurnDataSpec
      who = me,
      reason = "game_rule",
      phase_table = { Player.Finish }
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
  end)

  lu.assertEquals(#me:getCardIds("h"), 1)
end
