-- 手搓jsonrpc协议的一小部分

local json = require 'json'

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
---@field method string
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

  if obj.jsonrpc ~= "2.0" then
    return nil, "rpc: not a jsonrpc packet"
  end

  -- 懒得判了
  return obj, nil
end

---@param obj JsonRpcPacket
---@return "request" | "notify" | "reply"
local packet_type = function(obj)
  if obj.id == nil then
    return "notify"
  end

  if obj.result ~= nil then
    return "reply"
  end

  return "request"
end

local M = {}
M.request = request
M.reply = reply
M.notify = notify
M.parse = parse
M.packet_type = packet_type
return M
