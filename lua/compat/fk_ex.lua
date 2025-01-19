-- 牢函数

---@class LegacyTriggerSkillSpec: UsableSkillSpec
---@field public global? boolean
---@field public events? (TriggerEvent|integer|string) | (TriggerEvent|integer|string)[]
---@field public refresh_events? (TriggerEvent|integer|string) | (TriggerEvent|integer|string)[]
---@field public priority? number | table<(TriggerEvent|integer|string), number>
---@field public on_trigger? TrigFunc
---@field public can_trigger? TrigFunc
---@field public on_cost? TrigFunc
---@field public on_use? TrigFunc
---@field public on_refresh? TrigFunc
---@field public can_refresh? TrigFunc
---@field public can_wake? TrigFunc

---@deprecated
---@param spec LegacyTriggerSkillSpec
---@return LegacyTriggerSkill
function fk.CreateTriggerSkill(spec)
  assert(type(spec.name) == "string")
  --assert(type(spec.on_trigger) == "function")
  if spec.frequency then assert(type(spec.frequency) == "number") end

  local frequency = spec.frequency or Skill.NotFrequent
  local skill = LegacyTriggerSkill:new(spec.name, frequency)
  fk.readUsableSpecToSkill(skill, spec)

  if type(spec.events) == "number" then
    table.insert(skill.events, spec.events)
  elseif type(spec.events) == "table" then
    table.insertTable(skill.events, spec.events)
  end

  if type(spec.refresh_events) == "number" then
    table.insert(skill.refresh_events, spec.refresh_events)
  elseif type(spec.refresh_events) == "table" then
    table.insertTable(skill.refresh_events, spec.refresh_events)
  end

  if type(spec.global) == "boolean" then skill.global = spec.global end

  if spec.on_trigger then skill.trigger = spec.on_trigger end

  if spec.can_trigger then
    if spec.frequency == Skill.Wake then
      skill.triggerable = function(self, event, target, player, data)
        return spec.can_trigger(self, event, target, player, data) and
          skill:enableToWake(event, target, player, data)
      end
    else
      skill.triggerable = spec.can_trigger
    end
  end

  if skill.frequency == Skill.Wake and spec.can_wake then
    skill.canWake = spec.can_wake
  end

  if spec.on_cost then skill.cost = spec.on_cost end
  if spec.on_use then skill.use = spec.on_use end

  if spec.can_refresh then
    skill.canRefresh = spec.can_refresh
  end

  if spec.on_refresh then
    skill.refresh = spec.on_refresh
  end

  if spec.attached_equip then
    if not spec.priority then
      spec.priority = 0.1
    end
  elseif not spec.priority then
    spec.priority = 1
  end

  if type(spec.priority) == "number" then
    for _, event in ipairs(skill.events) do
      skill.priority_table[event] = spec.priority
    end
  elseif type(spec.priority) == "table" then
    for event, priority in pairs(spec.priority) do
      skill.priority_table[event] = priority
    end
  end
  return skill
end

---@param spec ActiveSkillSpec
---@return ActiveSkill
---@deprecated
function fk.CreateActiveSkill(spec)
  assert(type(spec.name) == "string")
  local skill = ActiveSkill:new(spec.name, spec.frequency or Skill.NotFrequent)
  fk.readUsableSpecToSkill(skill, spec)

  if spec.can_use then
    skill.canUse = function(curSkill, player, card, extra_data)
      return spec.can_use(curSkill, player, card, extra_data) and curSkill:isEffectable(player)
    end
  end
  if spec.card_filter then skill.cardFilter = spec.card_filter end
  if spec.target_filter then skill.targetFilter = spec.target_filter end
  if spec.mod_target_filter then skill.modTargetFilter = spec.mod_target_filter end
  if spec.feasible then
    -- print(spec.name .. ": feasible is deprecated. Use target_num and card_num instead.")
    skill.feasible = spec.feasible
  end
  if spec.on_use then skill.onUse = function(self, room, effect)
    if type(effect.from) == "table" then
      effect.from = effect.from.id
    end

    if effect.tos and type(effect.tos[1]) == "table" then
      local new_v = {}
      for _, p in ipairs(effect.tos) do
        table.insert(new_v, p.id)
      end
      effect.tos = new_v
    end
    spec.on_use(self, room, effect)
  end end
  if spec.on_action then skill.onAction = spec.on_action end
  if spec.about_to_effect then skill.aboutToEffect = spec.about_to_effect end
  if spec.on_effect then skill.onEffect = spec.on_effect end
  if spec.on_nullified then skill.onNullified = spec.on_nullified end
  if spec.prompt then skill.prompt = spec.prompt end
  if spec.target_tip then skill.targetTip = spec.target_tip end

  if spec.interaction then
    skill.interaction = setmetatable({}, {
      __call = function()
        if type(spec.interaction) == "function" then
          return spec.interaction(skill)
        else
          return spec.interaction
        end
      end,
    })
  end
  return skill
end

