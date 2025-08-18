pragma Singleton
import QtQuick

QtObject {
  function call(funcName: string, ...params): variant {
    return Backend.callLuaFunction(funcName, [...params]);
  }

  // 为什么不能取eval
  function evaluate(lua: string): variant {
    return Backend.evalLuaExp(`return ${lua}`);
  }

  function tr(src: string): string {
    return Backend.translate(src);
  }
}
