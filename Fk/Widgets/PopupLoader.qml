import QtQuick
import QtQuick.Controls

// 你游的定制Popup 为了沟槽的缩放功能设计
// 本体的宽高从realMainWin计算

Popup {
  id: root

  property alias item: loader.item
  property alias source: loader.source
  property alias sourceComponent: loader.sourceComponent

  clip: true

  Loader {
    id: loader
    anchors.centerIn: parent
    width: parent.width / mainWindow.scale
    height: parent.height / mainWindow.scale
    scale: mainWindow.scale
    clip: true
    onSourceChanged: {
      if (item === null) {
        return;
      }
      item.finish.connect(() => {
        root.close();
      });
    }
    onSourceComponentChanged: sourceChanged();
  }
}
