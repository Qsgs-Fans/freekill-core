-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("standard_cards", Package.CardPack)

local prefix = "packages."
if UsingNewCore then prefix = "packages.freekill-core." end

extension:loadSkillSkels(require(prefix .. "standard_cards.pkg.skills"))

local slash = fk.CreateCard{
  name = "slash",
  type = Card.TypeBasic,
  is_damage_card = true,
  skill = "slash_skill",
}
extension:loadCardSkels {
  slash,
}
extension:addCardSpec("slash", Card.Spade, 7)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 9)
extension:addCardSpec("slash", Card.Spade, 9)
extension:addCardSpec("slash", Card.Spade, 10)
extension:addCardSpec("slash", Card.Spade, 10)

extension:addCardSpec("slash", Card.Club, 2)
extension:addCardSpec("slash", Card.Club, 3)
extension:addCardSpec("slash", Card.Club, 4)
extension:addCardSpec("slash", Card.Club, 5)
extension:addCardSpec("slash", Card.Club, 6)
extension:addCardSpec("slash", Card.Club, 7)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 10)
extension:addCardSpec("slash", Card.Club, 10)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Club, 11)

extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 11)

extension:addCardSpec("slash", Card.Diamond, 6)
extension:addCardSpec("slash", Card.Diamond, 7)
extension:addCardSpec("slash", Card.Diamond, 8)
extension:addCardSpec("slash", Card.Diamond, 9)
extension:addCardSpec("slash", Card.Diamond, 10)
extension:addCardSpec("slash", Card.Diamond, 13)

local jink = fk.CreateCard{
  type = Card.TypeBasic,
  name = "jink",
  skill = "jink_skill",
  is_passive = true,
}
extension:loadCardSkels {
  jink,
}
extension:addCardSpec("jink", Card.Heart, 2)
extension:addCardSpec("jink", Card.Heart, 2)
extension:addCardSpec("jink", Card.Heart, 13)
extension:addCardSpec("jink", Card.Diamond, 2)
extension:addCardSpec("jink", Card.Diamond, 2)
extension:addCardSpec("jink", Card.Diamond, 3)
extension:addCardSpec("jink", Card.Diamond, 4)
extension:addCardSpec("jink", Card.Diamond, 5)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 9)
extension:addCardSpec("jink", Card.Diamond, 10)
extension:addCardSpec("jink", Card.Diamond, 11)
extension:addCardSpec("jink", Card.Diamond, 11)

local peach = fk.CreateCard{
  name = "peach",
  type = Card.TypeBasic,
  skill = "peach_skill",
}
extension:loadCardSkels {
  peach,
}
extension:addCardSpec("peach", Card.Heart, 3)
extension:addCardSpec("peach", Card.Heart, 4)
extension:addCardSpec("peach", Card.Heart, 6)
extension:addCardSpec("peach", Card.Heart, 7)
extension:addCardSpec("peach", Card.Heart, 8)
extension:addCardSpec("peach", Card.Heart, 9)
extension:addCardSpec("peach", Card.Heart, 12)
extension:addCardSpec("peach", Card.Heart, 12)

local dismantlement = fk.CreateCard{
  name = "dismantlement",
  type = Card.TypeTrick,
  skill = "dismantlement_skill",
}
extension:loadCardSkels {
  dismantlement,
}
extension:addCardSpec("dismantlement", Card.Spade, 3)
extension:addCardSpec("dismantlement", Card.Spade, 4)
extension:addCardSpec("dismantlement", Card.Spade, 12)
extension:addCardSpec("dismantlement", Card.Club, 3)
extension:addCardSpec("dismantlement", Card.Club, 4)
extension:addCardSpec("dismantlement", Card.Heart, 12)

local snatch = fk.CreateCard{
  name = "snatch",
  type = Card.TypeTrick,
  skill = "snatch_skill",
}
extension:loadCardSkels {
  snatch,
}
extension:addCardSpec("snatch", Card.Spade, 3)
extension:addCardSpec("snatch", Card.Spade, 4)
extension:addCardSpec("snatch", Card.Spade, 11)
extension:addCardSpec("snatch", Card.Diamond, 3)
extension:addCardSpec("snatch", Card.Diamond, 4)

local duel = fk.CreateCard{
  name = "duel",
  type = Card.TypeTrick,
  skill = "duel_skill",
  is_damage_card = true,
}
extension:loadCardSkels {
  duel,
}
extension:addCardSpec("duel", Card.Spade, 1)
extension:addCardSpec("duel", Card.Club, 1)
extension:addCardSpec("duel", Card.Diamond, 1)

