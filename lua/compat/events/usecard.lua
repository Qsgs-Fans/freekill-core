--- 将新数据改为牢数据
function RespondCardData:toLegacy()
  local ret = table.simpleClone(rawget(self, "_data"))
  for _, k in ipairs({"from", "customFrom"}) do
    local v = ret[k]
    if v then
      ret[k] = v.id
    end
  end
  return ret
end

--- 将牢数据改为新数据
function RespondCardData:loadLegacy(data)
  for k, v in pairs(data) do
    if table.contains({"from", "customFrom"}, k) then
      self[k] = Fk:currentRoom():getPlayerById(v)
    else
      self[k] = v
    end
  end
end

--- 将新数据改为牢数据
function UseCardData:toLegacy()
  local ret = RespondCardData.toLegacy(self)

  for _, k in ipairs({"nullifiedTargets", "disresponsiveList"}) do
    local v = ret[k]
    if v then
      local new_v = {}
      for _, p in ipairs(v) do
        table.insert(new_v, p.id)
      end
      ret[k] = new_v
    end
  end

  if ret.damageDealt then
    local new_v = {}
    for sp, pv in pairs(ret.damageDealt) do
      new_v[sp.id] = pv
    end
    ret.damageDealt = new_v
  end

  return ret
end

--- 将牢数据改为新数据
function UseCardData:loadLegacy(data)
  for k, v in pairs(data) do
    if table.contains({"from", "customFrom"}, k) then
      self[k] = Fk:currentRoom():getPlayerById(v)
    elseif table.contains({"nullifiedTargets", "disresponsiveList"}, k) then
      local new_v = {}
      for _, pid in ipairs(v) do
        table.insert(new_v, Fk:currentRoom():getPlayerById(pid))
      end
      self[k] = new_v
    elseif table.contains({"damageDealt"}, k) then
      local new_v = {}
      for pid, pv in pairs(v) do
        new_v[Fk:currentRoom():getPlayerById(pid)] = pv
      end
      self[k] = new_v
    else
      self[k] = v
    end
  end
end

--- 将新数据改为牢数据
function CardEffectData:toLegacy()
  local ret = RespondCardData.toLegacy(self)

  if ret.to then
    ret.to = ret.to.id
  end

  for _, k in ipairs({"nullifiedTargets", "disresponsiveList", "unoffsetableList"}) do
    local v = ret[k]
    if v then
      local new_v = {}
      for _, p in ipairs(v) do
        table.insert(new_v, p.id)
      end
      ret[k] = new_v
    end
  end

  return ret
end

--- 将牢数据改为新数据
function CardEffectData:loadLegacy(data)
  for k, v in pairs(data) do
    if table.contains({"from", "to", "customFrom"}, k) then
      self[k] = Fk:currentRoom():getPlayerById(v)
    elseif table.contains({"nullifiedTargets", "disresponsiveList", "unoffsetableList"}, k) then
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
