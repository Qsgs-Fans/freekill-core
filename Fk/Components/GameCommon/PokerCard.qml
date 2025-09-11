import QtQuick

import Fk

BasicCard {
  id: root

  property string suit: "club"
  property int number: 7
  property string color: ""

  Image {
    id: suitItem
    visible: parent.known
    source: (parent.suit !== "" && parent.suit !== "nosuit") ?
      SkinBank.searchBuiltinPic("/image/card/suit/", parent.suit) : ""
    x: 3
    y: 19
    width: 21
    height: 17
  }

  Image {
    id: numberItem
    visible: parent.known
    source: (parent.suit != "" && parent.number > 0) ?
      SkinBank.searchBuiltinPic(`/image/card/number/${parent.getColor()}/`, parent.number) : ""
    x: 0
    y: 0
    width: 27
    height: 28
  }

  Image {
    id: colorItem
    visible: parent.known && (parent.suit === "" || parent.suit === "nosuit")
      //  && number <= 0 // <- FIXME: 需要区分“黑色有点数”和“无色有点数”
    source: (visible && parent.color !== "") ? SkinBank.CARD_SUIT_DIR + "/" + parent.color
                                      : ""
    x: 1
  }

  function getColor() {
    if (suit != "")
      return (suit == "heart" || suit == "diamond") ? "red" : "black";
    else return color;
  }
}
