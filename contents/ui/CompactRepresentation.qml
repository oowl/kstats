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

    RowLayout {
        id: row

        anchors.centerIn: parent
        height: parent.height
        spacing: Kirigami.Units.smallSpacing

        Local.BarStat {
            visible: Plasmoid.configuration.showCpu
            label: i18nc("@label", "CPU")
            value: rootItem.sensorText(rootItem.cpuUsageSensor)
            percent: rootItem.sensorPercent(rootItem.cpuUsageSensor)
            accentColor: Kirigami.Theme.positiveTextColor
        }

        Local.BarStat {
            visible: Plasmoid.configuration.showMemory
            label: i18nc("@label", "MEM")
            value: rootItem.sensorText(rootItem.memoryUsageSensor)
            percent: rootItem.sensorPercent(rootItem.memoryUsageSensor)
            accentColor: Kirigami.Theme.focusColor
        }

        Local.BarStat {
            visible: Plasmoid.configuration.showDisk
            label: i18nc("@label", "DSK")
            value: rootItem.sensorText(rootItem.diskUsageSensor)
            percent: rootItem.sensorPercent(rootItem.diskUsageSensor)
            accentColor: Kirigami.Theme.neutralTextColor
        }

        RowLayout {
            visible: Plasmoid.configuration.showNetwork
            spacing: Kirigami.Units.smallSpacing / 2
            Layout.alignment: Qt.AlignVCenter

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

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: compactMouse.containsMouse
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
            : "transparent"
        z: -1
    }

    MouseArea {
        id: compactMouse

        anchors.fill: parent
        hoverEnabled: true
        onClicked: rootItem.expanded = !rootItem.expanded
    }
}
