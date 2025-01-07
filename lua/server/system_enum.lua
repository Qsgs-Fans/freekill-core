-- SPDX-License-Identifier: GPL-3.0-or-later

---@alias PlayerId integer

--- askForUseCard中的extra_data
---@class UseExtraData
---@field public must_targets? integer[] @ 必须选择这些目标？
---@field public include_targets? integer[] @ 必须选其中一个目标？
---@field public exclusive_targets? integer[] @ 只能选择这些目标？
---@field public bypass_distances? boolean @ 无距离限制？
---@field public bypass_times? boolean @ 无次数限制？
---@field public playing? boolean @ (AI专用) 出牌阶段？

--- AimStruct 处理使用牌目标的数据
---@class AimStruct
---@field public from integer @ 使用者
---@field public card Card @ 卡牌本牌
---@field public tos AimGroup @ 总角色目标
---@field public to integer @ 当前角色目标
---@field public subTargets? integer[] @ 子目标（借刀！）
---@field public targetGroup? TargetGroup @ 目标组
---@field public nullifiedTargets? integer[] @ 对这些角色无效
---@field public firstTarget boolean @ 是否是第一个目标
---@field public additionalDamage? integer @ 额外伤害值（如酒之于杀）
---@field public additionalRecover? integer @ 额外回复值
---@field public disresponsive? boolean @ 是否不可响应
---@field public unoffsetable? boolean @ 是否不可抵消
---@field public fixedResponseTimes? table<string, integer>|integer @ 额外响应请求
---@field public fixedAddTimesResponsors? integer[] @ 额外响应请求次数
---@field public additionalEffect? integer @额外结算次数
---@field public extraData? UseExtraData | any @ 额外数据

--- AskForCardUse 询问使用卡牌的数据
---@class AskForCardUse
---@field public user ServerPlayer @ 使用者
---@field public cardName string @ 烧条信息
---@field public pattern string @ 可用牌过滤
---@field public eventData? CardEffectEvent @ 事件数据
---@field public extraData? UseExtraData | any @ 额外数据
---@field public result? UseCardDataSpec @ 使用结果

--- AskForCardResponse 询问响应卡牌的数据
---@class AskForCardResponse
---@field public user ServerPlayer @ 响应者
---@field public cardName string @ 烧条信息
---@field public pattern string @ 可用牌过滤
---@field public extraData? UseExtraData | any @ 额外数据
---@field public result? Card

--- LogMessage 战报信息
---@class LogMessage
---@field public type string @ log主体
---@field public from? integer @ 要替换%from的玩家的id
---@field public to? integer[] @ 要替换%to的玩家id列表
---@field public card? integer[] @ 要替换%card的卡牌id列表
---@field public arg? any @ 要替换%arg的内容
---@field public arg2? any @ 要替换%arg2的内容
---@field public arg3? any @ 要替换%arg3的内容
---@field public toast? boolean @ 是否顺手把消息发送一条相同的toast

--- SkillUseStruct 使用技能的数据
---@class SkillUseStruct
---@field public skill Skill
---@field public willUse boolean

--- DrawCardStruct 摸牌的数据
---@class DrawCardStruct
---@field public who ServerPlayer @ 摸牌者
---@field public num number @ 摸牌数
---@field public skillName string @ 技能名
---@field public fromPlace "top"|"bottom" @ 摸牌的位置

--- TurnStruct 回合事件的数据
---@class TurnStruct
---@field public reason string? @ 当前额外回合的原因，不为额外回合则为game_rule
---@field public phase_table? Phase[] @ 此回合将进行的阶段，填空则为正常流程

--- 移动理由
---@alias CardMoveReason integer
fk.ReasonJustMove = 1
fk.ReasonDraw = 2
fk.ReasonDiscard = 3
fk.ReasonGive = 4
fk.ReasonPut = 5
fk.ReasonPutIntoDiscardPile = 6
fk.ReasonPrey = 7
fk.ReasonExchange = 8
fk.ReasonUse = 9
fk.ReasonResonpse = 10
fk.ReasonJudge = 11
fk.ReasonRecast = 12

--- 内置动画类型，理论上你可以自定义一个自己的动画类型（big会播放一段限定技动画）
---@alias AnimationType "special" | "drawcard" | "control" | "offensive" | "support" | "defensive" | "negative" | "masochism" | "switch" | "big"
