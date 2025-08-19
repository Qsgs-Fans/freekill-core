// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Fk

Flickable {
  id: root
  flickableDirection: Flickable.AutoFlickIfNeeded
  clip: true
  contentHeight: layout.height
  property bool loading: false
  ScrollBar.vertical: ScrollBar {
    parent: root.parent
    anchors.top: root.top
    anchors.right: root.right
    anchors.bottom: root.bottom
  }

  ColumnLayout {
    id: layout
    anchors.top: parent.top
    anchors.topMargin: 8

    /*
    Switch {
      text: Lua.tr("Disable Extension")
    }
    */

    RowLayout {
      Text {
        text: Lua.tr("General Packages Help")
        font.bold: true
      }
      /*
      Button {
        text: Lua.tr("Select All")
        onClicked: {
          for (let i = 0; i < mods.count; i++) {
            const col = mods.itemAt(i);
            const gri = col.children[1];
            for (var j = 0; j < gri.children.length - 1; j++) { // 最后一个不是 CheckBox
              gri.children[j].checked = true;
            }
          }
        }
      }
      Button {
        text: Lua.tr("Revert Selection")
        onClicked: {
          for (let i = 0; i < mods.count; i++) {
            const col = mods.itemAt(i);
            const gri = col.children[1];
            for (var j = 0; j < gri.children.length - 1; j++) {
              gri.children[j].checked = !gri.children[j].checked;
            }
          }
        }
      }
      */
    }
/* 
    ColumnLayout {
      Repeater {
        id: mods
        model: ListModel {
          id: modList
        }
        Column {
          id: modColumn
          property bool pkgShown: Config.shownPkg.includes(name) // 记忆展开状态
          ButtonGroup {
            id: childPkg
            exclusive: false
            checkState: parentModBox.checkState
          }

          RowLayout {
            spacing: 8
            CheckBox {
              id: parentModBox
              text: Lua.tr(name)
              font.bold: true
              enabled: false
              checkState: childPkg.checkState
              Layout.minimumWidth: 100
            }
            ToolButton {
              text: (modColumn.pkgShown ? "➖" : "➕")
              onClicked: {
                modColumn.pkgShown = !modColumn.pkgShown
                const idx = Config.shownPkg.indexOf(name);
                if (idx === -1) {
                  Config.shownPkg.push(name);
                } else {
                  Config.shownPkg.splice(idx, 1);
                }
                Config.shownPkgChanged();
              }
              background: Rectangle {
                implicitWidth: 20
                implicitHeight: 20

                visible: parent.down || parent.checked || parent.highlighted || parent.visualFocus
                  || (parent.enabled && parent.hovered)
              }
            }
          }

          GridLayout {
            id: pkgListLayout
            columns: 4
            rowSpacing: -5
            visible: parent.pkgShown
            Behavior on opacity { OpacityAnimator { duration: 200 } }

            Repeater {
              id: pkgList
              model: JSON.parse(pkgs)

              CheckBox {
                text: Lua.tr(modelData)
                leftPadding: indicator.width
                ButtonGroup.group: childPkg
                // enabled: modelData !== "test_p_0" // 测试包不允许选择
                enabled: false // 此处不允许选择 前往武将一览
                checked: !Config.curScheme.banPkg[modelData] // 初始状态

                onCheckedChanged: {
                  if (!loading) {
                    checkPackage(modelData, checked);
                  }
                }
              }
            }
          }
        }
      }
    }
*/
    RowLayout {
      Text {
        text: Lua.tr("Card Packages")
        font.bold: true
      }
      Button {
        text: Lua.tr("Select All")
        onClicked: {
          for (let i = 0; i < cpacks.count; i++) {
            const item = cpacks.itemAt(i);
            item.checked = true;
          }
        }
      }
      Button {
        text: Lua.tr("Revert Selection")
        onClicked: {
          for (let i = 0; i < cpacks.count; i++) {
            const item = cpacks.itemAt(i);
            item.checked = !item.checked;
          }
        }
      }
    }

    GridLayout {
      columns: 4

      Repeater {
        id: cpacks
        model: ListModel {
          id: cpacklist
        }

        CheckBox {
          text: name
          checked: pkg_enabled

          onCheckedChanged: {
            const packs = Config.curScheme.banCardPkg;
            if (checked) {
              const idx = packs.indexOf(orig_name);
              if (idx !== -1) packs.splice(idx, 1);
            } else {
              packs.push(orig_name);
            }
            Lua.call("UpdatePackageEnable", orig_name, checked);
            Config.curSchemeChanged();
          }
        }
      }
    }
  }

  function checkPackage(orig_name, checked) {
    return;

    // const s = Config.curScheme;
    // if (!checked) {
    //   s.banPkg[orig_name] = [];
    //   delete s.normalPkg[orig_name];
    // } else {
    //   delete s.normalPkg[orig_name];
    //   delete s.banPkg[orig_name];
    // }
    // Lua.call("UpdatePackageEnable", orig_name, checked);
    // Config.curSchemeChanged();
  }

  Component.onCompleted: {
    loading = true;
    let orig;
    /*
    const g = Lua.call("GetAllGeneralPack");
    const _mods = Lua.call("GetAllModNames");
    const modData = Lua.call("GetAllMods");
    const packs = Lua.call("GetAllGeneralPack");
    _mods.forEach(name => {
      const pkgs = modData[name].filter(p => packs.includes(p)
        && !Config.serverHiddenPacks.includes(p));
      if (pkgs.length > 0)
        modList.append({ name: name, pkgs: JSON.stringify(pkgs) });
    });
    */

    const c = Lua.call("GetAllCardPack");
    for (orig of c) {
      if (Config.serverHiddenPacks.includes(orig)) {
        continue;
      }
      cpacklist.append({
        name: Lua.tr(orig),
        orig_name: orig,
        pkg_enabled: !Config.curScheme.banCardPkg.includes(orig),
      });
    }
    loading = false;
  }
}
