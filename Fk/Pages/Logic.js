// SPDX-License-Identifier: GPL-3.0-or-later

callbacks["UpdateAvatar"] = (jsonData) => {
  mainWindow.busy = false;
  Self.avatar = jsonData;
  toast.show(Lua.tr("Update avatar done."));
}

callbacks["UpdatePassword"] = (jsonData) => {
  mainWindow.busy = false;
  if (jsonData === "1")
    toast.show(Lua.tr("Update password done."));
  else
    toast.show(Lua.tr("Old password wrong!"), 5000);
}
