local os = os

-- 下面俩是系统上要安装的 freekill不提供

-- 需安装lua-socket包
local socket = require "socket"
-- 需安装lua-filesystem包
local fs = require "lfs"

local jsonrpc = require "server.rpc.jsonrpc"

local fk = {}

-- swig/freekill.i
-- 服务端不需要fk_ver

---@return string
function fk.GetDisabledPacks()
  return os.getenv("FK_DISABLED_PACKS") or "[]"
end

-- swig/qt.i

--- 注：socket只能精确到0.1毫秒
---@return integer
function fk.GetMicroSecond()
  return socket.gettime() * 1000 * 1000
end

-- TODO: QRandomGenerator

function fk.qDebug(fmt, ...)
  jsonrpc.write(jsonrpc.notify("qDebug", { string.format(fmt, ...) }))
end

function fk.qInfo(fmt, ...)
  jsonrpc.write(jsonrpc.notify("qInfo", { string.format(fmt, ...) }))
end

function fk.qWarning(fmt, ...)
  jsonrpc.write(jsonrpc.notify("qWarning", { string.format(fmt, ...) }))
end

function fk.qCritical(fmt, ...)
  jsonrpc.write(jsonrpc.notify("qCritical", { string.format(fmt, ...) }))
end

-- 连print也要？！

function print(...)
  jsonrpc.write(jsonrpc.notify("print", { ... }))
end

-- swig/player.i
fk.Player_Invalid = 0
fk.Player_Online = 1
fk.Player_Trust = 2
fk.Player_Run = 3
fk.Player_Leave = 4
fk.Player_Robot = 5
fk.Player_Offline = 6

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
  return fs.attributes(path).mode == "directory"
end

-- swig/server.i: 没有附加到fk上的内容

return fk