local collateral = fk.CreateCard{
  name = "collateral",
  type = Card.TypeTrick,
  skill = "collateral_skill",
}
extension:loadCardSkels {
  collateral,
}
extension:addCardSpec("collateral", Card.Club, 12)
extension:addCardSpec("collateral", Card.Club, 13)

local ex_nihilo = fk.CreateCard{
  name = "ex_nihilo",
  type = Card.TypeTrick,
  skill = "ex_nihilo_skill",
}
extension:loadCardSkels {
  ex_nihilo,
}
extension:addCardSpec("ex_nihilo", Card.Heart, 7)
extension:addCardSpec("ex_nihilo", Card.Heart, 8)
extension:addCardSpec("ex_nihilo", Card.Heart, 9)
extension:addCardSpec("ex_nihilo", Card.Heart, 11)

local nullification = fk.CreateCard{
  name = "nullification",
  type = Card.TypeTrick,
  skill = "nullification_skill",
  is_passive = true,
}
extension:loadCardSkels {
  nullification,
}
extension:addCardSpec("nullification", Card.Spade, 11)
extension:addCardSpec("nullification", Card.Club, 12)
extension:addCardSpec("nullification", Card.Club, 13)
extension:addCardSpec("nullification", Card.Diamond, 12)

local savage_assault = fk.CreateCard{
  name = "savage_assault",
  type = Card.TypeTrick,
  skill = "savage_assault_skill",
  is_damage_card = true,
  multiple_targets = true,
}
extension:loadCardSkels {
  savage_assault,
}
extension:addCardSpec("savage_assault", Card.Spade, 7)
extension:addCardSpec("savage_assault", Card.Spade, 13)
extension:addCardSpec("savage_assault", Card.Club, 7)

local archery_attack = fk.CreateCard{
  name = "archery_attack",
  type = Card.TypeTrick,
  skill = "archery_attack_skill",
  is_damage_card = true,
  multiple_targets = true,
}
extension:loadCardSkels {
  archery_attack,
}
extension:addCardSpec("archery_attack", Card.Heart, 1)

local god_salvation = fk.CreateCard{
  name = "god_salvation",
  type = Card.TypeTrick,
  skill = "god_salvation_skill",
  multiple_targets = true,
}
extension:loadCardSkels {
  god_salvation,
}
extension:addCardSpec("god_salvation", Card.Heart, 1)

local amazing_grace = fk.CreateCard{
  name = "amazing_grace",
  type = Card.TypeTrick,
  skill = "amazing_grace_skill",
  multiple_targets = true,
}
extension:loadCardSkels {
  amazing_grace,
}
extension:addCardSpec("amazing_grace", Card.Heart, 3)
extension:addCardSpec("amazing_grace", Card.Heart, 4)

local lightning = fk.CreateCard{
  name = "lightning",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
  skill = "lightning_skill",
}
extension:loadCardSkels {
  lightning,
}
extension:addCardSpec("lightning", Card.Spade, 1)
extension:addCardSpec("lightning", Card.Heart, 12)

local indulgence = fk.CreateCard{
  name = "indulgence",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
  skill = "indulgence_skill",
}
extension:loadCardSkels {
  indulgence,
}
extension:addCardSpec("indulgence", Card.Spade, 6)
extension:addCardSpec("indulgence", Card.Club, 6)
extension:addCardSpec("indulgence", Card.Heart, 6)

local crossbow = fk.CreateCard{
  name = "crossbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 1,
  skill = "#crossbow_skill",
}
extension:loadCardSkels {
  crossbow,
}
extension:addCardSpec("crossbow", Card.Club, 1)
extension:addCardSpec("crossbow", Card.Diamond, 1)

local armorInvalidity = fk.CreateInvaliditySkill {
  name = "armor_invalidity",
  global = true,
  invalidity_func = function(self, player, skill)
    if skill.attached_equip and Fk:cloneCard(skill.attached_equip).sub_type == Card.SubtypeArmor then
      if player:getMark(MarkEnum.MarkArmorNullified) > 0 then return true end

      --无视防具（规则集版）！
      if not RoomInstance then return end
      local logic = RoomInstance.logic
      local event = logic:getCurrentEvent()
      local from = nil
      repeat
        if event.event == GameEvent.SkillEffect then
          if not event.data[3].cardSkill then
            from = event.data[2]
            break
          end
        elseif event.event == GameEvent.Damage then
          local damage = event.data
          if damage.to ~= player then return false end
          from = damage.from
          break
        elseif event.event == GameEvent.UseCard then
          local use = event.data
          if not table.contains(TargetGroup:getRealTargets(use.tos), player.id) then return false end
          from = use.from
          break
        end
        event = event.parent
      until event == nil
      if from then
        local suffixes = {""}
        table.insertTable(suffixes, MarkEnum.TempMarkSuffix)
        for _, suffix in ipairs(suffixes) do
          if table.contains(from:getTableMark(MarkEnum.MarkArmorInvalidTo .. suffix), player.id) or
            table.contains(player:getTableMark(MarkEnum.MarkArmorInvalidFrom .. suffix), from.id) then
            return true
          end
        end
      end
    end
  end
}
Fk:addSkill(armorInvalidity)

