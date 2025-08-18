pragma Singleton
import QtQuick

// 这个文件的警告就别管了。本身就是给C++乱用contextProperty擦屁股

QtObject {
  property string version: FkVersion
  property string os: OS
  property string locale: SysLocale
  property bool debug: Debugging

  function sqlquery(s: string): list<variant> {
    return ClientInstance.execSql(s);
  }
}
