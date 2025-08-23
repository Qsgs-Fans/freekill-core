// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Fk
import Fk.Components.LunarLTK.Photo
import Fk.Widgets as W

PhotoBase {
  id: root

  property string role: "unknown"
  property bool role_shown: false
  property string netstate: "online"
  property int handcards: 0
  property int maxHp: 0
  property int hp: 0
  property int shield: 0
  property bool dying: false
  property bool faceup: true
  property bool chained: false
  property int drank: 0
  property int rest: 0
  property list<string> sealedSlots: []

  property int distance: -1
  property string status: "normal"
  property int maxCard: 0

  property alias handcardArea: handcardAreaItem
  property alias equipArea: equipAreaItem
  property alias areasSealed: equipAreaItem
  property alias markArea: markAreaItem
  property alias picMarkArea: picMarkAreaItem
  property alias delayedTrickArea: delayedTrickAreaItem
  property alias specialArea: specialAreaItem

  property alias progressBar: progressBar
  property alias progressTip: progressTip.text

  property bool doubleTapped: false

  property bool playing: false

  property var targetTip: []

  PixmapAnimation {
    id: animPlaying
    source: SkinBank.PIXANIM_DIR + "playing"
    anchors.centerIn: parent
    loop: true
    scale: 1.1
    visible: root.playing
    running: visible
  }

  PixmapAnimation {
    id: animSelectable
    source: SkinBank.PIXANIM_DIR + "selectable"
    anchors.centerIn: parent
    loop: true
    visible: root.state === "candidate" && root.selectable
    running: visible
  }

  HpBar {
    id: hp
    x: 8
    value: root.hp
    maxValue: root.maxHp
    shieldNum: root.shield
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 36
  }

  Rectangle {
    x: 31
    y: 5
    width: 138
    height: 222
    radius: 8

    // visible: root.drank > 0
    color: "red"
    opacity: (root.drank <= 0 ? 0 : 0.4) + Math.log(root.drank) * 0.12
    Behavior on opacity { NumberAnimation { duration: 300 } }
  }

  ColumnLayout {
    id: restRect
    anchors.centerIn: photoMask
    anchors.leftMargin: 20
    visible: root.rest > 0

    GlowText {
      Layout.alignment: Qt.AlignCenter
      text: Lua.tr("resting...")
      font.family: Config.libianName
      font.pixelSize: 40
      font.bold: true
      color: "#FEF7D6"
      glow.color: "#845422"
      glow.spread: 0.8
    }

    GlowText {
      Layout.alignment: Qt.AlignCenter
      visible: root.rest > 0 && root.rest < 999
      text: root.rest
      font.family: Config.libianName
      font.pixelSize: 34
      font.bold: true
      color: "#DBCC69"
      glow.color: "#2E200F"
      glow.spread: 0.6
    }

    GlowText {
      Layout.alignment: Qt.AlignCenter
      visible: root.rest > 0 && root.rest < 999
      text: Lua.tr("rest round num")
      font.family: Config.libianName
      font.pixelSize: 28
      color: "#F0E5D6"
      glow.color: "#2E200F"
      glow.spread: 0.6
    }
  }

  Image {
    visible: equipAreaItem.length > 0
    source: SkinBank.PHOTO_DIR + "equipbg"
    x: 31
    y: 121
  }

  Image {
    source: root.status != "normal" ? SkinBank.STATUS_DIR + root.status : ""
    x: -6
  }

  Image {
    id: turnedOver
    visible: !root.faceup
    source: SkinBank.PHOTO_DIR + "faceturned" + (Config.heg ? '-heg' : '')
    x: 29; y: 5
  }

  EquipArea {
    id: equipAreaItem

    x: 31
    y: 157
  }

  Item {
    id: specialAreaItem

    x: 31
    y: 139

    InvisibleCardArea {
      id: specialContainer
      // checkExisting: true
    }

    function updatePileInfo(areaName) {
      if (areaName.startsWith('#')) return;
      const data = Lua.call("GetPile", root.playerid, areaName);
      if (data.length === 0) {
        root.markArea.removeMark(areaName);
      } else {
        root.markArea.setMark(areaName, data.length.toString());
      }
    }

    function add(inputs, areaName) {
      updatePileInfo(areaName);
      specialContainer.add(inputs);
    }

    function remove(inputs, areaName) {
      updatePileInfo(areaName);
      return specialContainer.remove(inputs);
    }

    function updateCardPosition(a) {
      specialContainer.updateCardPosition(a);
    }
  }

  MarkArea {
    id: markAreaItem

    anchors.bottom: equipAreaItem.top
    x: 31
  }

  Image {
    id: chain
    visible: root.chained
    source: SkinBank.PHOTO_DIR + "chain"
    anchors.horizontalCenter: parent.horizontalCenter
    y: 72
  }

  Image {
    // id: saveme
    visible: (root.dead && !root.rest) || root.dying || root.surrendered
    source: {
      if (root.surrendered) {
        return SkinBank.DEATH_DIR + "surrender";
      } else if (root.dead) {
        return SkinBank.getRoleDeathPic(root.role);
      }
      return SkinBank.DEATH_DIR + "saveme";
    }
    anchors.centerIn: photoMask
  }

  Image {
    id: netstat
    source: SkinBank.STATE_DIR + root.netstate
    x: photoMask.x
    y: photoMask.y
    scale: 0.9
    transformOrigin: Item.TopLeft
  }

  Image {
    id: handcardNum
    source: SkinBank.PHOTO_DIR + "handcard"
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -6
    x: -6

    Text {
      text: {
        let n = root.handcards;
        if (root.playerid === Self.id) {
          n = Lua.call("GetPlayerHandcards", Self.id).length; // 不计入expand_pile
        }
        if (root.maxCard === root.hp || root.hp < 0) {
          return n;
        } else {
          const maxCard = root.maxCard < 900 ? root.maxCard : "∞";
          return n + "/" + maxCard;
        }
      }
      font.family: Config.libianName
      font.pixelSize: (root.maxCard === root.hp || root.hp < 0 ) ? 32 : 27
      //font.weight: 30
      color: "white"
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 4
      style: Text.Outline
    }

    W.TapHandler { // 手牌图标点击查看手牌
      enabled: {
        if (root.playerid === Self.id) return false;
        if (root.handcards === 0) return false; // 优先绑定再判buddy，否则不会更新
        if (!Lua.call("IsMyBuddy", Self.id, root.playerid) &&
          !Lua.call("HasVisibleCard", Self.id, root.playerid)) return false;
        return true;
      }
      onTapped: {
        const params = { name: "hand_card" };
        let data = Lua.call("GetPlayerHandcards", root.playerid);
        data = data.filter((e) => Lua.call("CardVisibility", e));

        params.ids = data;

        roomScene.startCheat("../RoomElement/ViewPile", params);
      }
    }
  }

  W.TapHandler {
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.NoButton
    gesturePolicy: TapHandler.WithinBounds

    onTapped: (p, btn) => {
      if (btn === Qt.LeftButton || btn === Qt.NoButton) {
        if (parent.state != "candidate" || !parent.selectable) {
          return;
        }
        parent.selected = !parent.selected;
      } else if (btn === Qt.RightButton) {
        parent.showDetail();
      }
    }

    onLongPressed: {
      parent.showDetail();
    }

    onDoubleTapped: (p, btn) => {
      if (btn === Qt.LeftButton || btn === Qt.NoButton) {
        parent.doubleTapped = true;
      }
    }
  }

  RoleComboBox {
    id: role
    value: {
      if (root.role === "hidden") return "hidden";
      if (root.role_shown) return root.role;
      Lua.call("RoleVisibility", root.playerid) ? root.role : "unknown";
    }
    anchors.top: parent.top
    anchors.topMargin: -4
    anchors.right: parent.right
    anchors.rightMargin: -4
  }

  LimitSkillArea {
    id: limitSkills
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: role.height + 2
    anchors.rightMargin: 30
  }

  Image {
    visible: root.state === "candidate" && !selectable && !selected
    source: SkinBank.PHOTO_DIR + "disable"
    x: 31; y: -21
  }

  GlowText {
    id: seatNum
    visible: !progressBar.visible
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -32
    property var seatChr: [
      "一", "二", "三", "四", "五", "六",
      "七", "八", "九", "十", "十一", "十二",
    ]
    font.family: Config.li2Name
    font.pixelSize: 32
    text: seatChr[seatNumber - 1]

    glow.color: "brown"
    glow.spread: 0.2
    glow.radius: 8
    //glow.samples: 12
  }

  SequentialAnimation {
    id: trembleAnimation
    running: false
    PropertyAnimation {
      target: root
      property: "x"
      to: root.x - 20
      easing.type: Easing.InQuad
      duration: 100
    }
    PropertyAnimation {
      target: root
      property: "x"
      to: root.x
      easing.type: Easing.OutQuad
      duration: 100
    }
  }

  function tremble() {
    trembleAnimation.start()
  }

  ProgressBar {
    id: progressBar
    width: parent.width
    height: 4
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -4
    from: 0.0
    to: 100.0
    property int duration: Config.roomTimeout * 1000

    visible: false
    NumberAnimation on value {
      running: progressBar.visible
      from: 100.0
      to: 0.0
      duration: progressBar.duration

      onFinished: {
        progressBar.visible = false;
        root.progressTip = "";
      }
    }
  }

  Image {
    anchors.top: progressBar.bottom
    anchors.topMargin: 1
    source: SkinBank.PHOTO_DIR + "control/tip"
    visible: progressTip.text != ""
    Text {
      id: progressTip
      font.family: Config.libianName
      font.pixelSize: 18
      x: 18
      color: "white"
      text: ""
    }
  }

  RowLayout {
    anchors.centerIn: parent
    spacing: 5

    Repeater {
      model: root.targetTip

      Item {
        // Layout.alignment: Qt.AlignHCenter
        width: modelData.type === "normal" ? 40 : 24

        GlowText {
          anchors.centerIn: parent
          visible: modelData.type === "normal"
          text: Util.processPrompt(modelData.content)
          font.family: Config.li2Name
          color: "#FEFE84"
          font.pixelSize: {
            if (text.length <= 3) return 36;
            else return 28;
          }
          //font.bold: true
          glow.color: "black"
          glow.spread: 0.3
          glow.radius: 5
          lineHeight: 0.85
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WrapAnywhere
          width: font.pixelSize + 4
        }

        Text {
          anchors.centerIn: parent
          visible: modelData.type === "warning"
          font.family: Config.libianName
          font.pixelSize: 24
          opacity: 0.9
          horizontalAlignment: Text.AlignHCenter
          lineHeight: 24
          lineHeightMode: Text.FixedHeight
          //color: "#EAC28A"
          color: "snow"
          width: 24
          wrapMode: Text.WrapAnywhere
          style: Text.Outline
          //styleColor: "#83231F"
          styleColor: "red"
          text: Util.processPrompt(modelData.content)
        }
      }
    }
  }

  InvisibleCardArea {
    id: handcardAreaItem
    anchors.centerIn: parent
    onLengthChanged: {
      root.handcards = Lua.evaluate(`(function()
        return #ClientInstance:getPlayerById(${root.playerid}):getCardIds("h")
      end)()`);
    }
  }

  DelayedTrickArea {
    id: delayedTrickAreaItem
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
  }

  PicMarkArea {
    id: picMarkAreaItem

    anchors.top: parent.bottom
    anchors.right: parent.right
    anchors.topMargin: -4
  }

  InvisibleCardArea {
    id: defaultArea
    anchors.centerIn: parent
  }

  Rectangle {
    color: "white"
    height: 20
    width: 20
    visible: distance != -1
    Text {
      text: distance
      anchors.centerIn: parent
    }
  }

  HandcardViewer {
    x: -44
    y: 128
    playerid: root.playerid
    handcards: root.handcards

    visible: {
      if (root.playerid === Self.id) return false;
      if (root.handcards === 0) return false; // 优先绑定再判buddy，否则不会更新
      if (!Lua.call("IsMyBuddy", Self.id, root.playerid) &&
      !Lua.call("HasVisibleCard", Self.id, root.playerid)) return false;
      return true;
    }
  }

  function updateLimitSkill(skill, time) {
    limitSkills.update(skill, time);
  }

  function showDetail() {
    if (playerid === 0 || playerid === -1) {
      return;
    }

    roomScene.startCheat("PlayerDetail", { photo: this });
  }
}
