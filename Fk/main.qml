import QtQuick
import QtQuick.Window
import Fk

Window {
  width: 960
  height: 540
  minimumWidth: 160
  minimumHeight: 90
  visible: true

  title: qsTr("FreeKill") + " v" + Cpp.version

  // 唉兼容
  function lcall(funcName, ...params) {
    return Lua.call(funcName, ...params);
  }

  function leval(lua) {
    return Lua.evaluate(lua);
  }

  function luatr(src) {
    return Lua.tr(src);
  }

  function sqlquery(s) {
    return Cpp.sqlquery(s);
  }

}
