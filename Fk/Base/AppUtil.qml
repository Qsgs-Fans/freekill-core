pragma Singleton
import QtQuick
import Fk

// 一些Qml代码可能常用到的封装函数 省得写一堆notify

QtObject {
  function enterNewPage(uri, name) {
    Mediator.notify(null, Command.PushPage, Qt.createComponent(uri, name))
  }

  function quitPage() {
    Mediator.notify(null, Command.PopPage, null);
  }

  function showToast(s: string) {
    Mediator.notify(null, Command.ShowToast, s);
  }

  function setBusy(v: bool) {
    Mediator.notify(null, Command.SetBusyUI, v);
  }
}
