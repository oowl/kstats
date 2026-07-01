import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "." as Local

Item {
    id: compact

    required property var rootItem

    Layout.minimumWidth: Math.max(Kirigami.Units.gridUnit * 4, row.implicitWidth)
    Layout.minimumHeight: Kirigami.Units.gridUnit
    Layout.preferredWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
    Layout.maximumWidth: Kirigami.Units.gridUnit * 28

    implicitWidth: Layout.preferredWidth
    implicitHeight: Layout.preferredHeight

    component ClickTarget: Item {
        id: target

        property int tabIndex: 0
        property color accentColor: Kirigami.Theme.highlightColor
        default property alias content: contentRow.data
        readonly property real horizontalPadding: Kirigami.Units.smallSpacing
        readonly property bool active: compact.rootItem.selectedTab === tabIndex && compact.rootItem.expanded

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: contentRow.implicitWidth + horizontalPadding * 2
        Layout.preferredHeight: compact.height
        implicitWidth: Layout.preferredWidth
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
            spacing: Kirigami.Units.smallSpacing / 2
        }

        MouseArea {
            id: targetMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: compact.rootItem.openTab(target.tabIndex)
        }
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        height: parent.height
        spacing: Kirigami.Units.smallSpacing

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
