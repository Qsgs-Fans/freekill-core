-- SPDX-License-Identifier: GPL-3.0-or-later

---@class UseCardEventWrappers: Object
local UseCardEventWrappers = {} -- mixin

---@return boolean
local function exec(tp, ...)
  local event = tp:create(...)
  local _, ret = event:exec()
  return ret
end

---@param room Room
---@param player ServerPlayer
---@param card Card
local playCardEmotionAndSound = function(room, player, card)
  if card.type ~= Card.TypeEquip then
    local anim_path = "./packages/" .. card.package.extensionName .. "/image/anim/" .. card.name
    if not FileIO.exists(anim_path) then
      for _, dir in ipairs(FileIO.ls("./packages/")) do
        anim_path = "./packages/" .. dir .. "/image/anim/" .. card.name
        if FileIO.exists(anim_path) then break end
      end
    end
    if FileIO.exists(anim_path) then room:setEmotion(player, anim_path) end
  end

  local soundName
  if card.type == Card.TypeEquip then
    local subTypeStr
    if card.sub_type == Card.SubtypeDefensiveRide or card.sub_type == Card.SubtypeOffensiveRide then
      subTypeStr = "horse"
    elseif card.sub_type == Card.SubtypeWeapon then
      subTypeStr = "weapon"
    else
      subTypeStr = "armor"
    end

    soundName = "./audio/card/common/" .. subTypeStr
  else
    soundName = "./packages/" .. card.package.extensionName .. "/audio/card/"
      .. (player.gender == General.Male and "male/" or "female/") .. card.name
    if not FileIO.exists(soundName .. ".mp3") then
      local orig = Fk.all_card_types[card.name]
      soundName = "./packages/" .. orig.package.extensionName .. "/audio/card/"
      .. (player.gender == General.Male and "male/" or "female/") .. orig.name
    end
  end
  room:broadcastPlaySound(soundName)
end

---@param room Room
---@param useCardData UseCardData
local sendCardEmotionAndLog = function(room, useCardData)
  local from = useCardData.from
  local _card = useCardData.card

  -- when this function is called, card is already in PlaceTable and no filter skill is applied.
  -- So filter this card manually here to get 'real' use.card
  local card = _card
  ---[[
  if not _card:isVirtual() then
    local temp = { card = _card }
    Fk:filterCard(_card.id, room:getCardOwner(_card), temp)
    card = temp.card
  end
  useCardData.card = card
  --]]

  playCardEmotionAndSound(room, room:getPlayerById(from), card)

  if not useCardData.noIndicate then
    room:doAnimate("Indicate", {
      from = from,
      to = useCardData.tos or Util.DummyTable,
    })
  end

  local useCardIds = card:isVirtual() and card.subcards or { card.id }
  if useCardData.tos and #useCardData.tos > 0 and not useCardData.noIndicate then
    local to = {}
    for _, t in ipairs(useCardData.tos) do
      table.insert(to, t[1])
    end

    if card:isVirtual() or (card ~= _card) then
      if #useCardIds == 0 then
        room:sendLog{
          type = "#UseV0CardToTargets",
          from = from,
          to = to,
          arg = card:toLogString(),
        }
      else
        room:sendLog{
          type = "#UseVCardToTargets",
          from = from,
          to = to,
          card = useCardIds,
          arg = card:toLogString(),
        }
      end
    else
      room:sendLog{
        type = "#UseCardToTargets",
        from = from,
        to = to,
        card = useCardIds
      }
    end

    for _, t in ipairs(useCardData.tos) do
      if t[2] then
        local temp = {table.unpack(t)}
        table.remove(temp, 1)
        room:sendLog{
          type = "#CardUseCollaborator",
          from = t[1],
          to = temp,
          arg = card.name,
        }
      end
    end
  elseif useCardData.toCard then
    if card:isVirtual() or (card ~= _card) then
      if #useCardIds == 0 then
        room:sendLog{
          type = "#UseV0CardToCard",
          from = from,
          arg = useCardData.toCard.name,
          arg2 = card:toLogString(),
        }
      else
        room:sendLog{
          type = "#UseVCardToCard",
          from = from,
          card = useCardIds,
          arg = useCardData.toCard.name,
          arg2 = card:toLogString(),
        }
      end
    else
      room:sendLog{
        type = "#UseCardToCard",
        from = from,
        card = useCardIds,
        arg = useCardData.toCard.name,
      }
    end
  else
    if card:isVirtual() or (card ~= _card) then
      if #useCardIds == 0 then
        room:sendLog{
          type = "#UseV0Card",
          from = from,
          arg = card:toLogString(),
        }
      else
        room:sendLog{
          type = "#UseVCard",
          from = from,
          card = useCardIds,
          arg = card:toLogString(),
        }
      end
    else
      room:sendLog{
        type = "#UseCard",
        from = from,
        card = useCardIds,
      }
    end
  end

  return _card
