---@class ClientMixin : Base.AbstractRoom
---@field public client fk.Client
---@field public observing boolean 客户端是否在旁观
---@field public replaying boolean 客户端是否在重放
---@field public replaying_show boolean 重放时是否要看到全部牌
---@field public record any
---@field public callbacks { [string|integer]: fun(self, data) }
local ClientMixin = {}

function ClientMixin:initClientMixin(_client)
  self.client = _client
  self.recording = false
  self.callbacks = {}
  ------------------------
  self:addCallback("NetworkDelayTest", self.sendSetupPacket)
  self:addCallback("Setup", self.setup)
  self:addCallback("Heartbeat", self.heartbeat)

  self:addCallback("EnterRoom", self.enterRoom, true)
  self:addCallback("EnterLobby", self.quitRoom, true)
  self:addCallback("AddPlayer", self.addPlayer)
  self:addCallback("RemovePlayer", self.removePlayer)
  self:addCallback("AddObserver", self.addObserver)
  self:addCallback("RemoveObserver", self.removeObserver)
  self:addCallback("UpdateGameData", self.updateGameData, true)
  self:addCallback("AddTotalGameTime", self.addTotalGameTime)
  self:addCallback("Chat", self.chat)

  self:addCallback("StartGame", self.startGame)

  self:addCallback("ArrangeSeats", self.arrangeSeats)
  self:addCallback("SetPlayerMark", self.handleSetPlayerMark)
  self:addCallback("SetBanner", self.handleSetBanner)
  self:addCallback("Reconnect", self.reconnect)
  self:addCallback("Observe", self.observe)
end

---@param ui_func boolean?
function ClientMixin:addCallback(command, func, ui_func)
  self.callbacks[command] = ui_func and function(s, data)
    func(s, data)
    self.client:notifyUI(command, data)
  end or func
end

function ClientMixin:notifyUI(command, data)
  self.client:notifyUI(command, data)
end

function ClientMixin:startRecording()
  if self.recording then return end
  if self.replaying then return end
  self.record = {
    fk.FK_VER,
    os.date("%Y%m%d%H%M%S"),
    self.enter_room_data,
    cbor.encode { Self.id, Self.player:getScreenName(), Self.player:getAvatar() },
    "", -- 由于C++写翻车，此条空出来
    "normal", -- 表示本录像是正常全流程，还是重连，还是旁观
    -- RESERVED
    "",
    "",
    "",
    "",
  }
  for _, p in ipairs(self.players) do
    if p.id ~= Self.id then
      table.insert(self.record, {
        math.floor(os.getms() / 1000),
        false,
        "AddPlayer",
        cbor.encode {
          p.player:getId(),
          p.player:getScreenName(),
          p.player:getAvatar(),
          true,
          p.player:getTotalGameTime(),
        },
      })
    end
  end
  self.recording = true
end

function ClientMixin:stopRecording(jsonData)
  if not self.recording then return end
  self.record[2] = table.concat({
    self.record[2],
    Self.player:getScreenName():gsub("%.", "%%2e"),
    self.settings.gameMode,
    Self.general,
    Self.role,
    jsonData,
  }, ".")
  self.recording = false
end

-- callbacks

function ClientMixin:sendSetupPacket(data)
  self.client:sendSetupPacket(data)
end

function ClientMixin:setup(data)
  local id, name, avatar, msec = data[1], data[2], data[3], data[4]
  local self_player = self.client:getSelf()
  self_player:setId(id)
  self_player:setScreenName(name)
  self_player:setAvatar(avatar)
  Self = ClientPlayer:new(self_player)
  if msec then
    self.client:setupServerLag(msec)
  end
end

function ClientMixin:heartbeat()
  self.client:notifyServer("Heartbeat", "")
end

function ClientMixin:enterRoom(_data)
  Self = ClientPlayer:new(self.client:getSelf())
  -- FIXME: 需要改Qml
  local ob = self.observing
  local replaying = self.replaying
  local showcards = self.replaying_show
  local recording = self.recording

  -- TODO 看情况
  ClientInstance = Client:new(self.client)
  self = ClientInstance

  self.observing = ob
  self.replaying = replaying
  self.replaying_show = showcards
  self.recording = recording -- 重连/旁观的录像后面那段EnterRoom会触发该函数

  -- FIXME: 应该在C++中修改，这种改法错大发了
  -- FIXME: C++中加入房间时需要把Self也纳入players列表
  local sp = Self.player
  self.client:addPlayer(sp:getId(), sp:getScreenName(), sp:getAvatar())
  self.players = {Self}
  self.alive_players = {Self}

  local data = _data[3]
  self.enter_room_data = cbor.encode(_data);
  -- 补一个，防止爆炸
  if self.recording then
    self.record[3] = self.enter_room_data
  end
  self.timeout = _data[2]
  self.capacity = _data[1]
  self.settings = data
end

function ClientMixin:quitRoom()
  self:stopRecording("")
end

function ClientMixin:startGame(data)
  self:startRecording()

  -- FIXME 这是个给cpp擦屁股的行为 cpp中播放录像会立刻播一句StartGame
  -- FIXME 而新UI中必须先AddPlayer再StartGame（进入页面）
  -- FIXME 为此只好延迟一会 等全addPlayer齐了再StartGame
  -- FIXME AddPlayer中有一段同理
  if self.replaying and self.capacity > 1 and #self.players == 1 then
    return
  end

  self:notifyUI("StartGame", data)
end

function ClientMixin:updateGameData(data)
  local player, total, win, run = data[1], data[2], data[3], data[4]
  player = self:getPlayerById(player)
  if player then
    player.player:setGameData(total, win, run)
  end
end

