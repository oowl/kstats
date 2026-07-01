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
    readonly property bool hasConfiguredBarLength: configuredBarLength > 0
    readonly property real adaptiveBarLength: row.implicitWidth
    readonly property real fixedWidth: Math.max(minimumBarWidth, hasConfiguredBarLength ? configuredBarLength : adaptiveBarLength)
    readonly property real contentWidth: Math.max(0, hasConfiguredBarLength ? fixedWidth - horizontalPadding * 2 : fixedWidth)

    function networkRateNumber(text) {
        const value = String(text).trim();
        const match = value.match(/^(.*\S)\s+(\S+\/s)$/);
        return match ? match[1] : value;
    }

    function networkRateUnit(text) {
        const value = String(text).trim();
        const match = value.match(/^(.*\S)\s+(\S+\/s)$/);
        return match ? match[2] : "";
    }

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
                previewMode: "bar"
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

            ColumnLayout {
                id: networkRates

                readonly property real rateFontSize: Math.max(7, Kirigami.Theme.smallFont.pixelSize - 2)
                readonly property real arrowWidth: Math.ceil(networkArrowMetrics.width)
                readonly property real valueGap: Math.max(2, compact.innerSpacing)
                readonly property real unitGap: Math.max(2, compact.innerSpacing)
                readonly property real valuePadding: Math.max(2, Kirigami.Units.smallSpacing / 2)
                readonly property real valueWidth: Math.ceil(networkValueMetrics.width) + valuePadding
                readonly property real unitWidth: Math.ceil(networkUnitMetrics.width)
                readonly property real valueSlotWidth: valueWidth + valueGap
                readonly property real unitSlotWidth: unitWidth + unitGap
                readonly property real fixedWidth: arrowWidth + valueSlotWidth + unitSlotWidth
                readonly property real rowHeight: rateFontSize + 1

                spacing: 1
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: fixedWidth
                Layout.preferredWidth: fixedWidth
                Layout.maximumWidth: fixedWidth
                Layout.preferredHeight: rowHeight * 2 + spacing

                TextMetrics {
                    id: networkArrowMetrics

                    font.pixelSize: networkRates.rateFontSize
                    font.weight: Font.DemiBold
                    text: i18nc("@label upload", "↑")
                }

                TextMetrics {
                    id: networkValueMetrics

                    font.pixelSize: networkRates.rateFontSize
                    text: "999.9"
                }

                TextMetrics {
                    id: networkUnitMetrics

                    font.pixelSize: networkRates.rateFontSize
                    text: "MiB/s"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: networkRates.rowHeight
                    spacing: 0

                    Controls.Label {
                        text: i18nc("@label upload", "↑")
                        color: Kirigami.Theme.visitedLinkColor
                        font.pixelSize: networkRates.rateFontSize
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        Layout.minimumWidth: networkRates.arrowWidth
                        Layout.preferredWidth: networkRates.arrowWidth
                        Layout.maximumWidth: networkRates.arrowWidth
                        Layout.preferredHeight: networkRates.rowHeight
                    }

                    Controls.Label {
                        text: compact.networkRateNumber(rootItem.sensorText(rootItem.networkUploadSensor))
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        font.pixelSize: networkRates.rateFontSize
                        font.features: { "tnum": 1 }
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: networkRates.valueGap
                        Layout.minimumWidth: networkRates.valueSlotWidth
                        Layout.preferredWidth: networkRates.valueSlotWidth
                        Layout.maximumWidth: networkRates.valueSlotWidth
                        Layout.preferredHeight: networkRates.rowHeight
                    }

                    Controls.Label {
                        text: compact.networkRateUnit(rootItem.sensorText(rootItem.networkUploadSensor))
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        font.pixelSize: networkRates.rateFontSize
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: networkRates.unitGap
                        Layout.minimumWidth: networkRates.unitSlotWidth
                        Layout.preferredWidth: networkRates.unitSlotWidth
                        Layout.maximumWidth: networkRates.unitSlotWidth
                        Layout.preferredHeight: networkRates.rowHeight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: networkRates.rowHeight
                    spacing: 0

                    Controls.Label {
                        text: i18nc("@label download", "↓")
                        color: Kirigami.Theme.visitedLinkColor
                        font.pixelSize: networkRates.rateFontSize
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        Layout.minimumWidth: networkRates.arrowWidth
                        Layout.preferredWidth: networkRates.arrowWidth
                        Layout.maximumWidth: networkRates.arrowWidth
                        Layout.preferredHeight: networkRates.rowHeight
                    }

                    Controls.Label {
                        text: compact.networkRateNumber(rootItem.sensorText(rootItem.networkDownloadSensor))
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        font.pixelSize: networkRates.rateFontSize
                        font.features: { "tnum": 1 }
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: networkRates.valueGap
                        Layout.minimumWidth: networkRates.valueSlotWidth
                        Layout.preferredWidth: networkRates.valueSlotWidth
                        Layout.maximumWidth: networkRates.valueSlotWidth
                        Layout.preferredHeight: networkRates.rowHeight
                    }

                    Controls.Label {
                        text: compact.networkRateUnit(rootItem.sensorText(rootItem.networkDownloadSensor))
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        font.pixelSize: networkRates.rateFontSize
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: networkRates.unitGap
                        Layout.minimumWidth: networkRates.unitSlotWidth
                        Layout.preferredWidth: networkRates.unitSlotWidth
                        Layout.maximumWidth: networkRates.unitSlotWidth
                        Layout.preferredHeight: networkRates.rowHeight
                    }
                }
            }
        }
    }
}