end

---@class GameEvent.UseCard : GameEvent
---@field public data [UseCardData]
local UseCard = GameEvent:subclass("GameEvent.UseCard")
function UseCard:main()
  local useCardData = table.unpack(self.data)
  local room = self.room
  local logic = room.logic

  if type(useCardData.attachedSkillAndUser) == "table" then
    local attachedSkillAndUser = table.simpleClone(useCardData.attachedSkillAndUser)
    self:addExitFunc(function()
      if
        type(attachedSkillAndUser) == "table" and
        Fk.skills[attachedSkillAndUser.skillName] and
        Fk.skills[attachedSkillAndUser.skillName].afterUse
      then
        Fk.skills[attachedSkillAndUser.skillName]:afterUse(room:getPlayerById(attachedSkillAndUser.user), useCardData)
      end
    end)
    useCardData.attachedSkillAndUser = nil
  end

  if useCardData.card.skill then
    useCardData.card.skill:onUse(room, useCardData)
  end

  if useCardData.card.type == Card.TypeEquip then
    local targets = TargetGroup:getRealTargets(useCardData.tos)
    if #targets == 1 then
      local target = room:getPlayerById(targets[1])
      local subType = useCardData.card.sub_type
      local equipsExist = target:getEquipments(subType)

      if #equipsExist > 0 and not target:hasEmptyEquipSlot(subType) then
        local choices = table.map(
          equipsExist,
          function(id, index)
            return "#EquipmentChoice:" .. index .. "::" .. Fk:translate(Fk:getCardById(id).name) end
        )
        if target:hasEmptyEquipSlot(subType) then
          table.insert(choices, target:getAvailableEquipSlots(subType)[1])
        end
        useCardData.toPutSlot = room:askForChoice(target, choices, "replace_equip", "#GameRuleReplaceEquipment")
      end
    end
  end

  if logic:trigger(fk.PreCardUse, room:getPlayerById(useCardData.from), useCardData) then
    logic:breakEvent()
  end

  local _card = sendCardEmotionAndLog(room, useCardData)

  room:moveCardTo(useCardData.card, Card.Processing, nil, fk.ReasonUse)

  local card = useCardData.card
  local useCardIds = card:isVirtual() and card.subcards or { card.id }
  if #useCardIds > 0 then
    if useCardData.tos and #useCardData.tos > 0 and #useCardData.tos <= 2 and not useCardData.noIndicate then
      local tos = table.map(useCardData.tos, function(e) return e[1] end)
      room:sendFootnote(useCardIds, {
        type = "##UseCardTo",
        from = useCardData.from,
        to = tos,
      })
      if card:isVirtual() or card ~= _card then
        room:sendCardVirtName(useCardIds, card.name)
      end
    else
      room:sendFootnote(useCardIds, {
        type = "##UseCard",
        from = useCardData.from,
      })
      if card:isVirtual() or card ~= _card then
        room:sendCardVirtName(useCardIds, card.name)
      end
    end
  end

  if not useCardData.extraUse then
    room:getPlayerById(useCardData.from):addCardUseHistory(useCardData.card.trueName, 1)
  end

  if useCardData.responseToEvent then
    useCardData.responseToEvent.cardsResponded = useCardData.responseToEvent.cardsResponded or {}
    table.insertIfNeed(useCardData.responseToEvent.cardsResponded, useCardData.card)
  end

  for _, event in ipairs({ fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared, fk.CardUsing }) do
    if not useCardData.toCard and #TargetGroup:getRealTargets(useCardData.tos) == 0 then
      break
    end

    logic:trigger(event, room:getPlayerById(useCardData.from), useCardData)
    if event == fk.CardUsing then
      room:doCardUseEffect(useCardData)
    end
  end