---@param spec ViewAsSkillSpec
---@return ViewAsSkill
---@deprecated
function fk.CreateViewAsSkill(spec)
  assert(type(spec.name) == "string")
  assert(type(spec.view_as) == "function")

  local skill = ViewAsSkill:new(spec.name, spec.frequency or Skill.NotFrequent)
  fk.readUsableSpecToSkill(skill, spec)

  skill.viewAs = spec.view_as
  if spec.card_filter then
    skill.cardFilter = spec.card_filter
  end
  if type(spec.pattern) == "string" then
    skill.pattern = spec.pattern
  end
  if type(spec.enabled_at_play) == "function" then
    skill.enabledAtPlay = function(curSkill, player)
      return spec.enabled_at_play(curSkill, player) and curSkill:isEffectable(player)
    end
  end
  if type(spec.enabled_at_response) == "function" then
    skill.enabledAtResponse = function(curSkill, player, cardResponsing)
      return spec.enabled_at_response(curSkill, player, cardResponsing) and curSkill:isEffectable(player)
    end
  end
  if spec.prompt then skill.prompt = spec.prompt end

  if spec.interaction then
    skill.interaction = setmetatable({}, {
      __call = function()
        if type(spec.interaction) == "function" then
          return spec.interaction(skill)
        else
          return spec.interaction
        end
      end,
    })
  end

  if spec.before_use and type(spec.before_use) == "function" then
    skill.beforeUse = spec.before_use
  end

  if spec.after_use and type(spec.after_use) == "function" then
    skill.afterUse = spec.after_use
  end

  return skill
end

---@param spec DistanceSpec
---@return DistanceSkill
---@deprecated
function fk.CreateDistanceSkill(spec)
  assert(type(spec.name) == "string")
  assert(type(spec.correct_func) == "function" or type(spec.fixed_func) == "function")

  local skill = DistanceSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  skill.getCorrect = spec.correct_func
  skill.getFixed = spec.fixed_func

  return skill
end

---@param spec ProhibitSpec
---@return ProhibitSkill
---@deprecated
function fk.CreateProhibitSkill(spec)
  assert(type(spec.name) == "string")

  local skill = ProhibitSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  skill.isProhibited = spec.is_prohibited or skill.isProhibited
  skill.prohibitUse = spec.prohibit_use or skill.prohibitUse
  skill.prohibitResponse = spec.prohibit_response or skill.prohibitResponse
  skill.prohibitDiscard = spec.prohibit_discard or skill.prohibitDiscard
  skill.prohibitPindian = spec.prohibit_pindian or skill.prohibitPindian

  return skill
end

---@param spec AttackRangeSpec
---@return AttackRangeSkill
---@deprecated
function fk.CreateAttackRangeSkill(spec)
  assert(type(spec.name) == "string")
  assert(type(spec.correct_func) == "function" or type(spec.fixed_func) == "function" or
    type(spec.within_func) == "function" or type(spec.without_func) == "function")

  local skill = AttackRangeSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  if spec.correct_func then
    skill.getCorrect = spec.correct_func
  end
  if spec.fixed_func then
    skill.getFixed = spec.fixed_func
  end
  if spec.within_func then
    skill.withinAttackRange = spec.within_func
  end
  if spec.without_func then
    skill.withoutAttackRange = spec.without_func
  end

  return skill
end

---@param spec MaxCardsSpec
---@return MaxCardsSkill
---@deprecated
function fk.CreateMaxCardsSkill(spec)
  assert(type(spec.name) == "string")
  assert(type(spec.correct_func) == "function" or type(spec.fixed_func) == "function" or type(spec.exclude_from) == "function")

  local skill = MaxCardsSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  if spec.correct_func then
    skill.getCorrect = spec.correct_func
  end
  if spec.fixed_func then
    skill.getFixed = spec.fixed_func
  end
  skill.excludeFrom = spec.exclude_from or skill.excludeFrom

  return skill
end

---@param spec TargetModSpec
---@return TargetModSkill
---@deprecated
function fk.CreateTargetModSkill(spec)
  assert(type(spec.name) == "string")

  local skill = TargetModSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  if spec.bypass_times then
    skill.bypassTimesCheck = spec.bypass_times
  end
  if spec.residue_func then
    skill.getResidueNum = spec.residue_func
  end
  if spec.bypass_distances then
    skill.bypassDistancesCheck = spec.bypass_distances
  end
  if spec.distance_limit_func then
    skill.getDistanceLimit = spec.distance_limit_func
  end
  if spec.extra_target_func then
    skill.getExtraTargetNum = spec.extra_target_func
  end
  if spec.target_tip_func then
    skill.getTargetTip = spec.target_tip_func
  end

  return skill
end

---@param spec FilterSpec
---@return FilterSkill
---@deprecated
function fk.CreateFilterSkill(spec)
  assert(type(spec.name) == "string")

  local skill = FilterSkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  skill.cardFilter = spec.card_filter
  skill.viewAs = spec.view_as
  skill.equipSkillFilter = spec.equip_skill_filter

  return skill
end

---@param spec InvaliditySpec
---@return InvaliditySkill
---@deprecated
function fk.CreateInvaliditySkill(spec)
  assert(type(spec.name) == "string")

  local skill = InvaliditySkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)

  if spec.invalidity_func then
    skill.getInvalidity = spec.invalidity_func
  end
  if spec.invalidity_attackrange then
    skill.getInvalidityAttackRange = spec.invalidity_attackrange
  end

  return skill
end

---@param spec VisibilitySpec
---@return VisibilitySkill
---@deprecated
function fk.CreateVisibilitySkill(spec)
  assert(type(spec.name) == "string")

  local skill = VisibilitySkill:new(spec.name)
  fk.readStatusSpecToSkill(skill, spec)
  if spec.card_visible then skill.cardVisible = spec.card_visible end
  if spec.role_visible then skill.roleVisible = spec.role_visible end

  return skill
end
