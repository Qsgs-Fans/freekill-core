import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import Fk
import Fk.Widgets as W

Item {
  id: root

  readonly property real gameScale: 0.7
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
    id: replayControls
    visible: Config.replaying
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 20
    anchors.horizontalCenter: parent.horizontalCenter
    width: childrenRect.width + 8
    height: childrenRect.height + 8

    color: "#88EEEEEE"
    radius: 4

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

      Button {
        text: Lua.tr("Speed Down")
        onClicked: Backend.controlReplayer("slowdown");
      }

      Text {
        font.pixelSize: 20
        font.bold: true
        text: "x" + replayerSpeed;
      }

      Button {
        text: Lua.tr("Speed Up")
        onClicked: Backend.controlReplayer("speedup");
      }

      Button {
        property bool running: true
        text: Lua.tr(running ? "Pause" : "Resume")
        onClicked: {
          running = !running;
          Backend.controlReplayer("toggle");
        }
      }
    }
  }

  Rectangle {
    id: shadowRect
    color: "black"
    width: parent.width * root.gameScale
    height: parent.height * root.gameScale
    anchors.centerIn: parent

    layer.enabled: true
    layer.effect: DropShadow {
      transparentBorder: true
      radius: 12
      samples: 16
      color: "#000000"
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
    } else if (overlay.canHandleCommand(cmd)) {
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
