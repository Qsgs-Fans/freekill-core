-- SPDX-License-Identifier: GPL-3.0-or-later

---@class DeathEventWrappers: Object
local DeathEventWrappers = {} -- mixin

---@return boolean
local function exec(tp, ...)
  local event = tp:create(...)
  local _, ret = event:exec()
  return ret
end

---@class GameEvent.Dying : GameEvent
---@field data [DyingData]
local Dying = GameEvent:subclass("GameEvent.Dying")
function Dying:main()
  local dyingData = table.unpack(self.data)
  local room = self.room
  local logic = room.logic
  local dyingPlayer = room:getPlayerById(dyingData.who)
  dyingPlayer.dying = true
  room:broadcastProperty(dyingPlayer, "dying")
  room:sendLog{
    type = "#EnterDying",
    from = dyingPlayer.id,
  }
  logic:trigger(fk.EnterDying, dyingPlayer, dyingData)

  if dyingPlayer.hp < 1 then
    -- room.logic:trigger(fk.Dying, dyingPlayer, dyingStruct)
    local savers = room:getAlivePlayers()
    for _, p in ipairs(savers) do
      if not p.dead then
        if dyingPlayer.hp > 0 or dyingPlayer.dead or logic:trigger(fk.AskForPeaches, p, dyingData) then
          break
        end
      end
    end
    logic:trigger(fk.AskForPeachesDone, dyingPlayer, dyingData)
  end
end

function Dying:exit()
  local room = self.room
  local logic = room.logic
  local dyingData = self.data[1]

  local dyingPlayer = room:getPlayerById(dyingData.who)

  if dyingPlayer.dying then
    dyingPlayer.dying = false
    room:broadcastProperty(dyingPlayer, "dying")
  end
  logic:trigger(fk.AfterDying, dyingPlayer, dyingData, self.interrupted)
end

--- 根据濒死数据让人进入濒死。
---@param dyingDataSpec DyingDataSpec
function DeathEventWrappers:enterDying(dyingDataSpec)
  local dyingData = DyingData:new(dyingDataSpec)
  return exec(Dying, dyingData)
end

---@class GameEvent.Death : GameEvent
---@field data [DeathData]
local Death = GameEvent:subclass("GameEvent.Death")
function Death:prepare()
  local deathData = table.unpack(self.data)
  local room = self.room
  local victim = room:getPlayerById(deathData.who)
  if victim.dead then
    return true
  end
end

function Death:main()
  local deathData = table.unpack(self.data)
  local room = self.room
  local victim = room:getPlayerById(deathData.who)
  victim.dead = true

  if victim.rest <= 0 then
    victim._splayer:setDied(true)
  end

  table.removeOne(room.alive_players, victim)

  local logic = room.logic
  logic:trigger(fk.BeforeGameOverJudge, victim, deathData)

  local killer = deathData.damage and deathData.damage.from or nil
  if killer then
    room:sendLog{
      type = "#KillPlayer",
      to = {killer.id},
      from = victim.id,
      arg = (victim.rest > 0 and 'unknown' or victim.role),
    }
  else
    room:sendLog{
      type = "#KillPlayerWithNoKiller",
      from = victim.id,
      arg = (victim.rest > 0 and 'unknown' or victim.role),
    }
  end
  room:sendLogEvent("Death", {to = victim.id})

  if victim.rest == 0 then
    room:setPlayerProperty(victim, "role_shown", true)
    -- room:broadcastProperty(victim, "role")
  end
  room:broadcastProperty(victim, "dead")

  victim.drank = 0
  room:broadcastProperty(victim, "drank")
  victim.shield = 0
  room:broadcastProperty(victim, "shield")

  logic:trigger(fk.GameOverJudge, victim, deathData)
  logic:trigger(fk.Death, victim, deathData)
  logic:trigger(fk.BuryVictim, victim, deathData)

  logic:trigger(fk.Deathed, victim, deathData)
end

--- 根据死亡数据杀死角色。
---@param deathDataSpec DeathDataSpec
function DeathEventWrappers:killPlayer(deathDataSpec)
  local deathData = DeathData:new(deathDataSpec)
  return exec(Death, deathData)
end

---@class GameEvent.Revive : GameEvent
---@field data [ServerPlayer, boolean?, string?]
local Revive = GameEvent:subclass("GameEvent.Revive")
function Revive:main()
  local room = self.room
  local player, sendLog, reason = table.unpack(self.data)

  if not player.dead then return end
  room:setPlayerProperty(player, "dead", false)
  player._splayer:setDied(false)
  room:setPlayerProperty(player, "dying", false)
  room:setPlayerProperty(player, "hp", player.maxHp)
  table.insertIfNeed(room.alive_players, player)

  sendLog = (sendLog == nil) and true or sendLog
  if sendLog then
    room:sendLog { type = "#Revive", from = player.id }
  end

  reason = reason or ""
  local data = ReviveData:new{
    who = player,
    reason = reason
  }
  room.logic:trigger(fk.AfterPlayerRevived, player, data)
end

--- 复活一个角色
---@param player ServerPlayer @ 要复活的角色
---@param sendLog? boolean? @ 是否播放战报
---@param reason? string? @ 复活原因
function DeathEventWrappers:revivePlayer(player, sendLog, reason)
  return exec(Revive, player, sendLog, reason)
end

return { Dying, Death, Revive, DeathEventWrappers }
