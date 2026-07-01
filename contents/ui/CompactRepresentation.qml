import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "." as Local

Item {
    id: compact

    required property var rootItem
    readonly property real horizontalPadding: Math.max(1, Kirigami.Units.smallSpacing / 2)
    readonly property real moduleSpacing: Math.max(1, Kirigami.Units.smallSpacing / 2)
    readonly property real innerSpacing: Math.max(1, Kirigami.Units.smallSpacing / 4)
    readonly property real minimumBarWidth: Kirigami.Units.gridUnit * 4
    readonly property real configuredBarLength: Number(Plasmoid.configuration.compactBarLength)
    readonly property real adaptiveBarLength: row.implicitWidth + horizontalPadding * 2
    readonly property real fixedWidth: Math.max(minimumBarWidth, configuredBarLength > 0 ? configuredBarLength : adaptiveBarLength)
    readonly property real contentWidth: Math.max(0, fixedWidth - horizontalPadding * 2)

    Layout.minimumWidth: fixedWidth
    Layout.minimumHeight: Kirigami.Units.gridUnit
    Layout.preferredWidth: fixedWidth
    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
    Layout.maximumWidth: fixedWidth

    implicitWidth: fixedWidth
    implicitHeight: Layout.preferredHeight
    clip: true

    component ClickTarget: Item {
        id: target

        property int tabIndex: 0
        property color accentColor: Kirigami.Theme.highlightColor
        default property alias content: contentRow.data
        readonly property real horizontalPadding: compact.horizontalPadding
        readonly property real fixedWidth: contentRow.implicitWidth + horizontalPadding * 2
        readonly property bool active: compact.rootItem.selectedTab === tabIndex && compact.rootItem.expanded

        Layout.alignment: Qt.AlignVCenter
        Layout.minimumWidth: fixedWidth
        Layout.preferredWidth: fixedWidth
        Layout.maximumWidth: fixedWidth
        Layout.preferredHeight: compact.height
        implicitWidth: fixedWidth
        implicitHeight: Layout.preferredHeight

        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: target.active
                ? Qt.rgba(target.accentColor.r, target.accentColor.g, target.accentColor.b, 0.16)
                : targetMouse.containsMouse
                    ? Qt.rgba(target.accentColor.r, target.accentColor.g, target.accentColor.b, 0.10)
                    : "transparent"
            border.width: target.active ? 1 : 0
            border.color: Qt.rgba(target.accentColor.r, target.accentColor.g, target.accentColor.b, 0.32)
        }

        RowLayout {
            id: contentRow

            anchors.centerIn: parent
            spacing: compact.innerSpacing
        }

        MouseArea {
            id: targetMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: compact.rootItem.toggleTab(target.tabIndex)
        }
    }

    RowLayout {
        id: row

        readonly property real fitScale: Math.min(1, compact.contentWidth / Math.max(1, implicitWidth))

        x: (compact.width - row.implicitWidth * fitScale) / 2
        y: (compact.height - row.implicitHeight * fitScale) / 2
        height: parent.height
        scale: fitScale
        transformOrigin: Item.TopLeft
        spacing: compact.moduleSpacing

        ClickTarget {
            visible: Plasmoid.configuration.showCpu
            accentColor: Kirigami.Theme.positiveTextColor
            tabIndex: 0

            Local.BarStat {
                label: i18nc("@label", "CPU")
                value: rootItem.sensorText(rootItem.cpuUsageSensor)
                percent: rootItem.sensorPercent(rootItem.cpuUsageSensor)
                accentColor: Kirigami.Theme.positiveTextColor
            }
        }

        ClickTarget {
            visible: Plasmoid.configuration.showMemory
            accentColor: Kirigami.Theme.focusColor
            tabIndex: 1

            Local.BarStat {
                label: i18nc("@label", "MEM")
                value: rootItem.sensorText(rootItem.memoryUsageSensor)
                percent: rootItem.sensorPercent(rootItem.memoryUsageSensor)
                accentColor: Kirigami.Theme.focusColor
            }
        }

        ClickTarget {
            visible: Plasmoid.configuration.showDisk
            accentColor: Kirigami.Theme.neutralTextColor
            tabIndex: 4

            Local.BarStat {
                label: i18nc("@label", "DSK")
                value: rootItem.sensorText(rootItem.diskUsageSensor)
                percent: rootItem.sensorPercent(rootItem.diskUsageSensor)
                accentColor: Kirigami.Theme.neutralTextColor
            }
        }

        ClickTarget {
            visible: Plasmoid.configuration.showNetwork
            accentColor: Kirigami.Theme.visitedLinkColor
            tabIndex: 3

            Controls.Label {
                id: networkLabel

                text: i18nc("@label", "NET")
                color: Kirigami.Theme.visitedLinkColor
                elide: Text.ElideRight
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: Math.max(implicitWidth, Kirigami.Units.gridUnit * 1.25)
                Layout.preferredWidth: Math.max(implicitWidth, Kirigami.Units.gridUnit * 1.25)
                Layout.maximumWidth: Math.max(implicitWidth, Kirigami.Units.gridUnit * 1.25)
            }

            Local.BarStat {
                label: i18nc("@label download", "↓")
                value: rootItem.sensorText(rootItem.networkDownloadSensor)
                percent: 0
                showMeter: false
                accentColor: Kirigami.Theme.visitedLinkColor
            }

            Local.BarStat {
                label: i18nc("@label upload", "↑")
                value: rootItem.sensorText(rootItem.networkUploadSensor)
                percent: 0
                showMeter: false
                accentColor: Kirigami.Theme.visitedLinkColor
            }
        }
    }
}
