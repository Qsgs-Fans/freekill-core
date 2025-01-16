-- SPDX-License-Identifier: GPL-3.0-or-later

local function drawInit(room, player, n)
  -- TODO: need a new function to call the UI
  local cardIds = room:getNCards(n)
  player:addCards(Player.Hand, cardIds)
  for _, id in ipairs(cardIds) do
    Fk:filterCard(id, player)
  end

  local move_to_notify = {   ---@type MoveCardsDataSpec
    moveInfo = {},
    to = player.id,
    toArea = Card.PlayerHand,
    moveReason = fk.ReasonDraw
  }
  for _, id in ipairs(cardIds) do
    table.insert(move_to_notify.moveInfo,
    { cardId = id, fromArea = Card.DrawPile })
  end
  room:notifyMoveCards(nil, {move_to_notify})

  for _, id in ipairs(cardIds) do
    table.removeOne(room.draw_pile, id)
    room:setCardArea(id, Card.PlayerHand, player.id)
  end
end

local function discardInit(room, player)
  local cardIds = player:getCardIds(Player.Hand)
  player:removeCards(Player.Hand, cardIds)
  table.insertTable(room.draw_pile, cardIds)
  for _, id in ipairs(cardIds) do
    Fk:filterCard(id, nil)
  end

  local move_to_notify = { ---@type MoveCardsDataSpec
    moveInfo = {},
    from = player.id,
    toArea = Card.DrawPile,
    moveReason = fk.ReasonJustMove
  }
  for _, id in ipairs(cardIds) do
    table.insert(move_to_notify.moveInfo,
    { cardId = id, fromArea = Card.PlayerHand })
  end
  room:notifyMoveCards(nil, {move_to_notify})

  for _, id in ipairs(cardIds) do
    room:setCardArea(id, Card.DrawPile, nil)
  end
end

---@class GameEvent.DrawInitial : GameEvent
local DrawInitial = GameEvent:subclass("GameEvent.DrawInitial")
function DrawInitial:main()
  local room = self.room

  local luck_data = {
    drawInit = drawInit,
    discardInit = discardInit,
    playerList = table.map(room.alive_players, Util.IdMapper),
  }

  for _, player in ipairs(room.alive_players) do
    local draw_data = DrawInitialData:new{ num = 4 }
    room.logic:trigger(fk.DrawInitialCards, player, draw_data)
    luck_data[player.id] = draw_data
    luck_data[player.id].luckTime = room.settings.luckTime
    if player.id < 0 then -- Robot
      luck_data[player.id].luckTime = 0
    end
    if draw_data.num > 0 then
      drawInit(room, player, draw_data.num)
    end
  end

  if room.settings.luckTime <= 0 then
    for _, player in ipairs(room.alive_players) do
      local draw_data = luck_data[player.id]
      draw_data.luckTime = nil
      room.logic:trigger(fk.AfterDrawInitialCards, player, draw_data)
    end
    return
  end

  local request = Request:new(room.alive_players, "AskForSkillInvoke")
  for _, p in ipairs(room.alive_players) do
    request:setData(p, { "AskForLuckCard", "#AskForLuckCard:::" .. room.settings.luckTime })
  end
  request.focus_text = "AskForLuckCard"
  request.luck_data = luck_data
  request.accept_cancel = true
  request:ask()

  for _, player in ipairs(room.alive_players) do
    local draw_data = luck_data[player.id]
    draw_data.luckTime = nil
    room.logic:trigger(fk.AfterDrawInitialCards, player, draw_data)
  end
end

---@class GameEvent.Round : GameEvent
---@field public data [RoundData]
local Round = GameEvent:subclass("GameEvent.Round")

function Round:action()
  -- local data = table.unpack(self.data)
  local room = self.room
  -- local currentPlayer

  while true do
    local data = { ---@type TurnDataSpec
      who = room.current,
      reason = "game_rule"
    }
    GameEvent.Turn:create(TurnData:new(data)):exec()
    if room.game_finished then break end

    local changingData = { from = room.current, to = room.current.next, skipRoundPlus = false }
    room.logic:trigger(fk.EventTurnChanging, room.current, changingData, true)

    local nextTurnOwner = changingData.to
    if room.current.seat > nextTurnOwner.seat and not changingData.skipRoundPlus then
      break
    else
      room:setCurrent(nextTurnOwner)
    end
  end
  -- for _, seat in ipairs(data.turn_table) do
  --   local current_player = table.find(room.alive_players, function(p) return p.seat == seat end)
  --   if current_player then
  --     GameEvent.Turn:create(current_player):exec()
  
  --     local changingData = { from = room.current, to = room.current.next, skipRoundPlus = false }
  --     room.logic:trigger(fk.EventTurnChanging, current_player, changingData, true)

  --     --- TODO: 给我整不会了
  --   end
  -- end
