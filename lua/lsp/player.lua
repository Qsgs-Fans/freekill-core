-- SPDX-License-Identifier: GPL-3.0-or-later

---@meta

---@class fk.Player
local FPlayer = {}

---@return integer
function FPlayer:getId()
end

---@param id integer
function FPlayer:setId(id)
end

---@return string
function FPlayer:getScreenName()
end

---@param name string
function FPlayer:setScreenName(name)
end

---@return string
function FPlayer:getAvatar()
end

---@param avatar string
function FPlayer:setAvatar(avatar)
end

---@return integer
function FPlayer:getTotalGameTime()
end

---@param toAdd integer
function FPlayer:addTotalGameTime(toAdd)
end

---@return integer
function FPlayer:getState()
end

---@param state integer
function FPlayer:setState(state)
end

---@return integer[]
function FPlayer:getGameData()
end

---@param total integer
---@param win integer
---@param run integer
function FPlayer:setGameData(total, win, run)
end

---@return boolean
function FPlayer:isDied()
end

---@param died boolean
function FPlayer:setDied(died)
end

-- Enum definition
fk.Player_Invalid = 0
fk.Player_Online = 1
fk.Player_Trust = 2
fk.Player_Run = 3
fk.Player_Leave = 4
fk.Player_Robot = 5
fk.Player_Offline = 6

---@class fk.ClientPlayer : fk.Player
local FClientPlayer = {}
