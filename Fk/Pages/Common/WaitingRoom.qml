// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import Fk
import Fk.Components.Common
import Fk.Components.WaitingRoom
import Fk.Widgets as W

W.PageBase {
  id: roomScene

  property int playerNum: 0

  property bool isAllReady: false
  property bool canAddRobot: false

  property bool isOwner: false
  property bool isFull: false
  property bool isReady: false
  property bool canKickOwner: false
  property bool playersAltered: false // 有人加入或离开房间

  onPlayersAlteredChanged: {
    if (playersAltered) {
      checkCanAddRobot();
      playersAltered = false;
    }
  }

  onIsOwnerChanged: {
    if (isOwner && !isFull) {
      addInitComputers();
    }
  }

  onIsAllReadyChanged: {
    if (!isAllReady) {
      canKickOwner = false;
      kickOwnerTimer.stop();
    } else {
      Backend.playSound("./audio/system/ready");
      kickOwnerTimer.start();
    }
  }

  Timer {
    id: opTimer
    interval: 1000
  }

  Timer {
    id: kickOwnerTimer
    interval: 15000
    onTriggered: {
      canKickOwner = true;
    }
  }

  Rectangle {
    id: roomSettings

    x: 40
    y: 40

    color: "snow"
    opacity: 0.8
    radius: 6
    width: 280
    height: parent.height - 80

    Flickable {
      id: flickableContainer
      ScrollBar.vertical: ScrollBar {}
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 10
      flickableDirection: Flickable.VerticalFlick
      width: parent.width - 10
      height: parent.height - 10
      contentHeight: roominfo.height
      clip: true

      Text {
        id: roominfo
        font.pixelSize: 16
        width: parent.width
        wrapMode: TextEdit.WordWrap
        Component.onCompleted: {
          const data = Lua.call("GetRoomConfig");
          let cardpack = Lua.call("GetAllCardPack");
          cardpack = cardpack.filter(p => !data.disabledPack.includes(p));

          text = Lua.tr("GameMode") + Lua.tr(data.gameMode) + "<br />"
            + Lua.tr("LuckCardNum") + "<b>" + data.luckTime + "</b><br />"
            + Lua.tr("ResponseTime") + "<b>" + Config.roomTimeout + "</b><br />"
            + Lua.tr("ChooseGeneralTime") + "<b>" + data.generalTimeout + "</b><br />"
            + Lua.tr("GeneralBoxNum") + "<b>" + data.generalNum + "</b>"
            + (data.enableFreeAssign ? "<br />" + Lua.tr("IncludeFreeAssign")
                                     : "")
            + (data.enableDeputy ? " " + Lua.tr("IncludeDeputy") : "")
            + '<br />' + Lua.tr('CardPackages') + cardpack.map(e => {
              let ret = Lua.tr(e);
              // TODO: 这种东西最好还是变量名规范化= =
              if (ret.search(/特殊牌|衍生牌/) === -1) {
                ret = "<b>" + ret + "</b>";
              }
              return ret;
            }).join('，');
        }
      }
    }
  }

  ListModel {
    id: photoModel
  }

  GridLayout {
    id: roomArea

    anchors.left: roomSettings.right
    anchors.leftMargin: 40
    y: 40
    width: roomScene.width - 120 - roomSettings.width
    height: roomScene.height - 80

    columns: 5
    rowSpacing: -120
    columnSpacing: -20

    Repeater {
      id: photos
      model: photoModel
      WaitingPhoto {
        playerid: model.id
        general: model.avatar
        avatar: model.avatar
        screenName: model.screenName
        kingdom: "unknown"
        seatNumber: model.seatNumber
        dead: false
        surrendered: false
        isOwner: model.isOwner
        ready: model.ready
        opacity: model.sealed ? 0 : 1

        onClicked: {
          if (photoMenu.visible){
            photoMenu.close();
          } else if (model.id !== -1 && model.id !== Self.id) {
            photoMenu.open();
          }
        }

        Menu {
          id: photoMenu
          y: parent.height - 12
          width: parent.width * 0.8

          MenuItem {
            id: kickButton
            text: Lua.tr("Kick From Room")
            enabled: {
              if (model.id === Self.id) return false;
              if (model.id < -1) {
                const { minComp, curComp } = Lua.call("GetCompNum");
                return curComp > minComp;
              }
              return true;
            }
            onClicked: {
              // 傻逼qml喜欢加1.0
              // FIXME 留下image
              Cpp.notifyServer("KickPlayer", Math.floor(model.id));
            }
          }
          MenuItem {
            id: blockButton
            text: {
              const name = model.screenName;
              const blocked = !Config.blockedUsers.includes(name);
              return blocked ? Lua.tr("Block Chatter") : Lua.tr("Unblock Chatter");
            }
            enabled: model.id !== Self.id && model.id > 0 // 旁观屏蔽不了正在被旁观的人
            onClicked: {
              const name = model.screenName;
              const idx = Config.blockedUsers.indexOf(name);
              if (idx === -1) {
                if (name === "") return;
                Config.blockedUsers.push(name);
              } else {
                Config.blockedUsers.splice(idx, 1);
              }
              Config.blockedUsers = Config.blockedUsers;
            }
          }
        }
      }
    }
  }

  RowLayout {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 40

    W.ButtonContent {
      text: Lua.tr("Chat")
      font.pixelSize: 28
      onClicked: roomDrawer.open();
    }

    W.ButtonContent {
      id: kickOwner
      text: Lua.tr("Kick Owner")
      visible: canKickOwner && isFull && !isOwner
      onClicked: {
        for (let i = 0; i < playerNum; i++) {
          let item = photoModel.get(i);
          if (item.isOwner) {
            // 傻逼qml喜欢加1.0
            Cpp.notifyServer("KickPlayer", Math.floor(item.id));
          }
        }
      }
    }

    Item {
      Layout.preferredWidth: childrenRect.width
      Layout.preferredHeight: childrenRect.height
      W.ButtonContent {
        text: isReady ? Lua.tr("Cancel Ready") : Lua.tr("Ready")
        visible: !isOwner
        enabled: !opTimer.running
        onClicked: {
          opTimer.start();
          Cpp.notifyServer("Ready", "");
        }
      }

      W.ButtonContent {
        text: Lua.tr("Add Robot")
        visible: isOwner && !isFull
        enabled: Config.serverEnableBot && canAddRobot
        onClicked: {
          Cpp.notifyServer("AddRobot", "");
        }
      }

      W.ButtonContent {
        text: Lua.tr("Start Game")
        visible: isOwner && isFull
        enabled: isAllReady
        onClicked: {
          Cpp.notifyServer("StartGame", "");
        }
      }
    }
  }

  W.ButtonContent {
    id: menuButton
    anchors.top: parent.top
    anchors.topMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: 12
    text: Lua.tr("Menu")
    onClicked: {
      if (menuContainer.visible){
        menuContainer.close();
      } else {
        menuContainer.open();
      }
    }

    Menu {
      id: menuContainer
      y: menuButton.height - 12
      width: parent.width * 1.8

      MenuItem {
        id: quitButton
        text: Lua.tr("Quit")
        icon.source: Cpp.path + "/image/modmaker/back"
        onClicked: {
          if (Config.replaying) {
            Backend.controlReplayer("shutdown");
            App.quitPage();
          } else if (Config.observing) {
            Cpp.notifyServer("QuitRoom", "");
          } else {
            quitDialog.open();
          }
        }
      }

      MenuItem {
        id: volumeButton
        text: Lua.tr("Settings")
        icon.source: Cpp.path + "/image/button/tileicon/configure"
        onClicked: {
          settingsDialog.open();
        }
      }

      /*
      Menu {
        title: Lua.tr("Overview")
        icon.source: Cpp.path + "/image/button/tileicon/rule_summary"
        icon.width: 24
        icon.height: 24
        icon.color: palette.windowText
        MenuItem {
          id: generalButton
          text: Lua.tr("Generals Overview")
          icon.source: Cpp.path + "/image/button/tileicon/general_overview"
          onClicked: {
            overviewLoader.overviewType = "Generals";
            overviewDialog.open();
            overviewLoader.item.loadPackages();
          }
        }
        MenuItem {
          id: cardslButton
          text: Lua.tr("Cards Overview")
          icon.source: Cpp.path + "/image/button/tileicon/card_overview"
          onClicked: {
            overviewLoader.overviewType = "Cards";
            overviewDialog.open();
            overviewLoader.item.loadPackages();
          }
        }
        MenuItem {
          id: modesButton
          text: Lua.tr("Modes Overview")
          icon.source: Cpp.path + "/image/misc/paper"
          onClicked: {
            overviewLoader.overviewType = "Modes";
            overviewDialog.open();
          }
        }
      }
      */

      MenuItem {
        id: banSchemaButton
        text: Lua.tr("Ban List")
        icon.source: Cpp.path + "/image/button/tileicon/create_room"
        onClicked: {
          overviewLoader.overviewType = "GeneralPool";
          overviewDialog.open();
        }
      }
    }
  }

  W.PopupLoader {
    id: roomDrawer
    width: Config.winWidth * 0.4
    height: Config.winHeight * 0.95
    x: Config.winHeight * 0.025
    y: Config.winHeight * 0.025

    property int rememberedIdx: 0

    background: Rectangle {
      radius: 12 * Config.winScale
      color: "#FAFAFB"
      opacity: 0.9
    }

    ColumnLayout {
      // anchors.fill: parent
      width: parent.width / Config.winScale
      height: parent.height / Config.winScale
      scale: Config.winScale
      transformOrigin: Item.TopLeft

      W.ViewSwitcher {
        id: drawerBar
        Layout.alignment: Qt.AlignHCenter
        model: [
          Lua.tr("Chat"),
          Lua.tr("PlayerList"),
        ]
      }

      SwipeView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        interactive: false
        currentIndex: drawerBar.currentIndex
        clip: true
        Item {
          visible: !Config.replaying
          AvatarChatBox {
            id: chat
            anchors.fill: parent
          }
        }

        ListView {
          id: playerList

          clip: true
          ScrollBar.vertical: ScrollBar {}
          model: ListModel {
            id: playerListModel
          }

          delegate: ItemDelegate {
            width: playerList.width
            height: 30
            text: screenName
          }
        }
      }
    }

    onAboutToHide: {
      // 安卓下在聊天时关掉Popup会在下一次点开时完全卡死
      // 可能是Qt的bug 总之为了伺候安卓需要把聊天框赶走
      rememberedIdx = drawerBar.currentIndex;
      drawerBar.currentIndex = 0;
    }

    onAboutToShow: {
      drawerBar.currentIndex = rememberedIdx;
    }
  }

  MessageDialog {
    id: quitDialog
    title: Lua.tr("Quit")
    informativeText: Lua.tr("Are you sure to quit?")
    buttons: MessageDialog.Ok | MessageDialog.Cancel
    onButtonClicked: function (button) {
      switch (button) {
        case MessageDialog.Ok: {
          Cpp.notifyServer("QuitRoom", "[]");
          break;
        }
        case MessageDialog.Cancel: {
          quitDialog.close();
        }
      }
    }
  }

  Shortcut {
    sequence: "T"
    onActivated: {
      roomDrawer.open();
    }
  }

  function getPhotoModel(id) {
    for (let i = 0; i < playerNum; i++) {
      const item = photoModel.get(i);
      if (item.id === id) {
        return item;
      }
    }
    return undefined;
  }

  function getPhoto(id) {
    for (let i = 0; i < playerNum; i++) {
      const item = photoModel.get(i);
      if (item.id === id) {
        return photos.itemAt(i);
      }
    }
    return undefined;
  }

  function checkCanAddRobot() {
    if (Config.serverEnableBot) {
      const num = Lua.call("GetCompNum");
      canAddRobot = num.maxComp > num.curComp;
    }
  }

  function addInitComputers() {
    const num = Lua.call("GetCompNum");
    const min = num.minComp;
    const cur = num.curComp;
    const robotsToAdd = Math.max(0, min - cur);
    for (let i = 0; i < robotsToAdd; i++) {
      Cpp.notifyServer("AddRobot", "");
    }
  }

  function checkAllReady() {
    let allReady = true;
    for (let i = 0; i < playerNum; i++) {
      const item = photoModel.get(i);
      if (!item.isOwner && !item.ready) {
        allReady = false;
        break;
      }
    }
    roomScene.isAllReady = allReady;
  }

  function enterLobby(sender, data) {
    App.quitPage();

    App.setBusy(false);
    Cpp.notifyServer("RefreshRoomList", "");
    Config.saveConf();
  }

  function updateGameData(sender, data) {
    const id = data[0];
    const total = data[1];
    const win = data[2];
    const run = data[3];
    const photo = getPhoto(id);
    if (photo) {
      photo.totalGame = total;
      photo.winGame = win;
      photo.runGame = run;
    }
  }

  function setRoomOwner(sender, data) {
    // jsonData: int uid of the owner
    const uid = data[0];

    roomScene.isOwner = (Self.id === uid);

    const model = getPhotoModel(uid);
    if (typeof(model) !== "undefined") {
      model.isOwner = true;
    }
  }

  function readyChanged(sender, data) {
    const id = data[0];
    const ready = data[1];

    if (id === Self.id) {
      roomScene.isReady = !!ready;
    }

    const model = getPhotoModel(id);
    if (typeof(model) !== "undefined") {
      model.ready = ready ? true : false;
      checkAllReady();
    }
  }

  function addPlayer(sender, data) {
    // jsonData: int id, string screenName, string avatar, bool ready
    for (let i = 0; i < playerNum; i++) {
      const item = photoModel.get(i);
      if (item.id === -1) {
        const uid = data[0];
        const name = data[1];
        const avatar = data[2];
        const ready = data[3];

        item.id = uid;
        item.screenName = name;
        item.general = avatar;
        item.avatar = avatar;
        item.ready = ready;

        checkAllReady();

        if (getPhoto(-1)) {
          roomScene.isFull = false;
        } else {
          roomScene.isFull = true;
        }
        roomScene.playersAltered = true;

        return;
      }
    }
  }

  function removePlayer(sender, data) {
    // jsonData: int uid
    const uid = data[0];
    const model = getPhotoModel(uid);
    if (typeof(model) !== "undefined") {
      model.id = -1;
      model.screenName = "";
      model.avatar = "";
      model.general = "";
      model.isOwner = false;
      roomScene.isFull = false;
      roomScene.playersAltered = true;
    }
  }

  function resetPhotos() {
    photoModel.clear();
    for (let i = 0; i < 10; i++) {
      photoModel.append({
        id: i ? -1 : Self.id,
        avatar: i ? "" : Self.avatar,
        screenName: i ? "" : Self.screenName,
        seatNumber: i + 1,
        kingdom: "unknown",
        isOwner: false,
        ready: false,
        sealed: i >= playerNum,
      });
    }

    checkCanAddRobot();
    checkAllReady();
    isFull = false;
  }

  function loadPlayerData(sender) {
    const datalist = Lua.evaluate(`table.map(ClientInstance.players, function(p)
      local cp = p.player
      return {
        id = p.id,
        name = cp:getScreenName(),
        avatar = cp:getAvatar(),
        ready = p.ready,
        isOwner = p.owner,
        gameTime = cp:getTotalGameTime(),
      }
    end)`);

    resetPhotos();
    for (const d of datalist) {
      if (d.id === Self.id) {
        roomScene.isOwner = d.isOwner;
      } else {
        addPlayer(null, [d.id, d.name, d.avatar, d.ready, d.gameTime]);
      }
      const model = getPhotoModel(d.id);
      model.ready = d.ready;
      model.isOwner = d.isOwner;
    }
  }

  function startGame() {
    canKickOwner = false;
    kickOwnerTimer.stop();
    Backend.playSound("./audio/system/gamestart");

    const data = Lua.evaluate(`Fk:getBoardGame(ClientInstance.settings.gameMode).page`);
    console.log(JSON.stringify(data))
    if (!(data instanceof Object)) {
      App.enterNewPage("Fk.Pages.LunarLTK", "Room");
    } else {
      if (data.uri && data.name) {
        // TODO 还不可用，需要让Lua能添加import path
        App.enterNewPage(data.uri, data.name);
      } else {
        App.enterNewPage(Cpp.path + "/" + data.url);
      }
    }
  }

  function specialChat(pid, data, msg) {
    // skill audio: %s%d[%s]
    // death audio: ~%s
    // something special: !%s:...

    const time = data.time;
    const userName = data.userName;
    const general = Lua.tr(data.general);

    if (msg.startsWith("!") || msg.startsWith("~")) { // 胜利、阵亡
      const g = msg.slice(1);
      const extension = Lua.call("GetGeneralData", g).extension;
      if (!Config.disableMsgAudio) {
        const path = SkinBank.getAudio(g, extension, msg.startsWith("!") ? "win" : "death");
        Backend.playSound(path);
      }

      const m = Lua.tr(msg);
      data.msg = m;
      if (general === "")
        chat.append(`[${time}] ${userName}: ${m}`, data);
      else
        chat.append(`[${time}] ${userName}(${general}): ${m}`, data);

      const photo = getPhoto(pid);
      if (photo === undefined) {
        danmu.sendLog(`${userName}: ${m}`);
        return true;
      }
      photo.chat(m);

      return true;
    } else { // 技能
      const split = msg.split(":");
      if (split.length < 2) return false;
      const skill = split[0];
      const idx = parseInt(split[1]);
      const gene = split[2];
      if (!Config.disableMsgAudio)
        try {
          callbacks["LogEvent"]({
            type: "PlaySkillSound",
            name: skill,
            general: gene,
            i: idx,
          });
        } catch (e) {}
      const m = Lua.tr("$" + skill + (gene ? "_" + gene : "")
                          + (idx ? idx.toString() : ""));
      data.msg = m;
      if (general === "")
        chat.append(`[${time}] ${userName}: ${m}`, data);
      else
        chat.append(`[${time}] ${userName}(${general}): ${m}`, data)

      const photo = getPhoto(pid);
      if (photo === undefined) {
        danmu.sendLog(`${userName}: ${m}`);
        return true;
      }
      photo.chat(m);

      return true;
    }

    return false;
  }

  function addToChat(pid, raw, msg) {
    if (raw.type === 1) return;
    const photo = getPhoto(pid);
    if (photo === undefined && Config.hideObserverChatter)
      return;

    msg = msg.replace(/\{emoji([0-9]+)\}/g,
      `<img src="${Cpp.path}/image/emoji/$1.png" height="24" width="24" />`);
    raw.msg = raw.msg.replace(/\{emoji([0-9]+)\}/g,
      `<img src="${Cpp.path}/image/emoji/$1.png" height="24" width="24" />`);

    if (raw.msg.startsWith("$")) {
      if (specialChat(pid, raw, raw.msg.slice(1))) return; // 蛋花、语音
    }
    chat.append(msg, raw);

    if (photo === undefined) {
      const user = raw.userName;
      const m = raw.msg;
      danmu.sendLog(`${user}: ${m}`);
      return;
    }
    photo.chat(raw.msg);
  }

  Component.onCompleted: {
    addCallback(Command.EnterLobby, enterLobby);
    addCallback(Command.UpdateGameData, updateGameData);
    addCallback(Command.RoomOwner, setRoomOwner);

    addCallback(Command.ReadyChanged, readyChanged);
    addCallback(Command.AddPlayer, addPlayer);
    addCallback(Command.RemovePlayer, removePlayer);

    addCallback(Command.StartGame, startGame);
    addCallback(Command.BackToRoom, loadPlayerData);

    App.showToast(Lua.tr("$EnterRoom"));
    playerNum = Config.roomCapacity;

    resetPhotos();
  }
}
