import QtQuick 2.0
import Sailfish.Silica 1.0

// changing chart orientation dynamically does not work properly
// append({"barHeight": xx, "barColor": xx, "barLabel": xx, "sctn": xx})
SilicaListView {
    id: barChartView

    property color labelColor: Theme.secondaryHighlightColor
    property real labelFontSize: Theme.fontSizeExtraSmall
    property real labelWidth: Theme.fontSizeMedium*2
    property color sectionColor: Theme.highlightColor
    property real sectionFontSize: Theme.fontSizeExtraSmall
    property var sectionOrientation: orientation === ListView.Horizontal ? ListView.Vertical : ListView.Horizontal
    property real barWidth: Theme.paddingMedium
    property real selectedBarHeight: 0
    property string selectedBarLabel: ""
    property alias chartData: listData
    property real horizontalBarX0: Theme.horizontalPageMargin + 2*Theme.fontSizeMedium

    height: orientation === ListView.Horizontal ? 3*Theme.fontSizeMedium : 4*Theme.fontSizeMedium
    width: parent.width

    delegate: ListItem {
        contentHeight: barChartView.orientation === ListView.Horizontal ?
                    barChartView.height :
                    (itemLabel.height > barWidth? itemLabel.height: barWidth)
        width: barChartView.orientation === ListView.Horizontal ?
                   (itemLabel.width > barWidth? itemLabel.width : barWidth) :
                   parent.width
        propagateComposedEvents: true
        onClicked: {
            var i = barChartView.indexAt(mouseX+x,mouseY+y)
            selectedBarHeight = chartBar.height
            selectedBarLabel = itemLabel.text
            mouse.accepted = false
            console.log("valittu " + i + ", korkeus " + selectedBarHeight
                        + ", pylväs " + selectedBarLabel + ", rot " + barChartView.orientation +
                        ", label " + itemLabel.height + ", " + itemLabel.y + ", lista " + height)
        }

        Rectangle {
            id: chartBar
            height: barChartView.orientation === ListView.Horizontal ? barHeight : barWidth
            width: barChartView.orientation === ListView.Horizontal ? barWidth : barHeight
            color: barColor
            opacity: 0.5
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
            text: barLabel
            font.pixelSize: labelFontSize
            horizontalAlignment: barChartView.orientation === ListView.Horizontal?
                                     Text.AlignHCenter : Text.AlignRight
            x: barChartView.orientation === ListView.Horizontal ?
                   0.5*(parent.width - width) : Theme.horizontalPageMargin
            y: barChartView.orientation === ListView.Horizontal ?
                   barChartView.height - height - Theme.paddingSmall : 0.5*(parent.contentHeight - height)

            width: barChartView.orientation === ListView.Horizontal? parent.width : labelWidth
            color: labelColor
        } //

    }//listitem

    section {
        property: "sctn"

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
        id: listData
    }

}
