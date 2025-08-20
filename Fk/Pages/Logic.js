// SPDX-License-Identifier: GPL-3.0-or-later

callbacks["UpdateAvatar"] = (jsonData) => {
  App.setBusy(false);
  Self.avatar = jsonData;
  App.showToast(Lua.tr("Update avatar done."));
}

callbacks["UpdatePassword"] = (jsonData) => {
  App.setBusy(false);
  if (jsonData === "1")
    App.showToast(Lua.tr("Update password done."));
  else
    App.showToast(Lua.tr("Old password wrong!"), 5000);
}
