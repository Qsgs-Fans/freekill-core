--- 将新数据改为牢数据
function SkillEffectData:toLegacy()
  local ret = table.simpleClone(rawget(self, "_data"))
  if ret.from then
    ret.from = ret.from.id
  end

  if ret.tos then
    local new_v = {}
    for _, p in ipairs(ret.tos) do
      table.insert(new_v, p.id)
    end
    ret.tos = new_v
  end
  return ret
end

--- 将牢数据改为新数据
function SkillEffectData:loadLegacy(data)
  for k, v in pairs(data) do
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
