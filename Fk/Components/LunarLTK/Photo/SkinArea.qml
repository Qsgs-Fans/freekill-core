import QtQuick
import QtMultimedia
import QtQuick.Layouts
import QtQuick.Controls

import Fk
import Fk.Components.Common
import Fk.Components.GameCommon as Game
import Fk.Widgets as W
import Fk.Components.LunarLTK.Photo

Item {
  id: root
  property string source: ""
  property bool hasDeputy: false //是否使用dual这个功能还是相信后人智慧吧

  Loader {
    id: imgLoader
    anchors.fill: parent
    sourceComponent: {
      if (root.source.endsWith(".gif")) {
        return animated;
      } else if (root.source.endsWith(".mp4")) {
        return videoImg;
      } else {
        return staticImg;
      }
    }
  }

  Component {
    id: staticImg
    Image {
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      source: root.source
    }
  }

  Component {
    id: animated
    AnimatedImage {
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      source: root.source
      playing: true
    }
  }

  Component {
    id: videoImg
    Video {
      anchors.fill: parent
      source: root.source
      loops: MediaPlayer.Infinite
      fillMode: Image.PreserveAspectCrop
      muted: true

      Component.onCompleted: play()
    }
  }
}
