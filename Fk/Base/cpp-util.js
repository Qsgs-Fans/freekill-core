// 搬家到了JS，因为没警告（虽然目前qmlls也没给补全）

const version = typeof FkVersion !== 'undefined' ? FkVersion : 'qml-test';
const os = typeof OS !== 'undefined' ? OS : 'linux';
const path = typeof AppPath !== 'undefined' ? AppPath : '/';
const locale = typeof SysLocale !== 'undefined' ? SysLocale : 'zh_CN';
const debug = typeof Debugging !== 'undefined' ? Debugging : true;

function notifyServer(command, data) {
  ClientInstance.notifyServer(command, data);
}

function replyToServer(data) {
  ClientInstance.replyToServer("", data);
}

function showDialog(type, log, data) {
  Backend.showDialog(type, log, data);
}

function quitLobby(v) {
  Backend.quitLobby(v);
}

function loadTips() {
  const tips = Backend.loadTips();
  return tips.trim().split("\n");
}

function loadConf() {
  return Backend.loadConf();
}

function saveConf(s) {
  Backend.saveConf(s);
}

function setVolume(v) {
  Backend.volume = v;
}

function volume() {
  return Backend.volume;
}

function sqlquery(s) {
  return ClientInstance.execSql(s);
}
