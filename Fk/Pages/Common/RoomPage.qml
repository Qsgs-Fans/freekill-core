import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

import Fk
import Fk.Widgets as W
import Fk.Pages.Lobby as L

Item {
  id: root

  readonly property alias gameContent: gameLoader.item
  property alias gameComponent: gameLoader.sourceComponent

  property real replayerSpeed
  property int replayerElapsed
  property int replayerDuration

  Image {
    id: bg
    source: Config.lobbyBg
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop

    layer.enabled: true
    layer.effect: FastBlur {
      radius: 72
    }
  }

  Rectangle {
    id: bgRect
    anchors.fill: parent
    color: "#AFFFFFFF"
  }

  Rectangle {
    id: shadowRect
    color: "black"
    width: gameLoader.width
    height: gameLoader.height
    x: gameLoader.x
    y: gameLoader.y
    scale: gameLoader.scale

    layer.enabled: true
    layer.effect: DropShadow {
      transparentBorder: true
      radius: 12
      samples: 16
      color: "#000000"
    }
  }

  Item {
    id: topPanel
    height: parent.height * 0.1
    width: parent.width

    Text {
      anchors.centerIn: parent
      text: "点击游戏画面可退出菜单，继续操作"
      font.pixelSize: 16
    }
  }

  Item {
    id: bottomPanel
    height: parent.height * 0.1
    width: parent.width
    anchors.bottom: parent.bottom


    Rectangle {
      id: replayControls
      visible: Config.replaying
      anchors.centerIn: bottomPanel
      width: childrenRect.width + 8
      height: childrenRect.height + 8

      // color: "#88EEEEEE"
      // radius: 4
      color: 'transparent'

      RowLayout {
        x: 4; y: 4
        Text {
          font.pixelSize: 20
          font.bold: true
          text: {
            function addZero(temp) {
              if (temp < 10) return "0" + temp;
              else return temp;
            }
            const elapsedMin = Math.floor(replayerElapsed / 60);
            const elapsedSec = addZero(replayerElapsed % 60);
            const totalMin = Math.floor(replayerDuration / 60);
            const totalSec = addZero(replayerDuration % 60);

            return elapsedMin.toString() + ":" + elapsedSec + "/" + totalMin
            + ":" + totalSec;
          }
        }

        Switch {
          text: Lua.tr("Show All Cards")
          checked: Config.replayingShowCards
          onCheckedChanged: Config.replayingShowCards = checked;
        }

        Switch {
          text: Lua.tr("Speed Resume")
          checked: false
          onCheckedChanged: Backend.controlReplayer("uniform");
        }

        W.ButtonContent {
          Layout.preferredWidth: 40
          // text: Lua.tr("Speed Down")
          icon.source: "http://175.178.66.93/symbolic/actions/media-seek-backward-symbolic.svg"
          onClicked: Backend.controlReplayer("slowdown");
        }

        Text {
          font.pixelSize: 20
          font.bold: true
          text: "x" + replayerSpeed;
        }

        W.ButtonContent {
          Layout.preferredWidth: 40
          // text: Lua.tr("Speed Up")
          icon.source: "http://175.178.66.93/symbolic/actions/media-seek-forward-symbolic.svg"
          onClicked: Backend.controlReplayer("speedup");
        }

        W.ButtonContent {
          property bool running: true
          Layout.preferredWidth: 40
          // text: Lua.tr(running ? "Pause" : "Resume")
          icon.source: running ?
            "http://175.178.66.93/symbolic/actions/media-playback-pause-symbolic.svg" :
            "http://175.178.66.93/symbolic/actions/media-playback-start-symbolic.svg"
          onClicked: {
            running = !running;
            Backend.controlReplayer("toggle");
          }
        }
      }
    }
  }

  ColumnLayout {
    anchors.right: parent.right
    anchors.rightMargin: 20
    anchors.top: parent.top
    anchors.topMargin: parent.height * 0.1
    spacing: 16
    width: parent.width - shadowRect.width * 0.8 - 40 - 40
    // height: shadowRect.height * shadowRect.scale

    W.ButtonContent {
      id: quitButton
      text: Lua.tr("Quit")
      icon.source: "http://175.178.66.93/symbolic/actions/application-exit-rtl-symbolic.svg"
      font.bold: true
      Layout.fillWidth: true
      Layout.fillHeight: true
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

    W.ButtonContent {
      id: volumeButton
      text: Lua.tr("Settings")
      icon.source: "http://175.178.66.93/symbolic/categories/applications-system-symbolic.svg"
      font.bold: true
      Layout.fillWidth: true
      Layout.fillHeight: true
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

    W.ButtonContent {
      id: banSchemaButton
      text: "信息"
      icon.source: "http://175.178.66.93/symbolic/mimetypes/x-office-document-symbolic.svg"
      font.bold: true
      Layout.fillWidth: true
      Layout.fillHeight: true
      onClicked: {
        overviewLoader.overviewType = "GeneralPool";
        overviewDialog.open();
      }
    }

    W.ButtonContent {
      id: surrenderButton
      enabled: !Config.observing && !Config.replaying
      text: Lua.tr("Surrender")
      icon.source: Cpp.path + "/image/misc/surrender"
      font.bold: true
      Layout.fillWidth: true
      Layout.fillHeight: true
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


  Loader {
    id: gameLoader
    width: parent.width
    height: parent.height

    Behavior on x { NumberAnimation { duration: 150 } }
    Behavior on y { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150 } }

    Image {
      source: Config.roomBg
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
    }
  }

  RoomOverlay {
    id: overlay
    anchors.fill: parent
    gameContent: gameLoader
  }

  function canHandleCommand(cmd) {
    return gameContent.canHandleCommand(cmd) || overlay.canHandleCommand(cmd);
  }

  function handleCommand(sender, cmd, data) {
    if (gameContent.canHandleCommand(cmd)) {
      gameContent.handleCommand(sender, cmd, data);
    }
    if (overlay.canHandleCommand(cmd)) {
      overlay.handleCommand(sender, cmd, data);
    }
  }

  function enterLobby(sender, data) {
    App.quitPage(); // 退到等待页了，再退
    App.quitPage();

    App.setBusy(false);
    Cpp.notifyServer("RefreshRoomList", "");
    Config.saveConf();
  }

  Component.onCompleted: {
    overlay.addCallback(Command.EnterLobby, enterLobby);

    overlay.addCallback(Command.ReplayerDurationSet, (_, j) => {
      root.replayerDuration = parseInt(j);
    });
    overlay.addCallback(Command.ReplayerElapsedChange, (_, j) => {
      root.replayerElapsed = parseInt(j);
    });
    overlay.addCallback(Command.ReplayerSpeedChange, (_, j) => {
      root.replayerSpeed = parseFloat(j);
    });
  }
}
