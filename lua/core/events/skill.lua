
--- SkillData 技能作用目标的数据（用于主动技）
---@class SkillUseDataSpec
---@field public from ServerPlayer @ 使用者
---@field public tos ServerPlayer[] @ 角色目标
---@field public cards integer[] @ 选择卡牌

--- 技能使用的数据
---@class SkillUseData: SkillUseDataSpec, TriggerData
SkillUseData = TriggerData:subclass("SkillUseData")

---@class SkillEffectDataSpec
---@field public skill_cb fun():any @ 实际技能函数
---@field public who ServerPlayer @ 技能发动者
---@field public skill Skill @ 发动的技能
---@field public skill_data SkillUseData @ 技能数据
---@field public prevented? boolean @ 防止执行技能效果（仅用于触发技、主动技、转化技）
---@field public trigger_break? boolean @ 停止继续触发此时机（仅用于触发技）

--- 技能效果的数据（用于可发动的技能，主动技、视为技、触发技）
---@class SkillEffectData: SkillEffectDataSpec, TriggerData
SkillEffectData = TriggerData:subclass("SkillEffectData")

---@class SkillEffectEvent: TriggerEvent
---@field data SkillEffectData
local SkillEffectEvent = TriggerEvent:subclass("SkillEffectEvent")

---@class fk.SkillEffect: SkillEffectEvent
fk.SkillEffect = SkillEffectEvent:subclass("fk.SkillEffect")
---@class fk.AfterSkillEffect: SkillEffectEvent
fk.AfterSkillEffect = SkillEffectEvent:subclass("fk.AfterSkillEffect")

--- SkillModifyData 技能获取或移除的数据
---@class SkillModifyDataSpec
---@field public who ServerPlayer @ 技能拥有者
---@field public skill Skill @ 有关的技能

--- 技能获取或移除的数据
---@class SkillModifyData: SkillModifyDataSpec, TriggerData
SkillModifyData = TriggerData:subclass("SkillModifyData")

---@class SkillModifyEvent: TriggerEvent
---@field data SkillModifyData
local SkillModifyEvent = TriggerEvent:subclass("SkillModifyEvent")

---@class fk.EventLoseSkill: SkillModifyEvent
fk.EventLoseSkill = TriggerEvent:subclass("fk.EventLoseSkill")
---@class fk.EventAcquireSkill: SkillModifyEvent
fk.EventAcquireSkill = TriggerEvent:subclass("fk.EventAcquireSkill")

---@alias SkillEffectTrigFunc fun(self: TriggerSkill, event: SkillEffectEvent,
---  target: ServerPlayer, player: ServerPlayer, data: SkillEffectData): any
---@alias SkillModifyTrigFunc fun(self: TriggerSkill, event: SkillModifyEvent,
---  target: ServerPlayer, player: ServerPlayer, data: SkillModifyData): any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: SkillEffectEvent,
---  data: TrigSkelSpec<SkillEffectTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: SkillModifyEvent,
---  data: TrigSkelSpec<SkillModifyTrigFunc>, attr: TrigSkelAttribute?): SkillSkeleton
