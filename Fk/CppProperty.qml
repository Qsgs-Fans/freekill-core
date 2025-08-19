pragma Singleton
import QtQuick
import Fk

// 这个文件的警告就别管了。本身就是给C++乱用contextProperty擦屁股

QtObject {
  property string version: FkVersion
  property string os: OS
  property string path: AppPath
  property string locale: SysLocale
  property bool debug: Debugging

  function quitLobby(v) {
    Backend.quitLobby(v);
  }

  function loadTips(): list<string> {
    const tips = Backend.loadTips();
    return tips.trim().split("\n");
  }

  function loadConf(): string {
    return Backend.loadConf();
  }

  function saveConf(s: string) {
    Backend.saveConf(s);
  }

  function setVolume(v: real) {
    Backend.volume = v;
  }

  function volume(): real {
    return Backend.volume;
  }

  function sqlquery(s: string): list {
    return ClientInstance.execSql(s);
  }
}
