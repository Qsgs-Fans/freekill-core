// SPDX-License-Identifier: GPL-3.0-or-later

let callbacks = {};

callbacks["ServerDetected"] = (j) => {
  const serverDialog = mainStack.currentItem.serverDialog;
  if (!serverDialog) {
    return;
  }
  const item = serverDialog.item;
  if (item) {
    // App.showToast(qsTr("Detected Server %1").arg(j.slice(7)), 10000);
    item.addLANServer(j.slice(7))
  }
}

callbacks["GetServerDetail"] = (j) => {
  const [ver, icon, desc, capacity, count, addr] = JSON.parse(j);
  const serverDialog = mainStack.currentItem.serverDialog;
  if (!serverDialog) {
    return;
  }
  const item = serverDialog.item;
  if (item) {
    let [_addr, port] = addr.split(',');
    port = parseInt(port);
    item.updateServerDetail(_addr, port, [ver, icon, desc, capacity, count]);
  }
}

callbacks["UpdatePackage"] = (jsonData) => sheduled_download = jsonData;

callbacks["UpdateBusyText"] = (jsonData) => {
  mainWindow.busyText = jsonData;
}

callbacks["DownloadComplete"] = () => {
  App.setBusy(false);
  mainStack.currentItem.downloadComplete(); // should be pacman page
}

callbacks["SetDownloadingPackage"] = (name) => {
  const page = mainStack.currentItem;
  page.setDownloadingPackage(name);
}

callbacks["PackageDownloadError"] = (msg) => {
  const page = mainStack.currentItem;
  page.setDownloadError(msg);
}

callbacks["PackageTransferProgress"] = (data) => {
  const page = mainStack.currentItem;
  page.showTransferProgress(data);
}

callbacks["BackToStart"] = (jsonData) => {
  while (mainStack.depth > 1) {
    App.quitPage();
  }

  tryUpdatePackage();
}

callbacks["Chat"] = (data) => {
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

callbacks["ServerMessage"] = (jsonData) => {
  const current = mainStack.currentItem;  // lobby or room
  current.sendDanmu('<font color="grey"><b>[Server] </b></font>' + jsonData);
}
