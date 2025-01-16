-- SPDX-License-Identifier: GPL-3.0-or-later

---@class HpEventWrappers: Object
local HpEventWrappers = {} -- mixin

---@return boolean
local function exec(tp, ...)
  local event = tp:create(...)
  local _, ret = event:exec()
  return ret
end

-- local damage_nature_table = {
--   [fk.NormalDamage] = "normal_damage",
--   [fk.FireDamage] = "fire_damage",
--   [fk.ThunderDamage] = "thunder_damage",
--   [fk.IceDamage] = "ice_damage",
-- }

local function sendDamageLog(room, damageData)
  local damageName = Fk:getDamageNatureName(damageData.damageType)
  if damageData.from then
    room:sendLog{
      type = "#Damage",
      to = {damageData.from.id},
      from = damageData.to.id,
      arg = damageData.damage,
      arg2 = damageName,
    }
  else
    room:sendLog{
      type = "#DamageWithNoFrom",
      from = damageData.to.id,
      arg = damageData.damage,
      arg2 = damageName,
    }
  end
  room:sendLogEvent("Damage", {
    to = damageData.to.id,
    damageType = damageName,
    damageNum = damageData.damage,
  })
end

---@class GameEvent.ChangeHp : GameEvent
---@field public data [HpChangedData]
local ChangeHp = GameEvent:subclass("GameEvent.ChangeHp")
function ChangeHp:main()
  local data = table.unpack(self.data)
  local room = self.room
  local logic = room.logic

  if data:initData(room) then return false end
 
  if logic:trigger(fk.BeforeHpChanged, data.who, data) then
    logic:breakEvent(false)
  end


  local reason, damageData = data.reason, data.damageEvent
  local player, num = data.who, data.num

  if reason == "damage" then
    if data.shield_lost > 0 and not (damageData and damageData.isVirtualDMG) then
      room:changeShield(data.who, -data.shield_lost)
    end
    sendDamageLog(room, damageData)
  end

  if not (reason == "damage" and (data.num == 0 or (damageData and damageData.isVirtualDMG))) then
    assert(not (data.reason == "recover" and data.num < 0))
    data.who.hp = math.min(data.who.hp + data.num, data.who.maxHp)
    room:broadcastProperty(data.who, "hp")

    if reason == "loseHp" then
      room:sendLog{
        type = "#LoseHP",
        from = data.who.id,
        arg = 0 - data.num,
      }
      room:sendLogEvent("LoseHP", {})
    elseif reason == "recover" then
      room:sendLog{
        type = "#HealHP",
        from = data.who.id,
        arg = data.num,
      }
    end

    room:sendLog{
      type = "#ShowHPAndMaxHP",
      from = data.who.id,
      arg = data.who.hp,
      arg2 = data.who.maxHp,
    }
  end

  logic:trigger(fk.HpChanged, data.who, data)

  if data.who.hp < 1 then
    if num < 0 and not data.preventDying then
      local dyingDataSpec = {
        who = data.who.id,
        damage = damageData,
      }
      room:enterDying(dyingDataSpec)
    end
  elseif data.who.dying then
    data.who.dying = false
    room:broadcastProperty(data.who, "dying")
  end

  return true
end

--- 改变一名玩家的体力。
---@param player ServerPlayer @ 玩家
---@param num integer @ 变化量
---@param reason? string @ 原因
---@param skillName? string @ 技能名
---@param damageData? DamageData @ 伤害数据
---@return boolean
function HpEventWrappers:changeHp(player, num, reason, skillName, damageData)
  local data = HpChangedData:new{
    who = player,
    num = num,
    reason = reason,
    skillName = skillName,
    damageEvent = damageData
  }
  return exec(ChangeHp, data)
end

---@class GameEvent.Damage : GameEvent
---@field public data [DamageData]
local Damage = GameEvent:subclass("GameEvent.Damage")
function Damage:main()
  local damageData = table.unpack(self.data)
  local room = self.room
  local logic = room.logic

  damageData:initData(room)

  local stages = {}

  if not damageData.isVirtualDMG then
    stages = {
      { fk.PreDamage, "from"},
      { fk.DamageCaused, "from" },
      { fk.DamageInflicted, "to" },
    }
  end

  for _, struct in ipairs(stages) do
    local event, player = table.unpack(struct)
    if logic:trigger(event, damageData[player], damageData) then
      logic:breakEvent(false)
    end
  end

  damageData.dealtRecorderId = room.logic.specific_events_id[GameEvent.Damage]
  room.logic.specific_events_id[GameEvent.Damage] = room.logic.specific_events_id[GameEvent.Damage] + 1

  if damageData.card and damageData.damage > 0 then
    local parentUseData = logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      local cardUseEvent = parentUseData.data[1]
      cardUseEvent.damageDealt = cardUseEvent.damageDealt or {}
      cardUseEvent.damageDealt[damageData.to.id] = (cardUseEvent.damageDealt[damageData.to.id] or 0) + damageData.damage
    end
  end

  if not room:changeHp(
    damageData.to,
    -damageData.damage,
    "damage",
    damageData.skillName,
    damageData) then
    logic:breakEvent(false)
  end


  stages = {
    {fk.Damage, "from"},
    {fk.Damaged, "to"},
  }

  for _, struct in ipairs(stages) do
    local event, player = table.unpack(struct)
    logic:trigger(event, damageData[player], damageData)
  end

  return true
