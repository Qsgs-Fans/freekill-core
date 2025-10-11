// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import Fk
import Fk.Widgets as W

Item {
  width: 600
  height: 800

  W.PreferencePage {
    id: prefPage
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonBar.top
    anchors.bottomMargin: 8
    groupWidth: width * 0.8
    W.PreferenceGroup {
      title: Lua.tr("Basic settings")
      W.EntryRow {
        id: roomName
        title: Lua.tr("Room Name")
        text: Lua.tr("$RoomName").arg(Self.screenName)
      }
    }

    W.PreferenceGroup {
      W.EntryRow {
        id: roomPassword
        title: Lua.tr("Room Password")
      }
    }

    W.PreferenceGroup {
      title: Lua.tr("Properties")
      W.SpinRow {
        id: playerNum
        title: Lua.tr("Player num")
        from: 2
        to: 12
        value: Config.preferedPlayerNum

        onValueChanged: {
          Config.preferedPlayerNum = value;
        }
      }
      W.SpinRow {
        title: Lua.tr("Operation timeout")
        from: 10
        to: 60
        editable: true
        value: Config.preferredTimeout

        onValueChanged: {
          Config.preferredTimeout = value;
        }
      }
    }

    Component.onCompleted: {
      playerNum.value = Config.preferedPlayerNum;

      for (let k in Config.curScheme.banPkg) {
        Lua.call("UpdatePackageEnable", k, false);
      }
      Config.curScheme.banCardPkg.forEach(p => Lua.call("UpdatePackageEnable", p, false));
      Config.curScheme = Config.curScheme;
    }
  }

  Rectangle {
    id: buttonBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    height: 56 - 8
    color: "transparent"
    RowLayout {
      width: parent.width * 0.5
      height: parent.height
      anchors.centerIn: parent
      // anchors.rightMargin: 8
      spacing: 16
      W.ButtonContent {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        text: Lua.tr("OK")
        // enabled: !(warning.visible)
        onClicked: {
          Config.saveConf();
          root.finish();
          App.setBusy(true);
          let k, arr;

          let disabledGenerals = [];
          for (k in Config.curScheme.banPkg) {
            arr = Config.curScheme.banPkg[k];
            if (arr.length !== 0) {
              const generals = Lua.call("GetGenerals", k);
              if (generals.length !== 0) {
                disabledGenerals.push(...generals.filter(g => !arr.includes(g)));
              }
            }
          }
          for (k in Config.curScheme.normalPkg) {
            arr = Config.curScheme.normalPkg[k] ?? [];
            if (arr.length !== 0)
            disabledGenerals.push(...arr);
          }

          let disabledPack = Config.curScheme.banCardPkg.slice();
          for (k in Config.curScheme.banPkg) {
            if (Config.curScheme.banPkg[k].length === 0)
            disabledPack.push(k);
          }
          Config.serverHiddenPacks.forEach(p => {
            if (!disabledPack.includes(p)) {
              disabledPack.push(p);
            }
          });

          const gameMode = Config.preferedMode;
          const boardgameName = Lua.evaluate(`Fk:getBoardGame('${gameMode}').name`);
          const boardgameConf = Db.getModeSettings(boardgameName);
          const gameModeConf = Db.getModeSettings(boardgameName + ":" + gameMode);

          ClientInstance.notifyServer(
            "CreateRoom",
            [
              roomName.text, playerNum.value,
              Config.preferredTimeout, {
                gameMode,
                roomName: roomName.text,
                password: roomPassword.text,
                _game: boardgameConf,
                _mode: gameModeConf,
                // FIXME 暂且拿他俩没办法
                disabledPack: boardgameName === "lunarltk" ? disabledPack : [],
                disabledGenerals: boardgameName === "lunarltk" ? disabledGenerals : [],
              }
            ]
          );
        }
      }

      W.ButtonContent {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        text: Lua.tr("Cancel")
        onClicked: {
          root.finish();
        }
      }
    }
  }

  function refreshGameMode(gameMode) {
    const data = Lua.fn(`function(mode)
      local m = Fk.game_modes[mode]
      return {
        minPlayer = m.minPlayer,
        maxPlayer = m.maxPlayer,
      }
    end`)(gameMode);
    playerNum.from = data.minPlayer;
    playerNum.to = data.maxPlayer;
  }
}