local qinggang_sword = fk.CreateCard{
  name = "qinggang_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  skill = "#qinggang_sword_skill",
}
extension:loadCardSkels {
  qinggang_sword,
}
extension:addCardSpec("qinggang_sword", Card.Spade, 6)

local ice_sword = fk.CreateCard{
  name = "ice_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  skill = "#ice_sword_skill",
}
extension:loadCardSkels {
  ice_sword,
}
extension:addCardSpec("ice_sword", Card.Spade, 2)

local double_swords = fk.CreateCard{
  name = "double_swords",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  skill = "#double_swords_skill",
}
extension:loadCardSkels {
  double_swords,
}
extension:addCardSpec("double_swords", Card.Spade, 2)

local blade = fk.CreateCard{
  name = "blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  skill = "#blade_skill",
}
extension:loadCardSkels {
  blade,
}
extension:addCardSpec("blade", Card.Spade, 5)

local spear = fk.CreateCard{
  name = "spear",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  skill = "spear_skill",
}
extension:loadCardSkels {
  spear,
}
extension:addCardSpec("spear", Card.Spade, 12)

local axe = fk.CreateCard{
  name = "axe",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  skill = "axe_skill",
}
extension:loadCardSkels {
  axe,
}
extension:addCardSpec("axe", Card.Diamond, 5)

local halberd = fk.CreateCard{
  name = "halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  skill = "#halberd_skill",
}
extension:loadCardSkels {
  halberd,
}
extension:addCardSpec("halberd", Card.Diamond, 12)

local kylin_bow = fk.CreateCard{
  name = "kylin_bow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 5,
  skill = "#kylin_bow_skill",
}
extension:loadCardSkels {
  kylin_bow,
}
extension:addCardSpec("kylin_bow", Card.Heart, 5)

local eight_diagram = fk.CreateCard{
  name = "eight_diagram",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  skill = "#eight_diagram_skill",
}
extension:loadCardSkels {
  eight_diagram,
}
extension:addCardSpec("eight_diagram", Card.Spade, 2)
extension:addCardSpec("eight_diagram", Card.Club, 2)

local nioh_shield = fk.CreateCard{
  name = "nioh_shield",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  skill = "#nioh_shield_skill",
}
extension:loadCardSkels {
  nioh_shield,
}
extension:addCardSpec("nioh_shield", Card.Club, 2)

local dilu = fk.CreateCard{
  name = "dilu",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  skill = "#dilu_skill",
}
extension:loadCardSkels {
  dilu,
}
extension:addCardSpec("dilu", Card.Club, 5)

local jueying = fk.CreateCard{
  name = "jueying",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  skill = "#jueying_skill",
}
extension:loadCardSkels {
  jueying,
}
extension:addCardSpec("jueying", Card.Spade, 5)

local zhuahuangfeidian = fk.CreateCard{
  name = "zhuahuangfeidian",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  skill = "#zhuahuangfeidian_skill",
}
extension:loadCardSkels {
  zhuahuangfeidian,
}
extension:addCardSpec("zhuahuangfeidian", Card.Heart, 13)

local chitu = fk.CreateCard{
  name = "chitu",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  skill = "#chitu_skill",
}
extension:loadCardSkels {
  chitu,
}
extension:addCardSpec("chitu", Card.Heart, 5)

local dayuan = fk.CreateCard{
  name = "dayuan",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  skill = "#dayuan_skill",
}
extension:loadCardSkels {
  dayuan,
}
extension:addCardSpec("dayuan", Card.Spade, 13)

local zixing = fk.CreateCard{
  name = "zixing",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  skill = "#zixing_skill",
}
extension:loadCardSkels {
  zixing,
}
extension:addCardSpec("zixing", Card.Diamond, 13)

local pkgprefix = "packages/"
if UsingNewCore then pkgprefix = "packages/freekill-core/" end
dofile(pkgprefix .. "standard_cards/i18n/init.lua")

return extension
