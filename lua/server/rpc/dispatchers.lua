-- RPC过程处理
-- 所有函数都是先返回一个布尔再返回真实值
-- 基本上都是三步走，验证参数 - pcall - 返回success与返回值

-- 不得不品的ping，便于测试
local ping = function()
  return true, "PONG"
end

-- 以下是目前多进程方案中真正用到过的

local resumeRoom = function(params)
  if type(params[1]) ~= "number" then
    return false, nil
  end

  local ok, ret = pcall(ResumeRoom, params[1], params[2])
  if not ok then return false, 'internal_error' end
  return true, ret
end

local handleRequest = function(params)
  if type(params[1]) ~= "string" then
    return false, nil
  end

  local ok, ret = pcall(HandleRequest, params[1])
  if not ok then return false, 'internal_error' end
  return true, ret
end

---@type table<string, fun(...): boolean, ...>
return {
  ping = ping,

  ResumeRoom = resumeRoom,
  HandleRequest = handleRequest,
}
