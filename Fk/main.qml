import QtQuick
import QtQuick.Dialogs
import QtQuick.Window
import Fk

Window {
  id: root
  width: 1200
  height: 540
  minimumWidth: 200
  minimumHeight: 90
  visible: true

  title: qsTr("FreeKill") + " v" + Cpp.version

  onWidthChanged: Config.winWidth = width;
  onHeightChanged: Config.winHeight = height;

  RootPage {
    id: mainWindow

    width: (parent.width / parent.height < 1200 / 540) ? 1200 : 540 * parent.width / parent.height
    height: (parent.width / parent.height > 1200 / 540) ? 540 : 1200 * parent.height / parent.width
    scale: parent.width / width
    anchors.centerIn: parent

    onScaleChanged: Config.winScale = scale;
    onConfLoaded: {
      if (Cpp.os != "Android") {
        root.width = Config.winWidth;
        root.height = Config.winHeight;
      }
    }
  }

  MessageDialog {
    id: exitMessageDialog
    title: root.title
    informativeText: qsTr("Are you sure to exit?")
    buttons: MessageDialog.Ok | MessageDialog.Cancel
    onButtonClicked: function (button, role) {
      switch (button) {
        case MessageDialog.Ok: {
          mainWindow.closing = true;
          Config.saveConf();
          Cpp.quitLobby(false);
          root.close();
          break;
        }
        case MessageDialog.Cancel: {
          exitMessageDialog.close();
        }
      }
    }
  }

  Shortcut {
    sequences: [ "F11", "Ctrl+F", "Alt+Return" ]
    onActivated: {
      if (root.visibility === Window.FullScreen)
        root.showNormal();
      else
        root.showFullScreen();
    }
  }

  onClosing: (closeEvent) => {
    if (!mainWindow.closing) {
      closeEvent.accepted = false;
      exitMessageDialog.open();
    }
  }
}