end

function UseCard:clear()
  local useCardData = table.unpack(self.data)
  local room = self.room

  room.logic:trigger(fk.CardUseFinished, room:getPlayerById(useCardData.from), useCardData)

  local leftRealCardIds = room:getSubcardsByRule(useCardData.card, { Card.Processing })
  if #leftRealCardIds > 0 then
    room:moveCards({
      ids = leftRealCardIds,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse,
    })
  end
end

---@class GameEvent.RespondCard : GameEvent
---@field public data [RespondCardData]
local RespondCard = GameEvent:subclass("GameEvent.RespondCard")
function RespondCard:main()
  local respondCardData = table.unpack(self.data)
  local room = self.room
  local logic = room.logic

  if logic:trigger(fk.PreCardRespond, room:getPlayerById(respondCardData.from), respondCardData) then
    logic:breakEvent()
  end

  local from = respondCardData.customFrom or respondCardData.from
  local card = respondCardData.card
  local cardIds = room:getSubcardsByRule(card)

  if card:isVirtual() then
    if #cardIds == 0 then
      room:sendLog{
        type = "#ResponsePlayV0Card",
        from = from,
        arg = card:toLogString(),
      }
    else
      room:sendLog{
        type = "#ResponsePlayVCard",
        from = from,
        card = cardIds,
        arg = card:toLogString(),
      }
    end
  else
    room:sendLog{
      type = "#ResponsePlayCard",
      from = from,
      card = cardIds,
    }
  end

  playCardEmotionAndSound(room, room:getPlayerById(from), card)

  room:moveCardTo(card, Card.Processing, nil, fk.ReasonResonpse)
  if #cardIds > 0 then
    room:sendFootnote(cardIds, {
      type = "##ResponsePlayCard",
      from = from,
    })
    if card:isVirtual() then
      room:sendCardVirtName(cardIds, card.name)
    end
  end

  logic:trigger(fk.CardResponding, room:getPlayerById(respondCardData.from), respondCardData)
end

function RespondCard:clear()
  local respondCardData = table.unpack(self.data)
  local room = self.room

  room.logic:trigger(fk.CardRespondFinished, room:getPlayerById(respondCardData.from), respondCardData)

  local realCardIds = room:getSubcardsByRule(respondCardData.card, { Card.Processing })
  if #realCardIds > 0 and not respondCardData.skipDrop then
    room:moveCards({
      ids = realCardIds,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonResonpse,
    })
  end
end

---@class GameEvent.CardEffect : GameEvent
---@field public data [CardEffectData]
local CardEffect = GameEvent:subclass("GameEvent.CardEffect")
function CardEffect:main()
  local cardEffectData = table.unpack(self.data)
  local room = self.room
  local logic = room.logic

  if cardEffectData.card.skill:aboutToEffect(room, cardEffectData) then
    logic:breakEvent()
  end
  for _, event in ipairs({ fk.PreCardEffect, fk.BeforeCardEffect, fk.CardEffecting }) do
    if cardEffectData.isCancellOut then
      if logic:trigger(fk.CardEffectCancelledOut, room:getPlayerById(cardEffectData.from), cardEffectData) then
        cardEffectData.isCancellOut = false
      else
        logic:breakEvent()
      end
    end

    if
      not cardEffectData.toCard and
      (
        not (room:getPlayerById(cardEffectData.to):isAlive() and cardEffectData.to)
        or #room:deadPlayerFilter(TargetGroup:getRealTargets(cardEffectData.tos)) == 0
      )
    then
      logic:breakEvent()
    end

    if table.contains((cardEffectData.nullifiedTargets or Util.DummyTable), cardEffectData.to) then
      logic:breakEvent()
    end

    if event == fk.PreCardEffect then
      if logic:trigger(event, room:getPlayerById(cardEffectData.from), cardEffectData) then
        if cardEffectData.to then
          cardEffectData.nullifiedTargets = cardEffectData.nullifiedTargets or {}
          table.insert(cardEffectData.nullifiedTargets, cardEffectData.to)
        end
        logic:breakEvent()
      end
    elseif logic:trigger(event, room:getPlayerById(cardEffectData.to), cardEffectData) then
      if cardEffectData.to then
        cardEffectData.nullifiedTargets = cardEffectData.nullifiedTargets or {}
        table.insert(cardEffectData.nullifiedTargets, cardEffectData.to)
      end
      logic:breakEvent()
    end

    room:handleCardEffect(event, cardEffectData)
  end
