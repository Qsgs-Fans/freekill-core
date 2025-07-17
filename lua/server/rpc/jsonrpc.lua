-- 手搓jsonrpc协议的一小部分

local json = require 'json'
local io = io

local _reqId = 0

---@param method string
---@param params? table<string, any> | any[]
local request = function(method, params)
  _reqId = _reqId + 1
  return json.encode {
    jsonrpc = "2.0",
    method = method,
    params = params,
    id = _reqId,
  }
end

---@param result any
---@param id integer
local reply = function(result, id)
  return json.encode {
    jsonrpc = "2.0",
    result = result,
    id = id,
  }
end

---@param method string
---@param params? table<string, any> | any[]
local notify = function(method, params)
  return json.encode {
    jsonrpc = "2.0",
    method = method,
    params = params,
  }
end

---@class JsonRpcPacket
---@field jsonrpc "2.0"
---@field method? string
---@field params? table<string, any> | any[]
---@field id? integer
---@field result? any

--- 返回jsonrpc包，或者nil与error字符串
---@param str string
---@return JsonRpcPacket?, string?
local parse = function(str)
  local ok, obj = pcall(json.decode, str)
  if not ok then
    return nil, "rpc: json parse err"
  end
  setmetatable(obj, { __tostring = json.encode })

  if obj.jsonrpc ~= "2.0" then
    return nil, "rpc: not a jsonrpc packet"
  end

  -- 只要有id就合法 起码是reply包
  if type(obj.id) == "number" then
    return obj, nil
  end

  -- 剩下就是notify包
  if type(obj.method) == "string" then
    return obj, nil
  end

  -- 懒得判了
  return nil, "rpc: not a jsonrpc packet"
end

---@param obj JsonRpcPacket
---@return "request" | "notify" | "reply"
local packetType = function(obj)
  if obj.id == nil then
    return "notify"
  end

  if type(obj.method) == "string" then
    return "request"
  end

  return "reply"
end

local _print = print

---@param data string
local function write(data)
  _print(data)
end

---@type string[]
local _buffer = {}
local _waitingRequestId = -1
local _eof = false

---@return string?
local function read()
  if #_buffer > 0 then
    local ret = table.remove(_buffer, #_buffer)
    return ret
  end

  if _eof then return nil end

  local ret = io.read()
  if ret == nil then _eof = true end
  return ret
end

---@return nil
local function call(method, params)
  write(notify(method, params))
end

---@return any
local function callAndWait(method, params)
  write(request(method, params))
  local current = coroutine.running()
  if coroutine.isyieldable(current) then
    -- TODO: 挂起，甚至要记录roomId和reqId
    -- TODO: 还好lua是单线程，不用担心_reqId改变，赞美吧
  else
    _waitingRequestId = _reqId
    while true do
      local msg = io.read()
      if msg == nil then
        _eof = true
        break
      end

      local obj = parse(msg)
      if obj then
        if packetType(obj) == "reply" and obj.id == _waitingRequestId then
          return obj.result
        else
          table.insert(_buffer, 1, msg)
        end
      end
    end
  end
end

---@class jsonrpc
local M = {}
M.request = request
M.reply = reply
M.notify = notify
M.parse = parse
M.packetType = packetType

M.write = write
M.read = read

M.call = call
M.callAndWait = callAndWait

return M
