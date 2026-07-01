import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Item {
    id: page

    required property var rootItem

    clip: true
    Layout.fillWidth: true
    Layout.fillHeight: true

    component CpuSummaryRow: RowLayout {
        property string label: ""
        property string value: ""
        property color markerColor: Kirigami.Theme.positiveTextColor
        property bool showMarker: true

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 2
            opacity: showMarker ? 1 : 0
            color: markerColor
        }

        Controls.Label {
            text: label
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Controls.Label {
            text: value
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.4
            clip: true
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.largeSpacing

                Local.RingGauge {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                    value: page.rootItem.sensorPercent(page.rootItem.cpuUsageSensor)
                    label: i18nc("@label", "CPU")
                    accentColor: Kirigami.Theme.positiveTextColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        Layout.fillWidth: true

                        Controls.Label {
                            text: i18nc("@label", "CPU Usage")
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        Controls.Label {
                            text: page.rootItem.sensorText(page.rootItem.cpuUsageSensor)
                            color: Kirigami.Theme.positiveTextColor
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                            font.weight: Font.DemiBold
                        }
                    }

                    CpuSummaryRow {
                        label: i18nc("@label", "Logical CPUs")
                        value: page.rootItem.sensorText(page.rootItem.cpuCountSensor)
                        showMarker: false
                    }

                    CpuSummaryRow {
                        label: i18nc("@label", "Cores")
                        value: page.rootItem.sensorText(page.rootItem.cpuCoreCountSensor)
                        markerColor: Kirigami.Theme.positiveTextColor
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        Local.CpuCoreBars {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.6
            refreshInterval: Math.max(1000, page.rootItem.sensorUpdateRate)
        }

        Local.CpuBreakdown {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5.8
            refreshInterval: Math.max(1000, page.rootItem.sensorUpdateRate)
        }

        Local.TopApplicationList {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            metric: "cpu"
            limit: 5
            refreshInterval: Math.max(1500, page.rootItem.sensorUpdateRate * 2)
        }
    }
}