end

function Round:main()
  local room = self.room
  local logic = room.logic
  local data = table.unpack(self.data)

  local isFirstRound = room:getTag("FirstRound")
  if isFirstRound then
    room:setTag("FirstRound", false)
  end

  local roundCount = room:getTag("RoundCount")
  roundCount = roundCount + 1
  room:setTag("RoundCount",  roundCount)
  room:doBroadcastNotify("UpdateRoundNum", roundCount)
  -- 强行平局 防止can_trigger报错导致瞬间几十万轮卡炸服务器
  if roundCount >= 280 then
    room:sendLog{
      type = "#TimeOutDraw",
      toast = true,
    }
    room:gameOver("")
  end

  if isFirstRound then
    logic:trigger(fk.GameStart, room.current, data)
  end

  logic:trigger(fk.RoundStart, room.current, data)
  self:action()
  logic:trigger(fk.RoundEnd, room.current, data)
  logic:trigger(fk.AfterRoundEnd, room.current, data)
end

function Round:clear()
  local room = self.room

  for _, p in ipairs(room.players) do
    p:setCardUseHistory("", 0, Player.HistoryRound)
    p:setSkillUseHistory("", 0, Player.HistoryRound)
    for name, _ in pairs(p.mark) do
      if name:find("-round", 1, true) then
        room:setPlayerMark(p, name, 0)
      end
    end
  end

  for cid, cmark in pairs(room.card_marks) do
    for name, _ in pairs(cmark) do
      if name:find("-round", 1, true) then
        room:setCardMark(Fk:getCardById(cid), name, 0)
      end
    end
  end

  for _, p in ipairs(room.players) do
    p:filterHandcards()
    room:broadcastProperty(p, "MaxCards")
  end
end

---@class GameEvent.Turn : GameEvent
---@field public data [TurnData]
local Turn = GameEvent:subclass("GameEvent.Turn")
function Turn:prepare()
  local room = self.room
  local logic = room.logic
  local data = table.unpack(self.data)
  local player = data.who
  data.reason = data.reason or "game_rule"

  if player.rest > 0 and player.rest < 999 then
    room:setPlayerRest(player, player.rest - 1)
    if player.rest == 0 and player.dead then
      room:revivePlayer(player, true, "rest")
    else
      room:delay(50)
    end
  end

  if player.dead then return true end

  room:sendLog{ type = "$AppendSeparator" }

  if logic:trigger(fk.PreTurnStart, player, data) then
    return true
  end

  if not player.faceup then
    player:turnOver()
    return true
  end

  return logic:trigger(fk.BeforeTurnStart, player, data)
end

function Turn:main()
  local room = self.room
  local data = table.unpack(self.data)
  local player = data.who
  player.phase = Player.PhaseNone
  room.logic:trigger(fk.TurnStart, player, data)
  player.phase = Player.NotActive
  player:play(data.phase_table)
end

function Turn:clear()
  local room = self.room
  local data = table.unpack(self.data)
  local current = data.who

  local logic = room.logic
  if self.interrupted then
    if current.phase ~= Player.NotActive then
      local current_phase = current.phase
      current.phase = Player.PhaseNone
      logic:trigger(fk.EventPhaseChanging, current,
        { from = current_phase, to = Player.NotActive }, true) -- FIXME: 等待规范化 
      current.phase = Player.NotActive
      room:broadcastProperty(current, "phase")
      logic:trigger(fk.EventPhaseStart, current, data, true)
    end

    current.skipped_phases = {}
  end

  current.phase = Player.PhaseNone
  logic:trigger(fk.TurnEnd, current, data, self.interrupted)
  logic:trigger(fk.AfterTurnEnd, current, data, self.interrupted)
  current.phase = Player.NotActive

  room:setTag("endTurn", false)

  for _, p in ipairs(room.players) do
    p:setCardUseHistory("", 0, Player.HistoryTurn)
    p:setSkillUseHistory("", 0, Player.HistoryTurn)
    for name, _ in pairs(p.mark) do
      if name:find("-turn", 1, true) then
        room:setPlayerMark(p, name, 0)
      end
    end
  end

  for cid, cmark in pairs(room.card_marks) do
    for name, _ in pairs(cmark) do
      if name:find("-turn", 1, true) then
        room:setCardMark(Fk:getCardById(cid), name, 0)
      end
    end
  end

  for _, p in ipairs(room.players) do
    p:filterHandcards()
    room:broadcastProperty(p, "MaxCards")
  end
