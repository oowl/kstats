import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

RowLayout {
    id: stat

    property string label
    property string value
    property real percent: 0
    property color accentColor: Kirigami.Theme.highlightColor
    property bool showMeter: true

    spacing: Kirigami.Units.smallSpacing / 2
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        visible: stat.showMeter
        Layout.preferredWidth: 3
        Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit, stat.height - Kirigami.Units.smallSpacing)
        radius: width / 2
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0, Math.min(100, stat.percent)) / 100
            radius: parent.radius
            color: stat.accentColor
        }
    }

    Controls.Label {
        text: stat.label
        color: stat.accentColor
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignRight
    }

    Controls.Label {
        text: stat.value
        color: Kirigami.Theme.textColor
        elide: Text.ElideRight
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.features: { "tnum": 1 }
        Layout.maximumWidth: Kirigami.Units.gridUnit * 4.5
    }
}
