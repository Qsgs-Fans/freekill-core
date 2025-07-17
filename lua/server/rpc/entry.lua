-- 通过lua lua/server/rpc/entry.lua直接启动rpc进程
-- 关于rpc的说明详见README

-- 在加载freekill.lua之前，必须先做好所有准备，模拟出类似swig的环境
local os = os
local io = io

package.path = package.path .. "./?.lua;./?/init.lua;./lua/lib/?.lua;./lua/?.lua;./lua/?/init.lua"
fk = require "server.rpc.fk"
local jsonrpc = require "server.rpc.jsonrpc"

-- 加载新月杀相关内容并ban掉两个吃stdin的
dofile "lua/freekill.lua"
dofile "lua/server/scheduler.lua"

---@diagnostic disable-next-line lowercase-global
dbg = Util.DummyFunc
debug.debug = Util.DummyFunc

---@param packet JsonRpcPacket
local tryHandlePacket = function(packet)
  print(packet)
end

local mainLoop = function()
  InitScheduler {
    getRoom = function(_, id)
      return jsonrpc.callAndWait("getRoom", { id })
    end,
  }
  jsonrpc.call("hello", { "world" })

  while true do
    local msg = jsonrpc.read()
    if msg == nil then
      -- EOF
      break
    end

    local packet = jsonrpc.parse(msg)
    if packet == nil then
      goto continue
    end

    -- 先假设我发过去的request全都是阻塞式读取，不让room挂起
    -- 那这个循环其实只会接收到request

    if jsonrpc.packetType(packet) == "request" then
      if packet.method == "exit" then
        break
      end
      tryHandlePacket(packet)
    end

    ::continue::
  end
end

-- 参考文献：http://lua-users.org/lists/lua-l/2021-12/msg00023.html
-- if __name__ == '__main__':
if not ... then
  mainLoop()
end