function ClientMixin:addTotalGameTime(data)
  local player, time = data[1], data[2]
  player = self:getPlayerById(player)
  if player then
    player.player:addTotalGameTime(time)
    if player == Self then
      self:notifyUI("AddTotalGameTime", data)
    end
  end
end

function ClientMixin:createPlayer(_player)
  return ClientPlayer:new(_player)
end

function ClientMixin:addPlayer(data)
  local id, name, avatar, time = data[1], data[2], data[3], data[5]
  local player = self.client:addPlayer(id, name, avatar)
  player:addTotalGameTime(time or 0)
  local p = self:createPlayer(player)
  table.insert(self.players, p)
  self:notifyUI("AddPlayer", data)

  -- FIXME 详见StartGame
  if self.replaying and #self.players == self.capacity then
    self:startGame(nil)
  end
end

function ClientMixin:removePlayer(data)
  -- jsonData: [ int id ]
  local id = data[1]
  for _, p in ipairs(self.players) do
    if p.player:getId() == id then
      table.removeOne(self.players, p)
      break
    end
  end

  if id ~= Self.id then
    self.client:removePlayer(id)
    self:notifyUI("RemovePlayer", data)
  end
end

function ClientMixin:addObserver(data)
  local id, name, avatar = data[1], data[2], data[3]
  local player = {
    getId = function() return id end,
    getScreenName = function() return name end,
    getAvatar = function() return avatar end,
  }
  local p = ClientPlayer:new(player)
  table.insert(self.observers, p)
  -- self:notifyUI("ServerMessage", string.format(Fk:translate("$AddObserver"), name))
end

function ClientMixin:removeObserver(data)
  local id = data[1]
  for _, p in ipairs(self.observers) do
    if p.player:getId() == id then
      table.removeOne(self.observers, p)
      -- self:notifyUI("ServerMessage", string.format(Fk:translate("$RemoveObserver"), p.player:getScreenName()))
      break
    end
  end
end

function ClientMixin:chat(data)
  -- jsonData: { int type, int sender, string msg }
  if data.type == 1 then
    data.general = ""
    data.time = os.date("%H:%M:%S")
    self:notifyUI("Chat", data)
    return
  end

  local p = self:getPlayerById(data.sender)
  if not p then
    for _, pl in ipairs(self.observers) do
      if pl.id == data.sender then
        p = pl; break
      end
    end
    if not p then return end
    data.general = ""
  else
    data.general = p.general
  end
  data.userName = p.player:getScreenName()
  data.time = os.date("%H:%M:%S")
  self:notifyUI("Chat", data)
end

function ClientMixin:arrangeSeats(player_circle)
  local n = #self.players
  local players = {}

  for i = 1, n do
    local p = self:getPlayerById(player_circle[i])
    p.seat = i
    table.insert(players, p)
  end

  for i = 1, #players - 1 do
    players[i].next = players[i + 1]
  end
  players[#players].next = players[1]

  self.players = players

  self:notifyUI("ArrangeSeats", player_circle)
end

function ClientMixin:handleSetPlayerMark(data)
  -- jsonData: [ int id, string mark, int value ]
  local player, mark, value = data[1], data[2], data[3]
  local p = self:getPlayerById(player)
  p:setMark(mark, value)

  if string.sub(mark, 1, 1) == "@" then
    if mark:startsWith("@[") and mark:find(']') then
      local close = mark:find(']')
      local mtype = mark:sub(3, close - 1)
      local spec = Fk.qml_marks[mtype]
      if spec then
        local text = spec.how_to_show(mark, value, p)
        if text == "#hidden" then data[3] = 0 end
      end
    end
    self:notifyUI("SetPlayerMark", data)
  end
end

function ClientMixin:handleSetBanner(data)
  -- jsonData: [ int id, string mark, int value ]
  local mark, value = data[1], data[2]
  self:setBanner(mark, value)

  if string.sub(mark, 1, 1) == "@" then
    self:notifyUI("SetBanner", data)
  end
end

function ClientMixin:sendDataToUI()
  for k, v in pairs(self.banners) do
    if k[1] == "@" then
      self:notifyUI("SetBanner", { k, v })
    end
  end
end

function ClientMixin:loadRoomSummary(data)
  local enter_room_data = { #data.circle, data.timeout, data.settings }
  self:enterRoom(enter_room_data)
  self:notifyUI("EnterRoom", enter_room_data)

  local players = data.players

  for _, pid in ipairs(data.circle) do
    if pid ~= data.you then
      self:addPlayer(players[pid].setup_data)
    end
  end

  self:startGame()

  self:arrangeSeats(data.circle)

  self:loadJsonObject(data)

  -- 此处已同步全部数据 剩下就是更新UI
  -- 交给各种Client复写了
  self:sendDataToUI()
  for _, p in ipairs(self.players) do p:sendDataToUI() end
end

function ClientMixin:reconnect(data)
  local players = data.players

  self:stopRecording("")
  self:notifyUI("EnterLobby", "")

  if not self.replaying then
    self:startRecording()
    self.record[6] = "reconnect"
    table.insert(self.record, {math.floor(os.getms() / 1000), false, "Reconnect", cbor.encode(data)})
  end

  local setup_data = players[data.you].setup_data
  self:setup(setup_data)

  self:loadRoomSummary(data)

  self:addTotalGameTime { setup_data[1], setup_data[5] }
end

function ClientMixin:observe(data)
  local players = data.players

  if not self.replaying then
    self:startRecording()
    self.record[6] = "reconnect"
    table.insert(self.record, {math.floor(os.getms() / 1000), false, "Observe", cbor.encode(data)})
  end

  local setup_data = players[data.you].setup_data
  self:setup(setup_data)

  self:loadRoomSummary(data)
end

return ClientMixin
