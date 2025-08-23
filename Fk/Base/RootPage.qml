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

  property string sheduledDownload: ""

  signal confLoaded

  onBusyChanged: busyText = "";

  Image {
    source: Config.lobbyBg
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
  }

  FontLoader {
    id: fontLibian
    source: Cpp.path + "/fonts/FZLBGBK.ttf"
  }

  FontLoader {
    id: fontLi2
    source: Cpp.path + "/fonts/FZLE.ttf"
  }

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
    font.family: Config.libianName
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
      for (let i = mainStack.depth; i >= 0; i--) {
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

  function errorMessage(sender, data) {
    let log;
    try {
      const a = JSON.parse(data);
      log = qsTr(a[0]).arg(a[1]);
    } catch (e) {
      log = qsTr(data);
    }

    console.log("ERROR: " + log);
    App.showToast(log, 5000);
    busy = false;
  }

  function errorDialog(sender, data) {
    let log;
    try {
      const a = JSON.parse(data);
      log = qsTr(a[0]).arg(a[1]);
    } catch (e) {
      log = qsTr(data);
    }

    console.log("ERROR: " + log);
    Cpp.showDialog("warning", log, data);
    busy = false;
  }

  function setServerSettings(sender, data) {
    const [ motd, hiddenPacks, enableBots ] = data;
    Config.serverMotd = motd;
    Config.serverHiddenPacks = hiddenPacks;
    Config.serverEnableBot = enableBots;
  }

  function setBusy(sender, data) {
    busy = data;
  }

  function addTotalGameTime(sender, data) {
    Config.totalTime++;
  }

  function backToStart() {
    while (mainStack.depth > 1) {
      App.quitPage();
    }

    tryUpdatePackage();
  }

  function setDownloadData(sender, data) {
    sheduledDownload = data;
  }

  function tryUpdatePackage() {
    if (sheduledDownload !== "") {
      mainStack.push(Qt.createComponent("Fk.Pages.Common", "PackageDownload"));
      const downloadPage = mainStack.currentItem;
      downloadPage.setPackages(sheduledDownload);
      Pacman.loadSummary(JSON.stringify(sheduledDownload), true);
      sheduledDownload = "";
    }
  }

  function chat(sender, data) {
    // jsonData: { string userName, string general, string time, string msg }
    const current = mainStack.currentItem;  // lobby or room
    const pid = data.sender;
    const userName = data.userName;
    const general = Lua.tr(data.general);
    const time = data.time;
    const msg = data.msg;

    if (Config.blockedUsers.indexOf(userName) !== -1) {
      return;
    }

    let text;
    if (general === "")
    text = `<font color="#3598E8">[${time}] ${userName}:</font> ${msg}`;
    else
    text = `<font color="#3598E8">[${time}] ${userName}` +
    `(${general}):</font> ${msg}`;

    current.addToChat(pid, data, text);
  }


  Component.onCompleted: {
    Config.loadConf();
    confLoaded();

    tipList = Cpp.loadTips();

    addCallback(Command.PushPage, pushPage);
    addCallback(Command.PopPage, popPage);
    addCallback(Command.ShowToast, showToast);
    addCallback(Command.SetBusyUI, setBusy);

    addCallback(Command.ErrorMsg, errorMessage);
    addCallback(Command.ErrorDlg, errorDialog);
    // 此为cpp手误 不加入Command
    addCallback("ErrorDialog", errorDialog);

    addCallback(Command.SetServerSettings, setServerSettings);
    addCallback(Command.AddTotalGameTime, addTotalGameTime);

    addCallback(Command.UpdatePackage, setDownloadData);
    addCallback(Command.BackToStart, backToStart);

    // FIXME 我偷懒了
    addCallback(Command.Chat, chat);

    mainStack.push(Qt.createComponent("Fk.Pages.Common", "Init"));
  }
}
