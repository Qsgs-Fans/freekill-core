-- 基于大语言模型的AI策略
-- 真的能行吗？不过这不是挺有意思么，试试看吧
-- 在我的设想中这个需要多进程才可实现，freekill这边只负责产出prompt
-- 中间的进程负责将prompt交给LLM，然后将回答返回freekill
-- 至于使用何种LLM、制定何种system prompt就全看他自己了
-- 我也会在同一个文件夹内用python写一个访问ollama的中间程序以便实验

-- 如果能行的话，这个AI也没法推广，毕竟目标写着“所有设备可用”，所以还是得整手搓策略的SmartAI
-- 但是LLMAI也很酷就是了

---@class LLMAI: SmartAI
local LLMAI = AI:subclass("LLMAI")

-- system prompt中应该说明基本游戏规则
-- prompt中应该要说明房间内的情况、玩家此时要完成的事情
-- 此外还要说明场内所有玩家可见的卡牌/技能的描述信息
-- 最后，还要说明答复的格式
--
-- 下面是试着设计的prompt 估计也不好用

local system_prompt = [[
  你现在是一名三国杀玩家。你的任务是根据prompt中给出的对局情况给出最佳决策。
  回复的格式需要是json，回复时不要解释原因，只给出json就行。
]]

local prompt_body = [[
  Current situation of the game:
  %s

  Description of card and skills:
  %s

  Data of this request:
  %s

  You are player #%d

  Your reply format is:
  %s

  Extra data:
  %s

  请作出选择。
]]

-- 按理说可以直接用这个重连信息喂给LLM，但是完全可以精简
function LLMAI:getSituationOfGame()
  local obj = self.room:toJsonObject(self.player)
  obj.settings = nil
  local desc_obj = {}
  for _, p in pairs(obj.players) do
    p.setup_data = nil
    for _, skill in ipairs(p.skills) do
      if not desc_obj[skill] then
        desc_obj[skill] = Fk:translate(":" .. skill)
      end
    end
    for _, cards in ipairs(p.player_cards) do
      for _, cid in ipairs(cards) do
        local c = Fk:getCardById(cid)
        desc_obj[tostring(cid)] = Fk:translate(c.name) .. "\n" .. Fk:translate(":" .. c.name)
      end
    end
  end
  return obj, desc_obj
end

function LLMAI:buildPrompt(replyFormat, extra)
  local obj, desc_obj = self:getSituationOfGame()
  return prompt_body:format(
    json.encode(obj),
    json.encode(self.data),
    json.encode(desc_obj),
    self.player.id,
    replyFormat,
    extra
  )
end

-- 发出信息并等待LLM答复。
-- 因为不知道哪里规定了只有delay和玩家的思考才可使用异步等待，所以这里只能阻塞
---@param prompt string
function LLMAI:request(prompt)
  return ""
end

-- 以下是和AI对接的各种Request包装
----------------------------------------------

local reqactive_handler_format = [[
  你可以使用的牌: %s
  你可以使用的技能: %s
]]

local reqactive_reply_format = [[
  JSON格式。若你选择直接使用手牌，则应该返回
    {"card": <那张卡牌的id>, "targets": [ <目标角色们的id，可留空表示不选目标> ]}
  若你想要发动主动技，则格式为
    {"card": { "skill": <技能名>, "subcards": [ <发动此技能选择的卡牌> ]}, "targets": [ <此技能选择的目标角色id> ]}
]]

local function extract_json(s)
  local pattern = "```json\n(.+)\n```"

  local start, end_pos, json_content = string.find(s, pattern)
  if not start then
    return ""
  end

  return json_content
end

function LLMAI:handlePlayCard()
  local cards = self:getEnabledCards()
  local skills = self:getEnabledSkills()
  local prompt = self:buildPrompt(reqactive_reply_format, reqactive_handler_format:format(json.encode(cards), json.encode(skills)))
  --print(prompt)
  --print '=================='
  local ret = fk.AskOllama('http://192.168.193.173:11434/api/generate', {
    model = "qwen2.5",
    prompt = prompt,
    system = system_prompt,
    stream = false,
  }).response
  -- print(ret)
  -- local ret2 = extract_json(ret)
  -- print(ret2)
  -- dbg()
  return json.decode(ret)
end

return LLMAI