end

function CardEffect:clear()
  local cardEffectData = table.unpack(self.data)
  if cardEffectData.to then
    local room = self.room
    room.logic:trigger(fk.CardEffectFinished, room:getPlayerById(cardEffectData.to), cardEffectData)
  end
end


--- 根据卡牌使用数据，去实际使用这个卡牌。
---@param useCardData UseCardDataSpec @ 使用数据
---@return boolean
function UseCardEventWrappers:useCard(useCardData)
  return exec(UseCard, UseCardData:new(useCardData))
end

---@param room Room
---@param useCardData UseCardData
---@param aimEventCollaborators table<string, AimStruct[]>
---@return boolean
local onAim = function(room, useCardData, aimEventCollaborators)
  local eventStages = { fk.TargetSpecifying, fk.TargetConfirming, fk.TargetSpecified, fk.TargetConfirmed }
  for _, stage in ipairs(eventStages) do
    if (not useCardData.tos) or #useCardData.tos == 0 then
      return false
    end

    room:sortPlayersByAction(useCardData.tos, true)
    local aimGroup = AimGroup:initAimGroup(TargetGroup:getRealTargets(useCardData.tos))

    local collaboratorsIndex = {}
    local firstTarget = true
    repeat
      local toId = AimGroup:getUndoneOrDoneTargets(aimGroup)[1]
      ---@type AimStruct
      local aimStruct
      local initialEvent = false
      collaboratorsIndex[toId] = collaboratorsIndex[toId] or 1

      if not aimEventCollaborators[toId] or collaboratorsIndex[toId] > #aimEventCollaborators[toId] then
        aimStruct = {
          from = useCardData.from,
          card = useCardData.card,
          to = toId,
          targetGroup = useCardData.tos,
          nullifiedTargets = useCardData.nullifiedTargets or {},
          tos = aimGroup,
          firstTarget = firstTarget,
          additionalDamage = useCardData.additionalDamage,
          additionalRecover = useCardData.additionalRecover,
          additionalEffect = useCardData.additionalEffect,
          extra_data = useCardData.extra_data,
        }

        local index = 1
        for _, targets in ipairs(useCardData.tos) do
          if index > collaboratorsIndex[toId] then
            break
          end

          if #targets > 1 then
            for i = 2, #targets do
              aimStruct.subTargets = {}
              table.insert(aimStruct.subTargets, targets[i])
            end
          end
        end

        collaboratorsIndex[toId] = 1
        initialEvent = true
      else
        aimStruct = aimEventCollaborators[toId][collaboratorsIndex[toId]]
        aimStruct.from = useCardData.from
        aimStruct.card = useCardData.card
        aimStruct.tos = aimGroup
        aimStruct.targetGroup = useCardData.tos
        aimStruct.nullifiedTargets = useCardData.nullifiedTargets or {}
        aimStruct.firstTarget = firstTarget
        aimStruct.additionalEffect = useCardData.additionalEffect
        aimStruct.extra_data = useCardData.extra_data
      end

      firstTarget = false

      room.logic:trigger(stage, (stage == fk.TargetSpecifying or stage == fk.TargetSpecified) and room:getPlayerById(aimStruct.from) or room:getPlayerById(aimStruct.to), aimStruct)

      AimGroup:removeDeadTargets(room, aimStruct)

      local aimEventTargetGroup = aimStruct.targetGroup
      if aimEventTargetGroup then
        room:sortPlayersByAction(aimEventTargetGroup, true)
      end

      useCardData.from = aimStruct.from
      useCardData.tos = aimEventTargetGroup
      useCardData.nullifiedTargets = aimStruct.nullifiedTargets
      useCardData.additionalEffect = aimStruct.additionalEffect
      useCardData.extra_data = aimStruct.extra_data

      if #AimGroup:getAllTargets(aimStruct.tos) == 0 then
        return false
      end

      local cancelledTargets = AimGroup:getCancelledTargets(aimStruct.tos)
      if #cancelledTargets > 0 then
        for _, target in ipairs(cancelledTargets) do
          aimEventCollaborators[target] = {}
          collaboratorsIndex[target] = 1
        end
      end
      aimStruct.tos[AimGroup.Cancelled] = {}

      aimEventCollaborators[toId] = aimEventCollaborators[toId] or {}
      if room:getPlayerById(toId):isAlive() then
        if initialEvent then
          table.insert(aimEventCollaborators[toId], aimStruct)
        else
          aimEventCollaborators[toId][collaboratorsIndex[toId]] = aimStruct
        end

        collaboratorsIndex[toId] = collaboratorsIndex[toId] + 1
      end

      AimGroup:setTargetDone(aimStruct.tos, toId)
      aimGroup = aimStruct.tos
    until #AimGroup:getUndoneOrDoneTargets(aimGroup) == 0
  end

  return true
