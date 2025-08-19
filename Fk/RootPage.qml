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
    // If error occurs during loading initialItem
    //   the program will fall into "polish()" loop
    // initialItem: init
    anchors.fill: parent
  }

  /*
  Component { id: init; Init {} }
  Component { id: packageDownload; PackageDownload {} }
  Component { id: packageManage; PackageManage {} }
  Component { id: resourcePackManage; ResourcePackManage {} }
  Component { id: lobby; Lobby {} }
  Component { id: generalsOverview; GeneralsOverview {} }
  Component { id: cardsOverview; CardsOverview {} }
  Component { id: modesOverview; ModesOverview {} }
  Component { id: replay; Replay {} }
  Component { id: room; Room {} }
  Component { id: aboutPage; About {} }

  property alias generalsOverviewPage: generalsOverview
  property alias cardsOverviewPage: cardsOverview
  property alias modesOverviewPage: modesOverview
  property alias aboutPage: aboutPage
  property alias replayPage: replay
  */

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

  ToastManager {}

  Connections {
    target: Backend
    function onNotifyUI(command, jsonData) {
      if (command === "ErrorDialog") {
        errDialog.txt = jsonData;
        errDialog.open();
        return;
      }
      root.handleMessage(command, jsonData);
    }
  }

  function handleMessage(command, jsonData) {
    const cb = callbacks[command]
    if (typeof(cb) === "function") {
      cb(jsonData);
    } else {
      callbacks["ErrorMsg"]("Unknown command " + command + "!");
    }
  }

  Component.onCompleted: {
    Config.loadConf();
    confLoaded();

    tipList = Cpp.loadTips();
  }
}