end

function Damage:exit()
  local room = self.room
  local logic = room.logic
  local damageData = self.data[1]

  logic:trigger(fk.DamageFinished, damageData.to, damageData)

  if damageData.chain_table and #damageData.chain_table > 0 then
    damageData.chain_table = table.filter(damageData.chain_table, function(p)
      return p:isAlive() and p.chained
    end)
    local dmg = {
      from = damageData.from,
      damage = damageData.damage,
      damageType = damageData.damageType,
      card = damageData.card,
      skillName = damageData.skillName,
      chain = true,
    }
    for _, p in ipairs(damageData.chain_table) do
      room:sendLog{
        type = "#ChainDamage",
        from = p.id
      }
      dmg.to = p

      room:damage(dmg)
    end
  end
end

--- 根据伤害数据造成伤害。
---@param damageData DamageDataSpec
---@return boolean
function HpEventWrappers:damage(damageData)
  local data = DamageData:new(damageData)
  return exec(Damage, data)
end

---@class GameEvent.LoseHp : GameEvent
---@field public data [HpLostData]
local LoseHp = GameEvent:subclass("GameEvent.LoseHp")
function LoseHp:main()
  local data = table.unpack(self.data)
  local room = self.room
  local logic = room.logic

  local data = HpLostData:new{
    num = num,
    who = player,
    skillName = skillName,
  }
  if logic:trigger(fk.PreHpLost, data.who, data) then
    logic:breakEvent(false)
  end

  if not room:changeHp(data.who, -data.num, "loseHp", skillName) then
    logic:breakEvent(false)
  end

  logic:trigger(fk.HpLost, data.who, data)
  return true
end

--- 令一名玩家失去体力。
---@param player ServerPlayer @ 玩家
---@param num integer @ 失去的数量
---@param skillName? string @ 技能名
---@return boolean
function HpEventWrappers:loseHp(player, num, skillName)
  local data = HpLostData:new{
    who = player,
    num = num,
    skillName = skillName,
  }
  return exec(LoseHp, data)
end

---@class GameEvent.Recover : GameEvent
---@field public data [RecoverData]
local Recover = GameEvent:subclass("GameEvent.Recover")
function Recover:prepare()
  local recoverData = table.unpack(self.data)
  -- local room = self.room
  -- local logic = room.logic

  local who = recoverData.who

  if who.maxHp - who.hp < 0 then
    return true
  end

end

function Recover:main()
  local recoverData = table.unpack(self.data)
  local room = self.room
  local logic = room.logic
  recoverData:initData(room)
  local who = recoverData.who

  if logic:trigger(fk.PreHpRecover, who, recoverData) then
    logic:breakEvent(false)
  end

  recoverData.num = math.min(recoverData.num, who.maxHp - who.hp)

  if recoverData:checkBreak() or not room:changeHp(who, recoverData.num, "recover", recoverData.skillName) then
    logic:breakEvent(false)
  end

  logic:trigger(fk.HpRecover, who, recoverData)
  return true
end

--- 根据回复数据回复体力。
---@param recoverDataSpec RecoverDataSpec
---@return boolean @ 是否成功回复体力
function HpEventWrappers:recover(recoverDataSpec)
  local recoverData = RecoverData:new(recoverDataSpec)
  return exec(Recover, recoverData)
end

---@class GameEvent.ChangeMaxHp : GameEvent
---@field public data [MaxHpChangedData]
local ChangeMaxHp = GameEvent:subclass("GameEvent.ChangeMaxHp")
function ChangeMaxHp:main()
  local data = table.unpack(self.data)
  local room = self.room

  if data:checkBreak() or room.logic:trigger(fk.BeforeMaxHpChanged, data.who, data) or data.num == 0 then
    return false
  end


  local player = data.who
  local num = data.num

  room:setPlayerProperty(player, "maxHp", math.max(player.maxHp + num, 0))
  room:sendLogEvent("ChangeMaxHp", {
    player = player.id,
    num = num,
  })
  room:sendLog{
    type = num > 0 and "#HealMaxHP" or "#LoseMaxHP",
    from = player.id,
    arg = num > 0 and num or - num,
  }
  if player.maxHp == 0 then
    player.hp = 0
    room:broadcastProperty(player, "hp")
    room:sendLog{
      type = "#ShowHPAndMaxHP",
      from = player.id,
      arg = 0,
      arg2 = 0,
    }
    room:killPlayer({ who = player.id })
    return false
  end

  local diff = player.hp - player.maxHp
  if diff > 0 then
    if not room:changeHp(player, -diff) then
      player.hp = player.hp - diff
    end
  end

  room:sendLog{
    type = "#ShowHPAndMaxHP",
    from = player.id,
    arg = player.hp,
    arg2 = player.maxHp,
  }

  room.logic:trigger(fk.MaxHpChanged, player, data)
  return true
end

--- 改变一名玩家的体力上限。
---@param player ServerPlayer @ 玩家
---@param num integer @ 变化量
---@return boolean
function HpEventWrappers:changeMaxHp(player, num)
  local data = MaxHpChangedData:new{
    who = player,
    num = num,
  }
  return exec(ChangeMaxHp, data)
end

return { ChangeHp, Damage, LoseHp, Recover, ChangeMaxHp, HpEventWrappers }
