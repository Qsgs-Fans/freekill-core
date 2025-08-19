import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Fk
import Fk.Widgets as W

W.PageBase {
  id: root

  property list<string> tipList: []

  property bool busy: false
  property string busyText: ""
  property bool closing: false

  signal confLoaded

  onBusyChanged: busyText = "";

  Image {
    source: Config.lobbyBg
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
  }

  FontLoader { id: fontLibian; source: Cpp.path + "/fonts/FZLBGBK.ttf" }
  FontLoader { id: fontLi2; source: Cpp.path + "/fonts/FZLE.ttf" }

  StackView {
    id: mainStack
    visible: !root.busy
    anchors.fill: parent
  }

  BusyIndicator {
    id: busyIndicator
    running: true
    anchors.centerIn: parent
    visible: root.busy === true
  }

  Text {
    anchors.top: busyIndicator.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 8
    visible: root.busy === true

    property int idx: 1
    text: root.tipList[idx - 1] ?? ""
    color: "#F0E5DA"
    font.pixelSize: 20
    font.family: fontLibian.name
    style: Text.Outline
    styleColor: "#3D2D1C"
    textFormat: Text.RichText
    width: parent.width * 0.7
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WrapAnywhere

    onVisibleChanged: idx = 0;

    Timer {
      running: parent.visible
      interval: 3600
      repeat: true
      onTriggered: {
        const oldIdx = parent.idx;
        while (parent.idx === oldIdx) {
          parent.idx = Math.floor(Math.random() * root.tipList.length) + 1;
        }
      }
    }
  }

  Item {
    visible: root.busy === true && root.busyText !== ""
    anchors.bottom: parent.bottom
    height: 32
    width: parent.width
    Rectangle {
      anchors.fill: parent
      color: "#88EEEEEE"
    }
    Text {
      anchors.centerIn: parent
      text: root.busyText
      font.pixelSize: 24
    }
  }

  Popup {
    id: errDialog
    property string txt: ""
    modal: true
    anchors.centerIn: parent
    width: Math.min(contentWidth + 24, Config.winWidth * 0.9)
    height: Math.min(contentHeight + 24, Config.winHeight * 0.9)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 12
    contentItem: Text {
      text: errDialog.txt
      wrapMode: Text.WordWrap

      W.TapHandler {
        onTapped: errDialog.close();
      }
    }
  }

  ToastManager {
    id: toast
  }

  Connections {
    target: Mediator
    function onCommandGot(sender, command, data) {
      for (let i = 0; i < mainStack.depth; i++) {
        const page = mainStack.get(i, StackView.DontLoad) as W.PageBase;
        if (!page) continue;
        if (page.canHandleCommand(command)) {
          page.handleCommand(sender, command, data);
          return;
        }
      }

      if (root.canHandleCommand(command)) {
        root.handleCommand(sender, command, data);
        return;
      }
      console.warn("Unknown command " + command + "!");
    }
  }

  function pushPage(sender, data) {
    mainStack.push(data);
  }

  function popPage(sender, data) {
    mainStack.pop();
  }

  function showToast(sender, data) {
    toast.show(data);
  }

  Component.onCompleted: {
    Config.loadConf();
    confLoaded();

    tipList = Cpp.loadTips();

    addCallback(Command.PushPage, pushPage)
    addCallback(Command.PopPage, popPage)
    addCallback(Command.ShowToast, showToast)

    mainStack.push(Qt.createComponent("Fk.Pages.Common", "Init"));
  }
}
