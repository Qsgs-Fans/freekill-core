
--- DrawInitialData 关于摸起始手牌的数据
---@class DrawInitialDataSpec
---@field public num integer @ 摸牌数

--- 关于摸起始手牌的数据
---@class DrawInitialData: DrawInitialDataSpec, TriggerData
DrawInitialData = TriggerData:subclass("DrawInitialData")

---@class DrawInitialEvent: TriggerEvent
---@field data DrawInitialData
local DrawInitialEvent = TriggerEvent:subclass("DrawInitialEvent")

---@class fk.DrawInitialCards: DrawInitialEvent
fk.DrawInitialCards = TriggerEvent:subclass("fk.DrawInitialCards")
---@class fk.AfterDrawInitialCards: DrawInitialEvent
fk.AfterDrawInitialCards = TriggerEvent:subclass("fk.AfterDrawInitialCards")

---@class fk.EventTurnChanging: TriggerEvent
fk.EventTurnChanging = TriggerEvent:subclass("fk.EventTurnChanging")

---@class fk.GameStart: TriggerEvent
fk.GameStart = TriggerEvent:subclass("fk.GameStart")

--- RoundData 轮次的数据
---@class RoundDataSpec -- TODO: 发挥想象力，填写这个Spec吧
---@field turn_table? integer[] @ 额定回合表，填空则为正常流程

--- 轮次的数据
---@class RoundData: RoundDataSpec, TriggerData
---@field turn_table integer[] @ 额定回合表
RoundData = TriggerData:subclass("RoundData")

---@class RoundEvent: TriggerEvent
---@field data RoundData
local RoundEvent = TriggerEvent:subclass("RoundEvent")

---@class fk.RoundStart: RoundEvent
fk.RoundStart = RoundEvent:subclass("fk.RoundStart")
---@class fk.RoundEnd: RoundEvent
fk.RoundEnd = RoundEvent:subclass("fk.RoundEnd")
---@class fk.AfterRoundEnd: RoundEvent
fk.AfterRoundEnd = RoundEvent:subclass("fk.AfterRoundEnd")

--- TurnData 回合的数据
---@class TurnDataSpec -- TODO: 发挥想象力，填写这个Spec吧
---@field reason? string @ 当前额外回合的原因，不为额外回合则为game_rule
---@field phase_table? Phase[] @ 额定阶段表，填空则为正常流程

--- 回合的数据
---@class TurnData: TurnDataSpec, TriggerData
TurnData = TriggerData:subclass("TurnData")

---@class TurnEvent: TriggerEvent
---@field data TurnData
local TurnEvent = TriggerEvent:subclass("TurnEvent")

---@class fk.PreTurnStart: TurnEvent
fk.PreTurnStart = TurnEvent:subclass("fk.PreTurnStart")
---@class fk.BeforeTurnStart: TurnEvent
fk.BeforeTurnStart = TurnEvent:subclass("fk.BeforeTurnStart")
---@class fk.TurnStart: TurnEvent
fk.TurnStart = TurnEvent:subclass("fk.TurnStart")
---@class fk.TurnEnd: TurnEvent
fk.TurnEnd = TurnEvent:subclass("fk.TurnEnd")
---@class fk.AfterTurnEnd: TurnEvent
fk.AfterTurnEnd = TurnEvent:subclass("fk.AfterTurnEnd")

--- PhaseData 阶段的数据
---@class PhaseDataSpec -- TODO: 发挥想象力，填写这个Spec吧
---@field reason? string @ 额外阶段的指示物
---@field phase_end? boolean @ 该阶段是否即将结束

--- 阶段的数据
---@class PhaseData: PhaseDataSpec, TriggerData
PhaseData = TriggerData:subclass("PhaseData")

---@class PhaseEvent: TriggerEvent
---@field data PhaseData
local PhaseEvent = TriggerEvent:subclass("PhaseEvent")

---@class fk.EventPhaseStart: PhaseEvent
fk.EventPhaseStart = PhaseEvent:subclass("fk.EventPhaseStart")
---@class fk.EventPhaseProceeding: PhaseEvent
fk.EventPhaseProceeding = PhaseEvent:subclass("fk.EventPhaseProceeding")
---@class fk.EventPhaseEnd: PhaseEvent
fk.EventPhaseEnd = PhaseEvent:subclass("fk.EventPhaseEnd")
---@class fk.AfterPhaseEnd: PhaseEvent
fk.AfterPhaseEnd = PhaseEvent:subclass("fk.AfterPhaseEnd")
---@class fk.EventPhaseChanging: PhaseEvent
fk.EventPhaseChanging = PhaseEvent:subclass("fk.EventPhaseChanging")
---@class fk.EventPhaseSkipping: PhaseEvent
fk.EventPhaseSkipping = PhaseEvent:subclass("fk.EventPhaseSkipping")
---@class fk.EventPhaseSkipped: PhaseEvent
fk.EventPhaseSkipped = PhaseEvent:subclass("fk.EventPhaseSkipped")

---@class fk.DrawNCards: TriggerEvent
fk.DrawNCards = TriggerEvent:subclass("fk.DrawNCards")
---@class fk.AfterDrawNCards: TriggerEvent
fk.AfterDrawNCards = TriggerEvent:subclass("fk.AfterDrawNCards")

---@class fk.StartPlayCard: TriggerEvent
fk.StartPlayCard = TriggerEvent:subclass("fk.StartPlayCard")

-- 注释

---@alias RoundFunc fun(self: TriggerSkill, event: RoundEvent,
---  target: ServerPlayer, player: ServerPlayer, data: RoundData): any

---@alias TurnFunc fun(self: TriggerSkill, event: TurnEvent,
---  target: ServerPlayer, player: ServerPlayer, data: TurnData): any

---@alias PhaseFunc fun(self: TriggerSkill, event: PhaseEvent,
---  target: ServerPlayer, player: ServerPlayer, data: PhaseData): any

---@class SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: RoundEvent,
---  attr: TrigSkelAttribute?, data: TrigSkelSpec<RoundFunc>): SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: TurnEvent,
---  attr: TrigSkelAttribute?, data: TrigSkelSpec<TurnFunc>): SkillSkeleton
---@field public addEffect fun(self: SkillSkeleton, key: PhaseEvent,
---  attr: TrigSkelAttribute?, data: TrigSkelSpec<PhaseFunc>): SkillSkeleton
