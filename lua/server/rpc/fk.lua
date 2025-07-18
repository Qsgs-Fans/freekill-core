-- fk.lua: 目标是干掉swig 实现新月杀swig提供的所有功能
-- 里面会有一系列非常像test中写过的代码。。
--
-- 带 --[[ mut ]] 注释的是模仿rust的let mut写法，意思就是这个是可变的
-- 因为平时lua依赖方法直接读取C++对象的值，现在没有C++
-- 具体的变化全都要通过rpc传递

local os = os

-- 下面俩是系统上要安装的 freekill不提供

-- 需安装lua-socket包
local socket = require "socket"
-- 需安装lua-filesystem包
local fs = require "lfs"
-- 需手动编译安装，详见src/swig/qrandom文件夹
local qrandom = require 'freekill-qrandomgen'

local jsonrpc = require "server.rpc.jsonrpc"
local stdio = require "server.rpc.stdio"
local dispatchers = require "server.rpc.dispatchers"

local notifyRpc = function(method, params)
  local req = jsonrpc.notification(method, params)
  stdio.send(json.encode(req))
end

local callRpc = function(method, params)
  local req = jsonrpc.request(method, params)
  local id = req.id
  stdio.send(json.encode(req))

  while true do
    local msg = stdio.receive()
    if msg == nil then break end

    local ok, packet = pcall(json.decode, msg)
    if not ok then
      stdio.send(json.encode(jsonrpc.response_error(req, 'parse_error', packet)))
      goto continue
    end

    if packet.jsonrpc == "2.0" and packet.id == id and packet.method == nil then
      ---@cast packet JsonRpcPacket
      return packet.result, packet.error
    else
      local res = jsonrpc.server_response(dispatchers, packet)
      if res then
        stdio.send(json.encode(res))
      end
    end

    ::continue::
  end
end

local fk = {}

-- swig/freekill.i
-- 服务端不需要fk_ver

---@return string
function fk.GetDisabledPacks()
  return os.getenv("FK_DISABLED_PACKS") or "[]"
end

-- swig/qt.i

fk.QList = function(arr)
  return setmetatable(arr, {
    __index = {
      at = function(self, i)
        return self[i+1]
      end,
      length = function(self)
        return #self
      end,
    }
  })
end

--- 注：socket只能精确到0.1毫秒
---@return integer
function fk.GetMicroSecond()
  return socket.gettime() * 1000 * 1000
end

fk.QRandomGenerator = qrandom.new

function fk.qDebug(fmt, ...)
  notifyRpc("qDebug", { string.format(fmt, ...) })
end

function fk.qInfo(fmt, ...)
  notifyRpc("qInfo", { string.format(fmt, ...) })
end

function fk.qWarning(fmt, ...)
  notifyRpc("qWarning", { string.format(fmt, ...) })
end

function fk.qCritical(fmt, ...)
  notifyRpc("qCritical", { string.format(fmt, ...) })
end

-- 连print也要？！

function print(...)
  local params = {}
  local args = { ... }
  local n = select("#", ...)
  for i = 1, n do
    table.insert(params, tostring(args[i]))
  end
  notifyRpc("print", params)
end

-- swig/player.i
fk.Player_Invalid = 0
fk.Player_Online = 1
fk.Player_Trust = 2
fk.Player_Run = 3
fk.Player_Leave = 4
fk.Player_Robot = 5
fk.Player_Offline = 6

-- 还好服务端用不到setter.
---@type metatable
local _Player_MT = {
  __index = {
    getId = function(t) return t.id end,
    getScreenName = function(t) return t.screenName end,
    getAvatar = function(t) return t.avatar end,
    getTotalGameTime = function(t) return t.totalGameTime end,
    getGameData = function(t) return t.gameData end,

    -- RPC场景下died及其关联的逃跑惩罚判断应该值得思考
    isDied = function(t) return t.died end,
    setDied = function(t, v) t.died = v end,
  },
}

-- swig/client.i

---@type fun(path: string)
fk.QmlBackend_cd = fs.chdir

---@type fun(path: string): string[]
fk.QmlBackend_ls = function(path)
  local ret = {}
  for entry in fs.dir(path) do
    if entry ~= "." and entry ~= ".." then
      table.insert(ret, entry)
    end
  end
  return ret
end

---@type fun(): string
fk.QmlBackend_pwd = fs.currentdir

---@type fun(path: string): boolean
fk.QmlBackend_exists = function(path)
  return fs.attributes(path) ~= nil
end

---@type fun(path: string): boolean
fk.QmlBackend_isDir = function(path)
  return fs.attributes(path) and fs.attributes(path).mode == "directory"
end

-- swig/server.i

