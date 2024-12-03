-- SPDX-License-Identifier: GPL-3.0-or-later

---@meta

---@class fk.SPlayerList
SPlayerList = {}

---@return integer length
function SPlayerList:length()end

---@param index integer
---@return fk.ServerPlayer
function SPlayerList:at(index)end

--- * get microsecond from Epoch
---@return integer microsecond
function fk:GetMicroSecond()end

-- Logging functions
function fk.qDebug(msg, ...)
end

function fk.qInfo(msg, ...)
end

function fk.qWarning(msg, ...)
end

function fk.qCritical(msg, ...)
end

---@class fk.QJsonDocument
local FQJsonDocument = {}

---@param json string
---@return fk.QJsonDocument
function fk.QJsonDocument_fromJson(json)
end

---@return fk.QJsonDocument
function fk.QJsonDocument_fromVariant(variant)
end

---@return string
function FQJsonDocument:toJson(format)
end

---@return any
function FQJsonDocument:toVariant()
end

---@class fk.QRandomGenerator
local FQRandomGenerator = {}

---@param seed integer
---@return fk.QRandomGenerator
function fk.QRandomGenerator(seed)
end

---@return integer
function FQRandomGenerator:generate()
end

---@param lowest integer
---@param highest integer
---@return integer
function FQRandomGenerator:bounded(lowest, highest)
end

---@param low integer
---@param high integer
---@return number
function FQRandomGenerator:random(low, high) end

fk.FK_VER = '0.0.0'
