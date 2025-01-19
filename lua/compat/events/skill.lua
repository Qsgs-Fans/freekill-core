--- 将新数据改为牢数据
function SkillEffectData:toLegacy()
  local ret = table.simpleClone(rawget(self, "_data"))
  if not ret.skill_data then return end
  if ret.skill_data.from then
    ret.skill_data.from = ret.skill_data.from.id
  end

  if ret.skill_data.tos then
    local new_v = {}
    for _, p in ipairs(ret.skill_data.tos) do
      table.insert(new_v, p.id)
    end
    ret.skill_data.tos = new_v
  end
  return ret
end

--- 将牢数据改为新数据
function SkillEffectData:loadLegacy(data)
  if not data.skill_data then return end
  for k, v in pairs(data.skill_data) do
    if table.contains({"from"}, k) then
      self[k] = Fk:currentRoom():getPlayerById(v)
    elseif table.contains({"tos"}, k) then
      local new_v = {}
      for _, pid in ipairs(v) do
        table.insert(new_v, Fk:currentRoom():getPlayerById(pid))
      end
      self[k] = new_v
    else
      self[k] = v
    end
  end
end
