import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Rectangle {
    id: tile

    property string title
    property string iconName
    property string valueText
    property real percent: 0
    property color accentColor: Kirigami.Theme.highlightColor
    property bool compact: false
    property bool showChart: true

    radius: Kirigami.Units.cornerRadius
    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.55)
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
    border.width: 1

    implicitWidth: compact ? Kirigami.Units.gridUnit * 3 : Kirigami.Units.gridUnit * 8
    implicitHeight: compact ? Kirigami.Units.gridUnit * 2 : Kirigami.Units.gridUnit * 5

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: compact ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
        spacing: compact ? 1 : Kirigami.Units.smallSpacing / 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing / 2

            Kirigami.Icon {
                source: tile.iconName
                visible: !tile.compact
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
            }

            Controls.Label {
                text: tile.title
                elide: Text.ElideRight
                font.pixelSize: tile.compact ? Kirigami.Theme.smallFont.pixelSize : Kirigami.Theme.defaultFont.pixelSize
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
        }

        Controls.Label {
            text: tile.valueText
            elide: Text.ElideRight
            maximumLineCount: tile.compact ? 2 : 2
            wrapMode: Text.Wrap
            lineHeight: 0.92
            font.pixelSize: tile.compact ? Kirigami.Theme.smallFont.pixelSize : Kirigami.Theme.defaultFont.pixelSize * 1.15
            Layout.fillWidth: true
        }

        Local.Sparkline {
            visible: tile.showChart && !tile.compact
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit
            sampleValue: tile.percent
            lineColor: tile.accentColor
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            radius: height / 2
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(100, tile.percent)) / 100
                radius: parent.radius
                color: tile.accentColor

                Behavior on width {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