end

--- 对卡牌使用数据进行生效
---@param useCardData UseCardData
function UseCardEventWrappers:doCardUseEffect(useCardData)
  ---@type table<string, AimStruct>
  local aimEventCollaborators = {}
  if useCardData.tos and not onAim(self, useCardData, aimEventCollaborators) then
    return
  end

  local realCardIds = self:getSubcardsByRule(useCardData.card, { Card.Processing })

  self.logic:trigger(fk.BeforeCardUseEffect, self:getPlayerById(useCardData.from), useCardData)
  -- If using Equip or Delayed trick, move them to the area and return
  if useCardData.card.type == Card.TypeEquip then
    if #realCardIds == 0 then
      return
    end

    local target = TargetGroup:getRealTargets(useCardData.tos)[1]
    if not (self:getPlayerById(target).dead or table.contains((useCardData.nullifiedTargets or Util.DummyTable), target)) then
      local existingEquipId
      if useCardData.toPutSlot and useCardData.toPutSlot:startsWith("#EquipmentChoice") then
        local index = useCardData.toPutSlot:split(":")[2]
        existingEquipId = self:getPlayerById(target):getEquipments(useCardData.card.sub_type)[tonumber(index)]
      elseif not self:getPlayerById(target):hasEmptyEquipSlot(useCardData.card.sub_type) then
        existingEquipId = self:getPlayerById(target):getEquipment(useCardData.card.sub_type)
      end

      if existingEquipId then
        self:moveCards(
          {
            ids = { existingEquipId },
            from = target,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          },
          {
            ids = realCardIds,
            to = target,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonUse,
          }
        )
      else
        self:moveCards({
          ids = realCardIds,
          to = target,
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonUse,
        })
      end
    end

    return
  elseif useCardData.card.sub_type == Card.SubtypeDelayedTrick then
    if #realCardIds == 0 then
      return
    end

    local target = TargetGroup:getRealTargets(useCardData.tos)[1]
    if not (self:getPlayerById(target).dead or table.contains((useCardData.nullifiedTargets or Util.DummyTable), target)) then
      local findSameCard = false
      for _, cardId in ipairs(self:getPlayerById(target):getCardIds(Player.Judge)) do
        if Fk:getCardById(cardId).trueName == useCardData.card.trueName then
          findSameCard = true
        end
      end

      if not findSameCard then
        if useCardData.card:isVirtual() then
          self:getPlayerById(target):addVirtualEquip(useCardData.card)
        elseif useCardData.card.name ~= Fk:getCardById(useCardData.card.id, true).name then
          local card = Fk:cloneCard(useCardData.card.name)
          card.skillNames = useCardData.card.skillNames
          card:addSubcard(useCardData.card.id)
          self:getPlayerById(target):addVirtualEquip(card)
        else
          self:getPlayerById(target):removeVirtualEquip(useCardData.card.id)
        end

        self:moveCards({
          ids = realCardIds,
          to = target,
          toArea = Card.PlayerJudge,
          moveReason = fk.ReasonUse,
        })

        return
      end
    end

    return
  end

  if not useCardData.card.skill then
    return
  end

  -- If using card to other card (like jink or nullification), simply effect and return
  if useCardData.toCard ~= nil then
    local cardEffectData = CardEffectData:new{
      from = useCardData.from,
      tos = useCardData.tos,
      card = useCardData.card,
      toCard = useCardData.toCard,
      responseToEvent = useCardData.responseToEvent,
      nullifiedTargets = useCardData.nullifiedTargets,
      disresponsiveList = useCardData.disresponsiveList,
      unoffsetableList = useCardData.unoffsetableList,
      additionalDamage = useCardData.additionalDamage,
      additionalRecover = useCardData.additionalRecover,
      cardsResponded = useCardData.cardsResponded,
      prohibitedCardNames = useCardData.prohibitedCardNames,
      extra_data = useCardData.extra_data,
    }
    self:doCardEffect(cardEffectData)

    if cardEffectData.cardsResponded then
      useCardData.cardsResponded = useCardData.cardsResponded or {}
      for _, card in ipairs(cardEffectData.cardsResponded) do
        table.insertIfNeed(useCardData.cardsResponded, card)
      end
    end
    return
  end

  useCardData.additionalEffect = useCardData.additionalEffect or 0
  while true do
    if #TargetGroup:getRealTargets(useCardData.tos) > 0 and useCardData.card.skill.onAction then
      useCardData.card.skill:onAction(self, useCardData)
    end

    -- Else: do effect to all targets
    local collaboratorsIndex = {}
    for _, toId in ipairs(TargetGroup:getRealTargets(useCardData.tos)) do
      if self:getPlayerById(toId):isAlive() then
        ---@class CardEffectDataSpec
        local cardEffectData = {
          from = useCardData.from,
          tos = useCardData.tos,
          card = useCardData.card,
          toCard = useCardData.toCard,
          responseToEvent = useCardData.responseToEvent,
          nullifiedTargets = useCardData.nullifiedTargets,
          disresponsiveList = useCardData.disresponsiveList,
          unoffsetableList = useCardData.unoffsetableList,
          additionalDamage = useCardData.additionalDamage,
          additionalRecover = useCardData.additionalRecover,
          cardsResponded = useCardData.cardsResponded,
          prohibitedCardNames = useCardData.prohibitedCardNames,
          extra_data = useCardData.extra_data,
        }

        if aimEventCollaborators[toId] then
          cardEffectData.to = toId
          collaboratorsIndex[toId] = collaboratorsIndex[toId] or 1
          local curAimEvent = aimEventCollaborators[toId][collaboratorsIndex[toId]]

          cardEffectData.subTargets = curAimEvent.subTargets
          cardEffectData.additionalDamage = curAimEvent.additionalDamage
          cardEffectData.additionalRecover = curAimEvent.additionalRecover

          if curAimEvent.disresponsiveList then
            cardEffectData.disresponsiveList = cardEffectData.disresponsiveList or {}

            for _, disresponsivePlayer in ipairs(curAimEvent.disresponsiveList) do
              if not table.contains(cardEffectData.disresponsiveList, disresponsivePlayer) then
                table.insert(cardEffectData.disresponsiveList, disresponsivePlayer)
              end
            end
          end

          if curAimEvent.unoffsetableList then
            cardEffectData.unoffsetableList = cardEffectData.unoffsetableList or {}

            for _, unoffsetablePlayer in ipairs(curAimEvent.unoffsetableList) do
              if not table.contains(cardEffectData.unoffsetableList, unoffsetablePlayer) then
                table.insert(cardEffectData.unoffsetableList, unoffsetablePlayer)
              end
            end
          end

          cardEffectData.disresponsive = curAimEvent.disresponsive
          cardEffectData.unoffsetable = curAimEvent.unoffsetable
          cardEffectData.fixedResponseTimes = curAimEvent.fixedResponseTimes
          cardEffectData.fixedAddTimesResponsors = curAimEvent.fixedAddTimesResponsors

          collaboratorsIndex[toId] = collaboratorsIndex[toId] + 1

          local curCardEffectEvent = CardEffectData:new(table.simpleClone(cardEffectData))
          self:doCardEffect(curCardEffectEvent)

          if curCardEffectEvent.cardsResponded then
            useCardData.cardsResponded = useCardData.cardsResponded or {}
            for _, card in ipairs(curCardEffectEvent.cardsResponded) do
              table.insertIfNeed(useCardData.cardsResponded, card)
            end
          end

          if type(curCardEffectEvent.nullifiedTargets) == 'table' then
            table.insertTableIfNeed(useCardData.nullifiedTargets, curCardEffectEvent.nullifiedTargets)
          end
        end
      end
    end

    if #TargetGroup:getRealTargets(useCardData.tos) > 0 and useCardData.card.skill.onAction then
      useCardData.card.skill:onAction(self, useCardData, true)
    end

    if useCardData.additionalEffect > 0 then
      useCardData.additionalEffect = useCardData.additionalEffect - 1
    else
      break
    end
  end
