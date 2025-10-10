// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

import Fk
import Fk.Widgets as W

Item {
  id: root
  anchors.fill: parent

  signal finish()

  W.SideBarSwitcher {
    id: bar
    width: 200
    height: parent.height
    model: ListModel {
      ListElement { name: "General Settings" }
      ListElement { name: "游戏模式选择" }
      ListElement { name: "游戏设置" }
      ListElement { name: "模式设置" }
      ListElement { name: "Package Settings" }
      ListElement { name: "Ban General Settings" }
    }
  }

  SwipeView {
    width: root.width - bar.width - 16
    x: bar.width + 16
    height: root.height
    interactive: false
    orientation: Qt.Vertical
    currentIndex: bar.currentIndex
    RoomGeneralSettings {
      id: roomGeneralSettings
    }
    GameModeSelectPage {
      onGameModeChanged: {
        roomGeneralSettings.refreshGameMode(gameMode);
        const getUIData = Lua.fn("GetUIDataOfSettings");
        const boardgameName = Lua.evaluate(`Fk:getBoardGame('${gameMode}').name`);

        const boardgameConf = Db.getModeSettings(boardgameName);
        const boardgameSettingsData = getUIData(gameMode, null, true);
        boardgameSettings.configName = boardgameName;
        boardgameSettings.config = boardgameConf;
        boardgameSettings.loadSettingsUI(boardgameSettingsData);

        const gameModeConf = Db.getModeSettings(boardgameName + ':' + gameMode);
        const gameSettingsData = getUIData(gameMode, null, false);
        gameModeSettings.configName = `${boardgameName}:${gameMode}`;
        gameModeSettings.config = gameModeConf;
        gameModeSettings.loadSettingsUI(gameSettingsData);
      }
    }
    LuaSettingsPage {
      id: boardgameSettings
    }
    LuaSettingsPage {
      id: gameModeSettings
    }
    Item {
      RoomPackageSettings {
        anchors.fill: parent
      }
    }
    BanGeneralSetting {}
  }
}
