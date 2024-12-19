-- SPDX-License-Identifier: GPL-3.0-or-later

-- 列出所有触发时机。
-- 关于每个时机的详情请从文档中检索。

---@alias Event integer

fk.NonTrigger = 1
fk.GamePrepared = 78
fk.GameFinished = 66
fk.AskForCardUse = 67
fk.AskForCardResponse = 68
fk.HandleAskForPlayCard = 97
fk.AfterAskForCardUse = 98
fk.AfterAskForCardResponse = 99
fk.AfterAskForNullification = 100
fk.NumOfEvents = 103
