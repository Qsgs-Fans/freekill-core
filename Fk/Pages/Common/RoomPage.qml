import QtQuick

import Fk
import Fk.Widgets as W

Item {
  id: root

  W.PageBase {
    id: gameContent
  }

  W.PageBase {
    id: overlay
    anchors.fill: parent
  }

  function canHandleCommand(cmd) {
    return gameContent.canHandleCommand(cmd) || overlay.canHandleCommand(cmd);
  }

  function handleCommand(sender, cmd, data) {
    if (gameContent.canHandleCommand(cmd)) {
      gameContent.handleCommand(sender, cmd, data);
    }
    if (overlay.canHandleCommand(cmd)) {
      gameContent.handleCommand(sender, cmd, data);
    }
  }
}
