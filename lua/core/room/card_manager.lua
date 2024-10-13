--- 负责管理AbstractRoom中所有Card的位置，若在玩家的区域中，则管理所属玩家
---@class CardManager : Object
---@field public draw_pile integer[] @ 摸牌堆，这是卡牌id的数组
---@field public discard_pile integer[] @ 弃牌堆，也是卡牌id的数组
---@field public processing_area integer[] @ 处理区，依然是卡牌id数组
---@field public void integer[] @ 从游戏中除外区，一样的是卡牌id数组
---@field public card_place table<integer, CardArea> @ 每个卡牌的id对应的区域，一张表
---@field public owner_map table<integer, integer> @ 每个卡牌id对应的主人，表的值是那个玩家的id，可能是nil
---@field public filtered_cards table<integer, Card> @ 见于Engine，其实在这
---@field public printed_cards table<integer, Card> @ 同上
---@field public next_print_card_id integer
---@field public card_marks table<integer, any> @ 用来存实体卡的card.mark
local CardManager = {}    -- mixin

function CardManager:initCardManager()
  self.draw_pile = {}
  self.discard_pile = {}
  self.processing_area = {}
  self.void = {}

  self.card_place = {}
  self.owner_map = {}

  self.filtered_cards = {}
  self.printed_cards = {}
  self.next_print_card_id = -2
  self.card_marks = {}
end

--- 基本算是私有函数，别去用
---@param cardId integer
---@param cardArea CardArea
---@param owner? integer
function CardManager:setCardArea(cardId, cardArea, owner)
  self.card_place[cardId] = cardArea
  self.owner_map[cardId] = owner
end

--- 获取一张牌所处的区域。
---@param cardId integer | Card @ 要获得区域的那张牌，可以是Card或者一个id
---@return CardArea @ 这张牌的区域
function CardManager:getCardArea(cardId)
  local cardIds = {}
  for _, cid in ipairs(Card:getIdList(cardId)) do
    local place = self.card_place[cid] or Card.Unknown
    table.insertIfNeed(cardIds, place)
  end
  return #cardIds == 1 and cardIds[1] or Card.Unknown
end

function CardManager:getCardOwner(cardId)
  if type(cardId) ~= "number" then
    assert(cardId and cardId:isInstanceOf(Card))
    cardId = cardId:getEffectiveId()
  end
  return self.owner_map[cardId] or nil
end

--- 对那个id应用锁定视为技，将它变成要被锁定视为的牌。
---@param id integer @ 要处理的id
---@param player Player @ 和这张牌扯上关系的那名玩家
---@param data any @ 随意，目前只用到JudgeStruct，为了影响判定牌
function CardManager:filterCard(id, player, data)
  if player == nil then
    self.filtered_cards[id] = nil
    return
  end

  local card = Fk:getCardById(id, true)
  local filters = Fk:currentRoom().status_skills[FilterSkill] or Util.DummyTable

  if #filters == 0 then
    self.filtered_cards[id] = nil
    return
  end

  local modify = false
  if data and type(data) == "table" and data.card
    and type(data.card) == "table" and data.card:isInstanceOf(Card) then
    modify = true
  end

  for _, f in ipairs(filters) do
    if f:cardFilter(card, player, type(data) == "table" and data.isJudgeEvent) then
      local _card = f:viewAs(card, player)
      _card.id = id
      _card.skillName = f.name
      if modify and RoomInstance then
        if not f.mute then
          player:broadcastSkillInvoke(f.name)
          RoomInstance:doAnimate("InvokeSkill", {
            name = f.name,
            player = player.id,
            skill_type = f.anim_type,
          })
        end
        RoomInstance:sendLog{
          type = "#FilterCard",
          arg = f.name,
          from = player.id,
          arg2 = card:toLogString(),
          arg3 = _card:toLogString(),
        }
      end
      card = _card
    end
    if card == nil then
      card = Fk:getCardById(id)
    end
    self.filtered_cards[id] = card
  end

  if modify then
    self.filtered_cards[id] = nil
    data.card = card
    return
  end
end

function CardManager:printCard(name, suit, number)
  local card = Fk:cloneCard(name, suit, number)

  local id = self.next_print_card_id
  card.id = id
  self.printed_cards[id] = card
  self.next_print_card_id = self.next_print_card_id - 1

  table.insert(self.void, card.id)
  self:setCardArea(card.id, Card.Void, nil)
  return card
end

-- misc

---@param card Card
---@param fromAreas? CardArea[]
---@return integer[]
function CardManager:getSubcardsByRule(card, fromAreas)
  if card:isVirtual() and #card.subcards == 0 then
    return {}
  end

  local cardIds = {}
  fromAreas = fromAreas or Util.DummyTable
  for _, cardId in ipairs(card:isVirtual() and card.subcards or { card.id }) do
    if #fromAreas == 0 or table.contains(fromAreas, self:getCardArea(cardId)) then
      table.insert(cardIds, cardId)
    end
  end

  return cardIds
end

---@param pattern string
---@param num? number
---@param fromPile? string @ 查找的来源区域，值为drawPile|discardPile|allPiles
---@return integer[] @ id列表 可能空
function CardManager:getCardsFromPileByRule(pattern, num, fromPile)
  num = num or 1
  local pileToSearch = self.draw_pile
  if fromPile == "discardPile" then
    pileToSearch = self.discard_pile
  elseif fromPile == "allPiles" then
    pileToSearch = table.simpleClone(self.draw_pile)
    table.insertTable(pileToSearch, self.discard_pile)
  end

  if #pileToSearch == 0 then
    return {}
  end

  local cardPack = {}
  if num < 3 then
    for i = 1, num do
      local randomIndex = math.random(1, #pileToSearch)
      local curIndex = randomIndex
      repeat
        local curCardId = pileToSearch[curIndex]
        if Fk:getCardById(curCardId):matchPattern(pattern) and not table.contains(cardPack, curCardId) then
          table.insert(cardPack, pileToSearch[curIndex])
          break
        end

        curIndex = curIndex + 1
        if curIndex > #pileToSearch then
          curIndex = 1
        end
      until curIndex == randomIndex

      if #cardPack == 0 then
        break
      end
    end
  else
    local matchedIds = {}
    for _, id in ipairs(pileToSearch) do
      if Fk:getCardById(id):matchPattern(pattern) then
        table.insert(matchedIds, id)
      end
    end

    local loopTimes = math.min(num, #matchedIds)
    for i = 1, loopTimes do
      local randomCardId = matchedIds[math.random(1, #matchedIds)]
      table.insert(cardPack, randomCardId)
      table.removeOne(matchedIds, randomCardId)
    end
  end

  return cardPack
end

return CardManager