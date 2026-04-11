-- SPDX-License-Identifier: GPL-3.0-or-later

--- Skill用来描述一个技能。
---
---@class Skill : Object
---@field public name string @ 技能名
---@field public trueName string @ 技能真名
---@field public package Package @ 技能所属的包
---@field public frequency? SkillTag @ 技能标签，如compulsory（锁定技）、limited（限定技）。（deprecated，请改为向skeleton添加tag）
---@field public visible boolean @ 技能是否会显示在游戏中
---@field public mute boolean @ 决定是否关闭技能配音
---@field public no_indicate boolean @ 决定是否关闭技能指示线
---@field public global boolean @ 决定是否是全局技能
---@field public anim_type string|AnimationType @ 技能类型定义
---@field public related_skills Skill[] @ 和本技能相关的其他技能，有时候一个技能实际上是通过好几个技能拼接而实现的。
---@field public attached_equip string @ 属于什么装备的技能？
---@field public relate_to_place string| "m" | "d" @ 主将技("m")/副将技("d")
---@field public times integer @ 技能剩余次数，负数不显示
---@field public attached_skill_name string @ 给其他角色添加技能的名称
---@field public main_skill Skill @ 仅用作添加技能和提示信息
---@field public is_delay_effect boolean @ 是否是延时效果
---@field public audio_index integer|table @ 发动此技能时播放的语音序号，可为int或int表
---@field public cardSkill boolean @ 是否为卡牌效果对应的技能（仅用于ActiveSkill）
---@field public skeleton SkillSkeleton @ 获取技能骨架
local Skill = class("Skill")


---@alias SkillTag string

Skill.NotFrequent = "NotFrequent" -- 技能frequency的默认值
Skill.Lord = "Lord" -- 主公技
Skill.Compulsory = "Compulsory" -- 锁定技
Skill.Limited = "Limited" -- 限定技
Skill.Wake = "Wake" -- 觉醒技
Skill.Switch = "Switch" -- 转换技
Skill.Quest = "Quest" -- 使命技
Skill.Permanent = "Permanent" -- 持恒技
Skill.MainPlace = "MainPlace" -- 主将技
Skill.DeputyPlace = "DeputyPlace" -- 副将技
Skill.Hidden = "Hidden" -- 隐匿技
Skill.AttachedKingdom = "AttachedKingdom" --势力技
Skill.Charge = "Charge" --蓄力技
Skill.Family = "Family" --宗族技
Skill.Combo = "Combo" --连招技
Skill.Rhyme = "Rhyme" --韵律技
Skill.Force = "Force" --奋武技
Skill.Spirited = "Spirited" --昂扬技
Skill.Ambition = "Ambition" --移志技
Skill.GrowUp = "GrowUp" --成器技


