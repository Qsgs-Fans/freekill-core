-- SPDX-License-Identifier: GPL-3.0-or-later

---@class GameEvent.SkillEffect : GameEvent
local SkillEffect = GameEvent:subclass("GameEvent.SkillEffect")
function SkillEffect:main()
  local effect_cb, player, skill, skill_data = table.unpack(self.data)
  local room = self.room
  local logic = room.logic
  local main_skill = skill.main_skill and skill.main_skill or skill
  skill_data = skill_data or Util.DummyTable
  local cost_data = skill_data.cost_data or Util.DummyTable

  if player and not skill.cardSkill then
    player:revealBySkillName(main_skill.name)

    local tos = skill_data.tos or {}
    local mute, no_indicate = skill.mute, skill.no_indicate
    if type(cost_data) == "table" then
      if cost_data.mute then mute = cost_data.mute end
      if cost_data.no_indicate then no_indicate = cost_data.no_indicate end
    end
    if not mute then
      if skill.attached_equip then
        local equip = Fk.all_card_types[skill.attached_equip]
        if equip then
          local pkgPath = "./packages/" .. equip.package.extensionName
          local soundName = pkgPath .. "/audio/card/" .. equip.name
          room:broadcastPlaySound(soundName)
          if not no_indicate and #tos > 0 then
            room:sendLog{
              type = "#InvokeSkillTo",
              from = player.id,
              arg = skill.name,
              to = tos,
            }
          else
            room:sendLog{
              type = "#InvokeSkill",
              from = player.id,
              arg = skill.name,
            }
          end
          room:setEmotion(player, pkgPath .. "/image/anim/" .. equip.name)
        end
      else
        player:broadcastSkillInvoke(skill.name)
        room:notifySkillInvoked(player, skill.name, nil, no_indicate and {} or tos)
      end
    end
    if not no_indicate then
      room:doIndicate(player.id, tos)
    end

    if skill:isSwitchSkill() then
      local switchSkillName = skill.switchSkillName
      room:setPlayerMark(
        player,
        MarkEnum.SwithSkillPreName .. switchSkillName,
        player:getSwitchSkillState(switchSkillName, true)
      )
    end

    player:addSkillUseHistory(main_skill.name)
  end

  local cost_data_bak = skill.cost_data
  logic:trigger(fk.SkillEffect, player, main_skill)
  skill.cost_data = cost_data_bak

  local ret = effect_cb and effect_cb() or false
  logic:trigger(fk.AfterSkillEffect, player, main_skill)
  return ret
end

return SkillEffect
