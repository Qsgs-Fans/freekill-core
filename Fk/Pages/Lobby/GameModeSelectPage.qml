import QtQuick

import Fk
import Fk.Widgets as W

Item {
  id: root

  property string gameMode

  W.PreferencePage {
    anchors.fill: parent
    groupWidth: width * 0.8

    W.PreferenceGroup {
      W.ComboRow {
        id: gameModeCombo
        title: Lua.tr("Game Mode")
        textRole: "name"
        model: ListModel {
          id: gameModeList
        }

        onCurrentValueChanged: {
          const data = currentValue;

          root.gameMode = currentValue.orig_name;
          Config.preferedMode = data.orig_name;
        }
      }
    }
  }

  Component.onCompleted: {
    gameMode = Config.preferedMode;

    const mode_data = Lua.call("GetGameModes");
    let i = 0;
    for (const d of mode_data) {
      gameModeList.append(d);
      if (d.orig_name === gameMode) {
        gameModeCombo.setCurrentIndex(i);
      }
      i += 1;
    }

  }
}