end

--- 对卡牌效果数据进行生效
---@param cardEffectData CardEffectData
function UseCardEventWrappers:doCardEffect(cardEffectData)
  return exec(CardEffect, cardEffectData)
end

---@param event CardEffectEvent
---@param cardEffectData CardEffectData
function UseCardEventWrappers:handleCardEffect(event, cardEffectData)
  if event == fk.PreCardEffect then
    if
      cardEffectData.card.trueName == "slash" and
      not (cardEffectData.unoffsetable or table.contains(cardEffectData.unoffsetableList or Util.DummyTable, cardEffectData.to))
    then
      local loopTimes = 1
      if cardEffectData.fixedResponseTimes then
        if type(cardEffectData.fixedResponseTimes) == "table" then
          loopTimes = cardEffectData.fixedResponseTimes["jink"] or 1
        elseif type(cardEffectData.fixedResponseTimes) == "number" then
          loopTimes = cardEffectData.fixedResponseTimes
        end
      end
      Fk.currentResponsePattern = "jink"

      for i = 1, loopTimes do
        local to = self:getPlayerById(cardEffectData.to)
        local prompt = ""
        if cardEffectData.from then
          if loopTimes == 1 then
            prompt = "#slash-jink:" .. cardEffectData.from
          else
            prompt = "#slash-jink-multi:" .. cardEffectData.from .. "::" .. i .. ":" .. loopTimes
          end
        end

        local use = self:askForUseCard(
          to,
          "jink",
          nil,
          prompt,
          true,
          nil,
          cardEffectData
        )
        if use then
          use.toCard = cardEffectData.card
          use.responseToEvent = cardEffectData
          self:useCard(use)
        end

        if not cardEffectData.isCancellOut then
          break
        end

        cardEffectData.isCancellOut = i == loopTimes
      end
    elseif
      cardEffectData.card.type == Card.TypeTrick and
      not (cardEffectData.disresponsive or cardEffectData.unoffsetable) and
      not table.contains(cardEffectData.prohibitedCardNames or Util.DummyTable, "nullification")
    then
      local players = {}
      Fk.currentResponsePattern = "nullification"
      local cardCloned = Fk:cloneCard("nullification")
      for _, p in ipairs(self.alive_players) do
        if not p:prohibitUse(cardCloned) then
          local cards = p:getHandlyIds()
          for _, cid in ipairs(cards) do
            if
              Fk:getCardById(cid).trueName == "nullification" and
              not (
                table.contains(cardEffectData.disresponsiveList or Util.DummyTable, p.id) or
                table.contains(cardEffectData.unoffsetableList or Util.DummyTable, p.id)
              )
            then
              table.insert(players, p)
              break
            end
          end
          if not table.contains(players, p) then
            Self = p -- for enabledAtResponse
            for _, s in ipairs(table.connect(p.player_skills, p._fake_skills)) do
              if
                s.pattern and
                Exppattern:Parse("nullification"):matchExp(s.pattern) and
                not (s.enabledAtResponse and not s:enabledAtResponse(p)) and
                not (
                  table.contains(cardEffectData.disresponsiveList or Util.DummyTable, p.id) or
                  table.contains(cardEffectData.unoffsetableList or Util.DummyTable, p.id)
                )
              then
                table.insert(players, p)
                break
              end
            end
          end
        end
      end

      local prompt = ""
      if cardEffectData.to then
        prompt = "#AskForNullification::" .. cardEffectData.to .. ":" .. cardEffectData.card.name
      elseif cardEffectData.from then
        prompt = "#AskForNullificationWithoutTo:" .. cardEffectData.from .. "::" .. cardEffectData.card.name
      end

      local extra_data
      if #TargetGroup:getRealTargets(cardEffectData.tos) > 1 then
        local parentUseEvent = self.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if parentUseEvent then
          extra_data = { useEventId = parentUseEvent.id, effectTo = cardEffectData.to }
        end
      end
      if #players > 0 and cardEffectData.card.trueName == "nullification" then
        self:animDelay(2)
      end
      local use = self:askForNullification(players, nil, nil, prompt, true, extra_data, cardEffectData)
      if use then
        use.toCard = cardEffectData.card
        use.responseToEvent = cardEffectData
        self:useCard(use)
      end
    end
    Fk.currentResponsePattern = nil
  elseif event == fk.CardEffecting then
    if cardEffectData.card.skill then
      local data = { ---@type SkillEffectDataSpec
        who = self:getPlayerById(cardEffectData.from),
        skill = cardEffectData.card.skill,
        skill_cb = function ()
          cardEffectData.card.skill:onEffect(self, cardEffectData)
        end,
        skill_data = Util.DummyTable
      }
      exec(GameEvent.SkillEffect, SkillEffectData:new(data))
    end
  end
