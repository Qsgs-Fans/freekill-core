-- SPDX-License-Identifier: GPL-3.0-or-later
-- 暂且用来当client.lua用了，别在意

---@meta

---@class fk.QmlBackend
local FQmlBackend = {}

---@param path string
function FQmlBackend.cd(path)
end

---@param dir string
---@return string[]
function FQmlBackend.ls(dir)
end

---@return string
function FQmlBackend.pwd()
end

---@param file string
---@return boolean
function FQmlBackend.exists(file)
end

---@param file string
---@return boolean
function FQmlBackend.isDir(file)
end

-- External instance of QmlBackend
fk.Backend = FQmlBackend

-- Static method references
fk.QmlBackend_cd = FQmlBackend.cd
fk.QmlBackend_ls = FQmlBackend.ls
fk.QmlBackend_pwd = FQmlBackend.pwd
fk.QmlBackend_exists = FQmlBackend.exists
fk.QmlBackend_isDir = FQmlBackend.isDir

---@class fk.Client
local FClient = {}

---@param pubkey string
function FClient:sendSetupPacket(pubkey)
end

---@param server_time integer
function FClient:setupServerLag(server_time)
end

---@param command string
---@param json_data string
function FClient:replyToServer(command, json_data)
end

---@param command string
---@param json_data string
function FClient:notifyServer(command, json_data)
end

---@param id int
---@param name string
---@param avatar string
---@return fk.ClientPlayer
function FClient:addPlayer(id, name, avatar)
end

---@param id int
function FClient:removePlayer(id)
end

---@return fk.ClientPlayer
function FClient:getSelf()
end

---@param id int
function FClient:changeSelf(id)
end

---@param json string
---@param fname string
function FClient:saveRecord(json, fname)
end

---@param mode string
---@param general string
---@param deputy string
---@param role string
---@param result int
---@param replay string
---@param room_data string
---@param record string
function FClient:saveGameData(mode, general, deputy, role, result, replay, room_data, record)
end

---@param command string
---@param jsonData any
function FClient:notifyUI(command, jsonData)
end

function FClient:installMyAESKey() end
