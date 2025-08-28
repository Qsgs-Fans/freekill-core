--- 各种Room的第二基类 提供最基本的与Cpp交互 和scheduler协作运行的设施与方法
---@class RoomMixin
---@field public id integer @ 房间的id
---@field public room fk.Room @ C++层面的Room类实例，别管他就是了，用不着
---@field public main_co any @ 本房间的主协程
---@field public game_started boolean @ 游戏是否已经开始
---@field public game_finished boolean @ 游戏是否已经结束
---@field public logic GameLogic @ 这个房间使用的游戏逻辑，可能根据游戏模式而变动
---@field public last_request Request @ 上一次完成的request
---@field public _test_disable_delay boolean? 测试专用 会禁用delay和烧条
local RoomMixin = {}

---@param _room fk.Room
function RoomMixin:initRoomMixin(_room)
  self.room = _room
  self.id = _room:getId()

  self.game_started = false
  self.game_finished = false

  -- doNotify过载保护，每次获得控制权时置为0
  -- 若在yield之前执行了max次doNotify则强制让出
  self.notify_count = 0
  self.notify_max = 500

  self.timeout = _room:getTimeout()
  self.settings = cbor.decode(self.room:settings())
end

-- 供调度器使用的函数。能让房间开始运行/从挂起状态恢复。
---@param reason string?
function RoomMixin:resume(reason)
  -- 如果还没运行的话就先创建自己的主协程
  if not self.main_co then
    self.main_co = coroutine.create(function()
      self:run()
    end)
  end

  local ret, err_msg, rest_time = true, true, nil
  local main_co = self.main_co

  if self:checkNoHuman() then
    goto GAME_OVER
  end

  if not self.game_finished then
    self.notify_count = 0
    ret, err_msg, rest_time = coroutine.resume(main_co, reason)

    -- handle error
    if ret == false then
      fk.qCritical(err_msg .. "\n" .. debug.traceback(main_co))
      goto GAME_OVER
    end

    if rest_time == "over" then
      goto GAME_OVER
    end

    return false, rest_time
  end

  ::GAME_OVER::
  self:gameOver("")
  -- coroutine.close(main_co)
  -- self.main_co = nil
  return true
end

function RoomMixin:checkNoHuman(chkOnly)
  if #self.players == 0 then return end

  for _, p in ipairs(self.players) do
    -- TODO: trust
    if p.serverplayer:getState() == fk.Player_Online then
      return
    end
  end

  if not chkOnly then
    self:gameOver("")
  end
  return true
end


--- 正式在这个房间中开始游戏。
---
--- 当这个函数返回之后，整个Room线程也宣告结束。
---@return nil
function RoomMixin:run()
  self.start_time = os.time()
  for _, p in fk.qlist(self.room:getPlayers()) do
    local player = ServerPlayer:new(p)
    player.room = self
    table.insert(self.players, player)
  end

  local mode = Fk.game_modes[self.settings.gameMode]
  local logic = (mode.logic and mode.logic() or GameLogic):new(self)
  self.logic = logic
  if mode.rule then self:addSkill(mode.rule) end
  logic:start()
end

--- 向多名玩家广播一条消息。
---@param command string @ 发出这条消息的消息类型
---@param jsonData any @ 消息的数据，一般是JSON字符串，也可以是普通字符串，取决于client怎么处理了
---@param players? ServerPlayer[] @ 要告知的玩家列表，默认为所有人
function RoomMixin:doBroadcastNotify(command, jsonData, players)
  players = players or self.players
  for _, p in ipairs(players) do
    p:doNotify(command, jsonData)
  end
end

--- 延迟一段时间。
---@param ms integer @ 要延迟的毫秒数
function RoomMixin:delay(ms)
  self.room:delay(math.ceil(ms))
  if self._test_disable_delay then return end
  coroutine.yield("__handleRequest", ms)
end

--- 将触发技或状态技添加到房间
---@param skill Skill|string
function RoomMixin:addSkill(skill)
  if type(skill) == "string" then
    skill = Fk.skills[skill]
  end
  if skill == nil then return end
  if skill:isInstanceOf(StatusSkill) then
    self.status_skills[skill.class] = self.status_skills[skill.class] or {}
    table.insertIfNeed(self.status_skills[skill.class], skill)
    -- add status_skill to cilent room
    self:doBroadcastNotify("AddStatusSkill", { skill.name })
  elseif skill:isInstanceOf(TriggerSkill) then
    ---@cast skill TriggerSkill
    self.logic:addTriggerSkill(skill)
  end
  for _, s in ipairs(skill.related_skills) do
    self:addSkill(s)
  end
end

--- 检查房间是否已经被加入了触发技或状态技
---@param skill Skill|string
---@return boolean
function RoomMixin:hasSkill(skill)
  if type(skill) == "string" then
    skill = Fk.skills[skill]
  end
  if skill == nil then return false end
  if skill:isInstanceOf(StatusSkill) then
    if type(self.status_skills[skill.class]) == "table" then
      return table.contains(self.status_skills[skill.class], skill)
    end
  elseif skill:isInstanceOf(TriggerSkill) then
    ---@cast skill TriggerSkill
    local event = skill.event
    if type(self.logic.skill_table[event]) == "table" then
      return table.contains(self.logic.skill_table[event], skill)
    end
  end
  return false
end

-- TODO gameOver至少得拆出协程相关

return RoomMixin
