---@class HpChangedEvent: TriggerEvent
---@field data HpChangedData
local HpChangedEvent = TriggerEvent:subclass("HpChangedEvent")

---@class fk.BeforeHpChanged: HpChangedEvent
fk.BeforeHpChanged = HpChangedEvent:subclass("fk.BeforeHpChanged")
---@class fk.HpChanged: HpChangedEvent
fk.HpChanged = HpChangedEvent:subclass("fk.HpChanged")

---@class DamageEvent: TriggerEvent
---@field data DamageStruct
local DamageEvent = TriggerEvent:subclass("DamageEvent")

---@class fk.PreDamage: DamageEvent
fk.PreDamage = DamageEvent:subclass("fk.PreDamage")
---@class fk.DamageCaused: DamageEvent
fk.DamageCaused = DamageEvent:subclass("fk.DamageCaused")
---@class fk.DamageInflicted: DamageEvent
fk.DamageInflicted = DamageEvent:subclass("fk.DamageInflicted")
---@class fk.Damage: DamageEvent
fk.Damage = DamageEvent:subclass("fk.Damage")
---@class fk.Damaged: DamageEvent
fk.Damaged = DamageEvent:subclass("fk.Damaged")
---@class fk.DamageFinished: DamageEvent
fk.DamageFinished = DamageEvent:subclass("fk.DamageFinished")

---@class HpLostEvent: TriggerEvent
---@field public data HpLostData
local HpLostEvent = TriggerEvent:subclass("HpLostEvent")

---@class fk.PreHpLost: HpLostEvent
fk.PreHpLost = HpLostEvent:subclass("fk.PreHpLost")
---@class fk.HpLost: HpLostEvent
fk.HpLost = HpLostEvent:subclass("fk.HpLost")

---@class RecoverEvent: TriggerEvent
---@field public data RecoverStruct
local RecoverEvent = TriggerEvent:subclass("RecoverEvent")

---@class fk.PreHpRecover: RecoverEvent
fk.PreHpRecover = RecoverEvent:subclass("fk.PreHpRecover")
---@class fk.HpRecover: RecoverEvent
fk.HpRecover = RecoverEvent:subclass("fk.HpRecover")

---@class MaxHpChangedEvent: TriggerEvent
---@field public data MaxHpChangedData
local MaxHpChangedEvent = TriggerEvent:subclass("MaxHpChangedEvent")

---@class fk.BeforeMaxHpChanged: MaxHpChangedEvent
fk.BeforeMaxHpChanged = MaxHpChangedEvent:subclass("fk.BeforeMaxHpChanged")
---@class fk.MaxHpChanged: MaxHpChangedEvent
fk.MaxHpChanged = MaxHpChangedEvent:subclass("fk.MaxHpChanged")

-- 注释环节

--[[
先三个大any得了
---@class DamageSkelAttr: TrigSkelAttribute

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: HpChangedEvent,
---  attr: TrigSkelAttribute?, data: HpChangedSkelSpec): SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: DamageEvent,
---  attr: DamageSkelAttr?, data: DamageSkelSpec): SkillSkeleton
--]]
