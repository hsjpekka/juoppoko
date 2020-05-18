import QtQuick 2.0
import Sailfish.Silica 1.0

// changing chart orientation dynamically does not work properly
// append({"barHeight": xx, "barColor": xx, "barLabel": xx, "sctn": xx})
SilicaListView {
    id: barChartView

    property real   barWidth: Theme.fontSizeMedium
    property alias  chartData: listData
    property color  labelColor: Theme.secondaryHighlightColor
    property real   labelFontSize: Theme.fontSizeExtraSmall
    property real   labelWidth: Theme.fontSizeMedium*1.5
    property real   scale: 1 // bar height = barValue*scale
    property color  sectionColor: Theme.highlightColor
    property real   sectionFontSize: Theme.fontSizeExtraSmall
    property var    sectionOrientation: orientation === ListView.Horizontal ? ListView.Vertical : ListView.Horizontal
    //property real   selectedBarHeight: 0
    //property string selectedBarLabel: ""

    signal barSelected(int barNr, real barValue, string barLabel)

    height: orientation === ListView.Horizontal ? 3*Theme.fontSizeMedium : 4*Theme.fontSizeMedium
    width: parent.width

    delegate: ListItem {
        id: barItem
        contentHeight: barChartView.orientation === ListView.Horizontal ?
                    barChartView.height : (itemLabel.height > barWidth? itemLabel.height: barWidth)
        width: barChartView.orientation === ListView.Horizontal ?
                   (labelWidth > barWidth? labelWidth : barWidth) : parent.width
        propagateComposedEvents: true

        property real   bValue: barValue
        property string bLabel: barLabel

        onClicked: {
            var i = barChartView.indexAt(mouseX+x,mouseY+y)
            barSelected(i, bValue, bLabel)
            mouse.accepted = false
            console.log("valittu " + i + ", korkeus " + bValue
                        + ", pylväs " + bLabel + ", rot " + barChartView.orientation +
                        ", label " + itemLabel.height + ", " + itemLabel.y + ", lista " + height)
        }

        Rectangle {
            id: chartBar
            height: barChartView.orientation === ListView.Horizontal ? barItem.bValue*scale : barWidth
            width: barChartView.orientation === ListView.Horizontal ? barWidth : barItem.bValue*scale
            color: barColor
            opacity: 1.0
            y: barChartView.orientation === ListView.Horizontal ?
                   itemLabel.y - height - Theme.paddingSmall : 0.5*(parent.contentHeight - height)
            x: barChartView.orientation === ListView.Horizontal ?
                   0.5*(parent.width - width) : itemLabel.x + itemLabel.width + Theme.paddingSmall
            //anchors {
            //    horizontalCenter: parent.horizontalCenter
            //    bottom: itemLabel.top
            //    bottomMargin: Theme.paddingSmall
            //}
        }

        Label {
            id: itemLabel
            text: barItem.bLabel
            font.pixelSize: labelFontSize
            horizontalAlignment: barChartView.orientation === ListView.Horizontal?
                                     Text.AlignHCenter : Text.AlignRight
            x: barChartView.orientation === ListView.Horizontal ?
                   0.5*(parent.width - width) : 0
            y: barChartView.orientation === ListView.Horizontal ?
                   barChartView.height - height : 0.5*(parent.contentHeight - height)

            width: barChartView.orientation === ListView.Horizontal? parent.width : labelWidth
            color: labelColor
        } //

    }//listitem

    section {
        property: "sect"

        delegate: Item {
            width: barChartView.orientation === ListView.Horizontal?
                       sectionLabel.height : parent.width
            height: barChartView.orientation === ListView.Horizontal?
                        barChartView.height : sectionLabel.height //+ Theme.paddingSmall
            z:1
            Label {
                id: sectionLabel
                text: section
                color: sectionColor
                font.pixelSize: sectionFontSize
                x: barChartView.orientation === ListView.Horizontal?
                       height : parent.width - width - Theme.horizontalPageMargin
                y: barChartView.orientation === ListView.Horizontal?
                       0 : 0//Theme.paddingSmall
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        angle: barChartView.orientation === ListView.Horizontal? 90 : 0
                    }
                ]
            }
        }

    }

    model: ListModel {
        // {"barValue", "barColor", "barLabel", "sect"}
        id: listData
    }

}
