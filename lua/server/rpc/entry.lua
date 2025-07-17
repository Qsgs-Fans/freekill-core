-- 通过lua lua/server/rpc/entry.lua直接启动rpc进程
-- 关于rpc的说明详见README

-- 在加载freekill.lua之前，必须先做好所有准备，模拟出类似swig的环境
local os = os
local io = io

package.path = package.path .. "./?.lua;./?/init.lua;./lua/lib/?.lua;./lua/?.lua;./lua/?/init.lua"
fk = require("server.rpc.fk")

-- 加载新月杀相关内容
dofile "lua/freekill.lua"
dofile "lua/server/scheduler.lua"

local mainLoop = function()
end

print "Hello, world"
