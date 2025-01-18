--- 将新数据改为牢数据
function MoveCardsData:toLegacy()
  local ret = table.simpleClone(rawget(self, "_data"))
  for _, k in ipairs({"from", "to", "proposer"}) do
    local v = ret[k]
    if v then
      ret[k] = v.id
    end
  end

  if ret.visiblePlayers then
    local new_v = {}
    for _, p in ipairs(ret.visiblePlayers) do
      table.insert(new_v, p.id)
    end
    ret.visiblePlayers = new_v
  end

  return ret
end

--- 将牢数据改为新数据
function MoveCardsData:loadLegacy(data)
  for k, v in pairs(data) do
    if table.contains({"from", "to", "proposer"}, k) then
      self[k] = Fk:currentRoom():getPlayerById(v)
    elseif table.contains({"visiblePlayers"}, k) then
      if type(v) == "number" then
        v = {v}
      end
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
