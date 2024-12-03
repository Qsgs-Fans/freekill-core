-- SPDX-License-Identifier: GPL-3.0-or-later

---@diagnostic disable

---@class fk.Server
local FServer = {}
function FServer:beginTransaction() end
function FServer:endTransaction() end

---@class fk.Room
local FRoom = {}

---@return int
function FRoom:getId()
end

---@return fk.ServerPlayer[]
function FRoom:getPlayers()
end

---@return fk.ServerPlayer
function FRoom:getOwner()
end

---@return fk.ServerPlayer[]
function FRoom:getObservers()
end

---@param player fk.ServerPlayer
---@return boolean
function FRoom:hasObserver(player)
end

---@return int
function FRoom:getTimeout()
end

---@param ms int
function FRoom:delay(ms)
end

---@param id int
---@param mode string
---@param role string
---@param result int
function FRoom:updatePlayerWinRate(id, mode, role, result)
end

---@param general string
---@param mode string
---@param role string
---@param result int
function FRoom:updateGeneralWinRate(general, mode, role, result)
end

function FRoom:gameOver()
end

---@param ms int
function FRoom:setRequestTimer(ms)
end

function FRoom:destroyRequestTimer()
end

function FRoom:increaseRefCount()
end

function FRoom:decreaseRefCount()
end

---@return string
function FRoom:settings()
end

---@class fk.RoomThread
local FRoomThread = {}

---@param id int
---@return fk.Room
function FRoomThread:getRoom(id)
end

---@return boolean
function FRoomThread:isConsoleStart()
end

---@return boolean
function FRoomThread:isOutdated()
end

---@class fk.ServerPlayer : fk.Player
local FServerPlayer = {}

---@param command string
---@param json_data string
---@param timeout int
---@param timestamp long
function FServerPlayer:doRequest(command, json_data, timeout, timestamp)
end

---@param timeout int
---@return string
function FServerPlayer:waitForReply(timeout)
end

---@param command string
---@param json_data string
function FServerPlayer:doNotify(command, json_data)
end

---@return boolean
function FServerPlayer:thinking()
end

---@param t boolean
function FServerPlayer:setThinking(t)
end

---@return void
function FServerPlayer:emitKick()
    -- This method emits the kicked signal
end