---@param command string
---@param jsondata string
---@param timeout integer
---@param timestamp? integer
local _ServerPlayer_doRequest = function(self, command, jsondata, timeout, timestamp)
  callRpc("ServerPlayer_doRequest", { self.connId, command, tostring(jsondata), timeout, timestamp })
end

local _ServerPlayer_waitForReply = function(self, timeout)
  local ret, err = callRpc("ServerPlayer_waitForReply", { self.connId, timeout })
  if err ~= nil then
    return "__cancel"
  end
  return ret
end

local _ServerPlayer_doNotify = function(self, command, jsondata)
  callRpc("ServerPlayer_doNotify", { self.connId, command, tostring(jsondata) })
end

local _ServerPlayer_getState = function(self)
  local ret, err = callRpc("ServerPlayer_getState", { self.connId })
  if err ~= nil or ret == fk.Player_Run then
    return fk.Player_Robot
  end
  return ret
end

local _ServerPlayer_thinking = function(self)
  return callRpc("ServerPlayer_thinking", { self.connId })
end

local _ServerPlayer_setThinking = function(self, think)
  callRpc("ServerPlayer_setThinking", { self.connId, think })
end

-- ServerPlayer必须要绑定到具体socket上，uid完全不够用

---@type metatable
local _ServerPlayer_MT = {
  __index = setmetatable({
    doRequest = _ServerPlayer_doRequest,
    waitForReply = _ServerPlayer_waitForReply,
    doNotify = _ServerPlayer_doNotify,

    getState = _ServerPlayer_getState,

    thinking = _ServerPlayer_thinking,
    setThinking = _ServerPlayer_setThinking,

    -- TODO
    emitKick = function() end,
  }, _Player_MT),
}

fk.ServerPlayer = function(t)
  return setmetatable({
    connId = t.connId,

    id = t.id,
    screenName = t.screenName,
    avatar = t.avatar,
    totalGameTime = t.totalGameTime,

    gameData = fk.QList(t.gameData),

    -- TODO: 这两个应该是和C++代码完全绑定的，需要考虑
    died = false,
  }, _ServerPlayer_MT)
end

local _Room_getOwner = function(self)
  local players = self.players
  local ownerId = self.ownerId

  for _, p in ipairs(players) do
    if p.id == ownerId then
      return p
    end
  end
end

local _Room_hasObserver = function(self, player)
  for _, p in ipairs(self.observers) do
    if p.id == player.id then
      return true
    end
  end
  return false
end

local _Room_delay = function(self, ms)
  callRpc("Room_delay", { self.id, ms })
end

local _Room_updatePlayerWinRate = function(self, id, mode, role, result)
  callRpc("Room_updatePlayerWinRate", { self.id, id, mode, role, result })
end

local _Room_updateGeneralWinRate = function(self, general, mode, role, result)
  callRpc("Room_updateGeneralWinRate", { self.id, general, mode, role, result })
end

local _Room_gameOver = function(self)
  callRpc("Room_gameOver", { self.id })
end

local _Room_setRequestTimer = function(self, ms)
  callRpc("Room_setRequestTimer", { self.id, ms })
end

local _Room_destroyRequestTimer = function(self)
  callRpc("Room_destroyRequestTimer", { self.id })
end

---@type metatable
local _Room_MT = {
  __index = {
    getId = function(t) return t.id end,
    getPlayers = function(t) return t.players end,
    getOwner = _Room_getOwner,
    getObservers = function(t) return t.observers end,
    hasObserver = _Room_hasObserver,
    getTimeout = function(t) return t.timeout end,
    delay = _Room_delay,

    updatePlayerWinRate = _Room_updatePlayerWinRate,
    updateGeneralWinRate = _Room_updateGeneralWinRate,
    gameOver = _Room_gameOver,
    setRequestTimer = _Room_setRequestTimer,
    destroyRequestTimer = _Room_destroyRequestTimer,

    -- 这两个引用计数啥的我估计没啥用了，之后看看怎么完全剔除
    increaseRefCount = function() end,
    decreaseRefCount = function() end,

    settings = function(t) return t._settings end,
  }
}

fk.Room = function(t)
  local players = {}
  for _, obj in ipairs(t.players) do
    table.insert(players, fk.ServerPlayer(obj))
  end

  return setmetatable({
    id = t.id,
    players = fk.QList(players),
    ownerId = t.ownerId,
    --[[ mut ]] observers = fk.QList({}),
    timeout = t.timeout,

    _settings = t.settings,
  }, _Room_MT)
end

local _RoomThread_getRoom = function(_, id)
  local roomData = callRpc("RoomThread_getRoom", { id })
  return fk.Room(roomData)
end

fk.RoomThread = function()
  return {
    getRoom = _RoomThread_getRoom,
  }
end

return fk