--- 构造函数，不可随意调用。
---@param name string @ 技能名
function Skill:initialize(name, frequency)
  -- TODO: visible, lord, etc
  self.name = name
  -- skill's package is assigned when calling General:addSkill
  -- if you need skills that not belongs to any general (like 'jixi')
  -- then you should use general function addRelatedSkill to assign them
  self.package = { extensionName = "standard" }
  self.visible = true
  self.mute = false
  self.no_indicate = false
  self.anim_type = ""
  self.related_skills = {}
  self._extra_data = {}
  self.is_delay_effect = false

  self.attached_skill_name = nil

  --TODO: 以下是应当移到skeleton的参数
  local name_splited = self.name:split("__")
  self.trueName = name_splited[#name_splited]
  if string.sub(name, 1, 1) == "#" then
    self.visible = false
  end
  self.attached_equip = nil

  self.frequency = self.frequency or Skill.NotFrequent
end

function Skill:__index(k)
  if k == "cost_data" then
    return Fk:currentRoom().skill_costs[self.name]
  else
    return self._extra_data[k]
  end
end

function Skill:__newindex(k, v)
  if k == "cost_data" then
    Fk:currentRoom().skill_costs[self.name] = v
  else
    rawset(self, k, v)
  end
end

function Skill:__tostring()
  return "<Skill " .. self.name .. ">"
end

local CBOR_TAG_SKILL = 33004
function Skill:__tocbor()
  return cbor.encode(cbor.tagged(CBOR_TAG_SKILL, self.name))
end
function Skill:__touistring()
  return Fk:translate(self.name)
end
function Skill:__toqml()
  return {
    uri = "Fk.Components.LunarLTK",
    name = "SkillButton",

    prop = {
      type = "notactive",
      orig = self.name,
      skill = Fk:translate(self.name),
    },
  }
end
cbor.tagged_decoders[CBOR_TAG_SKILL] = function(v)
  return Fk.skills[v]
end

--- 为一个技能增加相关技能。
---@param skill Skill @ 技能
function Skill:addRelatedSkill(skill)
  table.insert(self.related_skills, skill)
  Fk.related_skills[self.name] = Fk.related_skills[self.name] or {}
  table.insert(Fk.related_skills[self.name], skill)
end

--- 确认本技能是否为装备技能。
---@param player? Player @ 技能拥有者
---@return boolean
function Skill:isEquipmentSkill(player)
  if player then
    local filterSkills = Fk:currentRoom().status_skills[FilterSkill] or Util.DummyTable
    for _, filter in ipairs(filterSkills) do
      local result = filter:equipSkillFilter(self, player)
      if result then
        return true
      end
    end
  end

  return type(self:getSkeleton().attached_equip) == "string"
end

--- 判断技能是不是对于某玩家而言失效了。
---
--- 判断技能是不是对于某角色而言失效了。
---
--- 它影响的是hasSkill，但也可以单独拿出来判断。
---@param player Player @ 角色
---@return boolean
function Skill:isEffectable(player)
  
  if self.cardSkill then return true --self:hasTag(Skill.Permanent)下移；注意技能各（①②③④⑤…）组分间的标签原则上可不尽相同，故不判断MainSk:hasTag(Skill.Permanent)
  end

  local Owners, MainSk, NVAE = {}, self, table.every(player.virtual_equips, function(e) return ((e.name ~= self.attached_equip) or (#e.subcards > 0)) end)
  for _, p in ipairs(Fk:currentRoom().alive_players) do
    for _, sk in ipairs(p:getAllSkills()) do
      if (p.id ~= player.id) and sk.attached_skill_name and string.find(sk.attached_skill_name, self.name) then Owners[1] = Owners[1] or sk:isEffectable(p)
      end
    end
  end
  if (#Owners > 0) and not Owners[1] then return false
  end
  for _, sk in ipairs(player:getAllSkills()) do
    if table.contains({table.unpack(sk.related_skills)}, self) then MainSk = sk
    end
  end
  local recheck_skills, room, NDR = {}, Fk:currentRoom(), table.every(player.derivative_skills, function(tb) return not table.contains(tb, MainSk) end)

  local nullifySkills = room.status_skills[InvaliditySkill] or Util.DummyTable---@type InvaliditySkill[]
  for _, nullifySkill in ipairs(nullifySkills) do
    if nullifySkill.recheck_invalidity then
      if not room.invalidity_rechecking then
        table.insert(recheck_skills, nullifySkill)
      end
    elseif nullifySkill:getInvalidity(player, MainSk) and not self:hasTag(Skill.Permanent) then --elseif nullifySkill:getInvalidity(player, self) then
      return false
    end
  end

  if #recheck_skills > 0 then
    room.invalidity_rechecking = true
    local ret = table.find(recheck_skills, function(s) return s:getInvalidity(player, MainSk) end) --function(s) return s:getInvalidity(player, self) end
    room.invalidity_rechecking = false
    if ret and not self:hasTag(Skill.Permanent) then return false end --if ret then return false end
  end

  for mark, value in pairs(player.mark) do -- 耦合 MarkEnum.InvalidSkills ！但仍不好处理其他角色技能（爱省字数）赋予的与装备技能“同名”（name相同）的（时段内）派生技
    if (mark == MarkEnum.InvalidSkills) and value[MainSk.name] then --新月允许角色同一子类别多重虚拟装备甚至与现有“实”装备同名(却没有特殊坐骑牌子类别和特殊坐骑区)
      if NDR and NVAE and table.find(value[MainSk.name], function(s) return (s == 'excludes') end) then return false --if value[self.name] then return false
      elseif (NDR and NVAE) or table.find(value[MainSk.name], function(s) return (s ~= 'excludes') end) then return self:hasTag(Skill.Permanent)
      end --'excludes'作为source_skill用于飞刀判定，故无视持恒技，但排除“同名”派生技及视为装备（涉及计数的状态类技能请这类设计者自行解决，考虑武将技能挂载StatusSkill）
    elseif mark:startsWith(MarkEnum.InvalidSkills .. "-") and value[MainSk.name] then --and value[self.name] then
      for _, suffix in ipairs(MarkEnum.TempMarkSuffix) do
        if mark:find(suffix, 1, true) then return self:hasTag(Skill.Permanent) --then return false
        end
      end
    end
  end

  return true
end

--判断技能是否为角色技能
---@param player? Player @ 技能拥有者
---@param includeModeSkill? boolean @ 是否包含模式技
---@return boolean
function Skill:isPlayerSkill(player, includeModeSkill)
  local skel = self:getSkeleton()
  if skel == nil then return false end
  return
    not (
      self.cardSkill or
      self:isEquipmentSkill(player) or
      self.name:endsWith("&") or
      (not includeModeSkill and skel.mode_skill)
    )
end

---@return integer
function Skill:getTimes(player)
  local ret = self.times
  if not ret then
    return -1
  elseif type(ret) == "function" then
    ret = ret(self, player)
  end
  return ret
end

---@param player Player
---@param lang? string
---@return string?
function Skill:getDynamicDescription(player, lang)
  if self:hasTag(Skill.Switch) then
    local skill_name = self:getSkeleton().name
    local switchState = player:getSwitchSkillState(skill_name)
    local descKey = ":" .. skill_name .. (switchState == fk.SwitchYang and "_yang" or "_yin")
    local translation = Fk:translate(descKey, lang)
    if translation ~= descKey then
      return translation
    end
  end

  return nil
end

--- 找到效果的技能骨架。可能为nil
---@return SkillSkeleton
function Skill:getSkeleton()
  return self.skeleton
end

--- 判断技能是否有某标签
---@param tag SkillTag  待判断的标签
---@param compulsory_expand boolean?  是否“拓展”锁定技和限定技标签的含义，包括觉醒技。默认是
---@return boolean
function Skill:hasTag(tag, compulsory_expand)
  local expand = (compulsory_expand == nil or compulsory_expand)
  local skel = self:getSkeleton()
  if not skel then return false end
  if expand then
    if tag == Skill.Compulsory then
      return table.contains(skel.tags, Skill.Compulsory) or table.contains(skel.tags, Skill.Wake)
    elseif tag == Skill.Limited then
      return table.contains(skel.tags, Skill.Limited) or table.contains(skel.tags, Skill.Wake)
    end
  end
  return table.contains(skel.tags, tag)
end

return Skill
