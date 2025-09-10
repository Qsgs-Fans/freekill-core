import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import Fk
import Fk.Widgets as W
import Fk.Pages.Lobby as L

W.PageBase {
  id: root

  required property var gameContent
  readonly property real gameScale: 0.7

  Rectangle {
    id: gameContentRect
    //color: "#60ED1E1E"
    color: "transparent"
    visible: false
    width: parent.width * root.gameScale
    height: parent.height * root.gameScale
    anchors.centerIn: parent

    W.TapHandler {
      onTapped: root.closeOverlay();
    }
  }

  Button {
    id: menuButton
    anchors.top: parent.top
    anchors.topMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: 12
    text: Lua.tr("Menu")
    onClicked: {
      if (menuContainer.visible){
        root.closeOverlay();
        menuContainer.close();
      } else {
        root.openOverlay();
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

      MenuItem {
        id: surrenderButton
        enabled: !Config.observing && !Config.replaying
        text: Lua.tr("Surrender")
        icon.source: Cpp.path + "/image/misc/surrender"
        onClicked: {
          if (Lua.evaluate('Self.dead and (Self.rest <= 0)')) {
            return;
          }
          const surrenderCheck = Lua.call('CheckSurrenderAvailable');
          if (!surrenderCheck.length) {
            surrenderDialog.informativeText =
            Lua.tr('Surrender is disabled in this mode');
          } else {
            surrenderDialog.informativeText = surrenderCheck
            .map(str => `${Lua.tr(str.text)}（${str.passed ? '✓' : '✗'}）`)
            .join('<br>');
          }
          surrenderDialog.open();
        }
      }
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

  MessageDialog {
    id: surrenderDialog
    title: Lua.tr("Surrender")
    informativeText: ''
    buttons: MessageDialog.Ok | MessageDialog.Cancel
    onButtonClicked: function (button, role) {
      switch (button) {
        case MessageDialog.Ok: {
          const surrenderCheck =
            Lua.call('CheckSurrenderAvailable');
          if (surrenderCheck.length &&
                !surrenderCheck.find(check => !check.passed)) {

            Cpp.notifyServer("PushRequest", [
              "surrender", true
            ].join(","));
          }
          surrenderDialog.close();
          break;
        }
        case MessageDialog.Cancel: {
          surrenderDialog.close();
        }
      }
    }
  }

  W.PopupLoader {
    id: settingsDialog
    padding: 0
    width: Config.winWidth * 0.8
    height: Config.winHeight * 0.9
    anchors.centerIn: parent
    background: Rectangle {
      color: "#EEEEEEEE"
      radius: 5
      border.color: "#A6967A"
      border.width: 1
    }

    sourceComponent: RowLayout {
      W.SideBarSwitcher {
        id: settingBar
        Layout.preferredWidth: 200
        Layout.fillHeight: true
        model: ListModel {
          ListElement { name: "Audio Settings" }
          ListElement { name: "Control Settings" }
        }
      }

      SwipeView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        interactive: false
        orientation: Qt.Vertical
        currentIndex: settingBar.currentIndex
        clip: true
        L.AudioSetting {}
        L.ControlSetting {}
      }
    }
  }

  function openOverlay() {
    gameContent.scale = root.gameScale;

    gameContentRect.visible = true;
  }

  function closeOverlay() {
    gameContent.scale = 1;

    gameContentRect.visible = false;
  }
}
