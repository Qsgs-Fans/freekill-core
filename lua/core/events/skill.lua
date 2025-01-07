
--- SkillEffectData 技能效果的数据
---@class SkillEffectDataSpec
---@field public from PlayerId @ 使用者
---@field public tos PlayerId[] @ 角色目标
---@field public cards integer[] @ 选择卡牌

--- 技能效果的数据
---@class SkillEffectData: SkillEffectDataSpec, TriggerData
SkillEffectData = TriggerData:subclass("SkillEffectData")

---@class SkillEffectEvent: TriggerEvent
---@field data SkillEffectData
local SkillEffectEvent = TriggerEvent:subclass("SkillEffectEvent")

---@class fk.SkillEffect: SkillEffectEvent
fk.SkillEffect = SkillEffectEvent:subclass("fk.SkillEffect")
---@class fk.AfterSkillEffect: SkillEffectEvent
fk.AfterSkillEffect = SkillEffectEvent:subclass("fk.AfterSkillEffect")

---@class fk.EventLoseSkill: TriggerEvent
fk.EventLoseSkill = TriggerEvent:subclass("fk.EventLoseSkill")
---@class fk.EventAcquireSkill: TriggerEvent
fk.EventAcquireSkill = TriggerEvent:subclass("fk.EventAcquireSkill")

-- 注释

---@alias SkillEffectTrigFunc fun(self: TriggerSkill, event: SkillEffectEvent,
---  target: ServerPlayer, player: ServerPlayer, data: SkillEffectData): any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: SkillEffectEvent,
---  attr: TrigSkelAttribute?, data: TrigSkelSpec<SkillEffectTrigFunc>): SkillSkeleton
