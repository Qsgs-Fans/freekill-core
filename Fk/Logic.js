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

callbacks["ServerMessage"] = (jsonData) => {
  const current = mainStack.currentItem;  // lobby or room
  current.sendDanmu('<font color="grey"><b>[Server] </b></font>' + jsonData);
}