end

--- 对“打出牌”进行处理
---@param responseCardData RespondCardDataSpec
function UseCardEventWrappers:responseCard(responseCardData)
  return exec(RespondCard, RespondCardData:new(responseCardData))
end

--- 令角色对某些目标使用虚拟卡牌，会检测使用和目标合法性。不合法则返回nil
---@param card_name string @ 想要视为使用的牌名
---@param subcards? integer[] @ 子卡，可以留空或者直接nil
---@param from ServerPlayer @ 使用来源
---@param tos ServerPlayer | ServerPlayer[] @ 目标角色（列表）
---@param skillName? string @ 技能名
---@param extra? boolean @ 是否不计入次数
---@return UseCardDataSpec | false
function UseCardEventWrappers:useVirtualCard(card_name, subcards, from, tos, skillName, extra)
  local card = Fk:cloneCard(card_name)
  if skillName then card.skillName = skillName end

  if from:prohibitUse(card) then return nil end

  if tos.class then tos = { tos } end
  for i = #tos, 1, -1 do
    local p = tos[i]
    if from:isProhibited(p, card) then
      table.remove(tos, i)
    end
  end

  if #tos == 0 then return nil end

  if subcards then card:addSubcards(Card:getIdList(subcards)) end

  local use = { ---@type UseCardDataSpec
    from = from.id,
    tos = table.map(tos, function(p) return { p.id } end),
    card = card,
    extraUse = extra
  }
  self:useCard(use)

  return use
end

return { UseCard, RespondCard, CardEffect, UseCardEventWrappers }
