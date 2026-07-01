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
    readonly property real labelWidth: Math.max(labelText.implicitWidth, stat.label.length <= 1 ? Kirigami.Units.gridUnit * 0.7 : Kirigami.Units.gridUnit * 1.25)
    readonly property real valueWidth: showMeter ? Kirigami.Units.gridUnit * 2.2 : Kirigami.Units.gridUnit * 3
    readonly property real meterWidth: showMeter ? 3 : 0
    readonly property real fixedWidth: labelWidth + valueWidth + (showMeter ? meterWidth + spacing * 2 : spacing)

    spacing: Math.max(1, Kirigami.Units.smallSpacing / 4)
    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: fixedWidth
    Layout.preferredWidth: fixedWidth
    Layout.maximumWidth: fixedWidth
    implicitWidth: fixedWidth

    Rectangle {
        visible: stat.showMeter
        Layout.minimumWidth: stat.meterWidth
        Layout.preferredWidth: stat.meterWidth
        Layout.maximumWidth: stat.meterWidth
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
        id: labelText

        text: stat.label
        color: stat.accentColor
        elide: Text.ElideRight
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: stat.labelWidth
        Layout.preferredWidth: stat.labelWidth
        Layout.maximumWidth: stat.labelWidth
    }

    Controls.Label {
        text: stat.value
        color: Kirigami.Theme.textColor
        elide: Text.ElideRight
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.features: { "tnum": 1 }
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: stat.valueWidth
        Layout.preferredWidth: stat.valueWidth
        Layout.maximumWidth: stat.valueWidth
    }
}