end

---@class GameEvent.Phase : GameEvent
---@field public data [PhaseData]
local Phase = GameEvent:subclass("GameEvent.Phase")
function Phase:main()
  local room = self.room
  local logic = room.logic
  local data = table.unpack(self.data)
  local player = data.who

  if not logic:trigger(fk.EventPhaseStart, player) then
    if player.phase ~= Player.NotActive then
      logic:trigger(fk.EventPhaseProceeding, player)

      switch(player.phase, {
      [Player.PhaseNone] = function()
        error("You should never proceed PhaseNone")
      end,
      [Player.RoundStart] = function()

      end,
      [Player.Start] = function()

      end,
      [Player.Judge] = function()
        local cards = player:getCardIds(Player.Judge)
        while #cards > 0 do
          if player._phase_end then break end
          local cid = table.remove(cards)
          if not cid then return end
          local card = player:removeVirtualEquip(cid)
          if not card then
            card = Fk:getCardById(cid)
          end
          if table.contains(player:getCardIds(Player.Judge), cid) then
            room:moveCardTo(card, Card.Processing, nil, fk.ReasonPut, self.name)

            local effect_data = CardEffectData:new{
              card = card,
              to = player.id,
              tos = { {player.id} },
            }
            room:doCardEffect(effect_data)
            if effect_data.isCancellOut and card.skill then
              card.skill:onNullified(room, effect_data)
            end
          end
        end
      end,
      [Player.Draw] = function()
        if player._phase_end then return end
        data.n = 2 -- FIXME: 等待阶段拆分
        room.logic:trigger(fk.DrawNCards, player, data)
        if data.n > 0 then
          room:drawCards(player, data.n, "phase_draw")
        end
        room.logic:trigger(fk.AfterDrawNCards, player, data)
      end,
      [Player.Play] = function()
        --player._phase_end = false
        if player._phase_end then return end
        room:doBroadcastNotify("UpdateSkill", "", {player})
        while not player.dead do
          if player._phase_end then break end
          local data = { timeout = room.timeout }
          logic:trigger(fk.StartPlayCard, player, data, true)

          local req = Request:new(player, "PlayCard")
          req.timeout = data.timeout
          local result = req:getResult(player)
          if result == "" then break end

          local useResult = room:handleUseCardReply(player, result)
          if type(useResult) == "table" then
            room:useCard(useResult)
          end
        end
      end,
      [Player.Discard] = function()
        if player._phase_end then return end
        local discardNum = #table.filter(
          player:getCardIds(Player.Hand), function(id)
            local card = Fk:getCardById(id)
            return table.every(room.status_skills[MaxCardsSkill] or Util.DummyTable, function(skill)
              return not skill:excludeFrom(player, card)
            end)
          end
        ) - player:getMaxCards()
        room:broadcastProperty(player, "MaxCards")
        if discardNum > 0 then
          room:askForDiscard(player, discardNum, discardNum, false, "phase_discard", false)
        end
      end,
      [Player.Finish] = function()

      end,
      })
    end
  end
end

function Phase:clear()
  local room = self.room
  local logic = room.logic
  local data = table.unpack(self.data)
  local player = data.who

  if player.phase ~= Player.NotActive then
    logic:trigger(fk.EventPhaseEnd, player, data, self.interrupted)
    logic:trigger(fk.AfterPhaseEnd, player, data, self.interrupted)
  else
    player.skipped_phases = {}
  end

  for _, p in ipairs(room.players) do
    p:setCardUseHistory("", 0, Player.HistoryPhase)
    p:setSkillUseHistory("", 0, Player.HistoryPhase)
    for name, _ in pairs(p.mark) do
      if name:find("-phase", 1, true) then
        room:setPlayerMark(p, name, 0)
      end
    end
    p._phase_end = false
  end

  for cid, cmark in pairs(room.card_marks) do
    for name, _ in pairs(cmark) do
      if name:find("-phase", 1, true) then
        room:setCardMark(Fk:getCardById(cid), name, 0)
      end
    end
  end

  for _, p in ipairs(room.players) do
    p:filterHandcards()
    room:broadcastProperty(p, "MaxCards")
  end
end

return { DrawInitial, Round, Turn, Phase }
