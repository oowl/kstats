import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksysguard.sensors 1.0

// KStats – a KDE Plasma 6 panel widget inspired by exelban/stats.
// Shows a compact status strip in the panel; click opens a detailed popup.
PlasmoidItem {
    id: root

    // Show the compact strip by default (panel mode).
    preferredRepresentation: compactRepresentation

    // Sensor poll cadence in milliseconds (2 s is a reasonable default).
    readonly property int sensorUpdateInterval: 2000

    // ── Sensors ──────────────────────────────────────────────────────────────

    Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: root.sensorUpdateInterval
    }

    Sensor {
        id: memUsedSensor
        sensorId: "memory/physical/used"
        updateRateLimit: root.sensorUpdateInterval
    }

    Sensor {
        id: memTotalSensor
        sensorId: "memory/physical/total"
        updateRateLimit: 60000
    }

    Sensor {
        id: diskReadSensor
        sensorId: "disk/all/read"
        updateRateLimit: root.sensorUpdateInterval
    }

    Sensor {
        id: diskWriteSensor
        sensorId: "disk/all/write"
        updateRateLimit: root.sensorUpdateInterval
    }

    Sensor {
        id: netDownloadSensor
        sensorId: "network/all/download"
        updateRateLimit: root.sensorUpdateInterval
    }

    Sensor {
        id: netUploadSensor
        sensorId: "network/all/upload"
        updateRateLimit: root.sensorUpdateInterval
    }

    // ── Formatting helpers ────────────────────────────────────────────────

    // Returns a percentage string, e.g. "42%", or "–" when unavailable.
    function formatPercent(value) {
        if (value === undefined || value === null || isNaN(value)) {
            return "–"
        }
        return Math.round(value) + "%"
    }

    // Human-readable byte count: B / K / M / G / T with one decimal place.
    function formatBytes(bytes) {
        if (bytes === undefined || bytes === null || isNaN(bytes) || bytes < 0) {
            return "0 B"
        }
        const units = ["B", "K", "M", "G", "T"]
        let i = 0
        let v = bytes
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024
            i++
        }
        return (i === 0 ? Math.round(v).toString() : v.toFixed(1)) + " " + units[i]
    }

    // Byte rate: formatBytes + "/s".
    function formatRate(bytesPerSec) {
        return formatBytes(bytesPerSec) + "/s"
    }

    // ── Compact representation – the always-visible panel strip ───────────
    //
    // Defined inline so that sensor ids (cpuSensor, etc.) and helpers
    // (formatPercent, etc.) defined on root are in scope.

    compactRepresentation: Component {
        MouseArea {
            implicitWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
            implicitHeight: compactRow.implicitHeight

            // Toggle the dropdown.
            onClicked: root.expanded = !root.expanded

            RowLayout {
                id: compactRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 3

                PlasmaComponents.Label {
                    text: "CPU " + root.formatPercent(cpuSensor.value)
                }

                PlasmaComponents.Label {
                    text: "MEM " + root.formatBytes(memUsedSensor.value)
                }

                PlasmaComponents.Label {
                    text: "DSK ↓" + root.formatRate(diskReadSensor.value) +
                          " ↑" + root.formatRate(diskWriteSensor.value)
                }

                PlasmaComponents.Label {
                    text: "NET ↓" + root.formatRate(netDownloadSensor.value) +
                          " ↑" + root.formatRate(netUploadSensor.value)
                }
            }
        }
    }

    // ── Full representation – the click-to-open dropdown popup ───────────

    fullRepresentation: Component {
        ColumnLayout {
            Layout.minimumWidth:  Kirigami.Units.gridUnit * 20
            Layout.preferredWidth: Kirigami.Units.gridUnit * 24
            Layout.minimumHeight: implicitHeight

            spacing: Kirigami.Units.largeSpacing

            // ── Title ───────────────────────────────────────────────────

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: "System Statistics"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.Theme.disabledTextColor
                opacity: 0.4
            }

            // ── CPU ─────────────────────────────────────────────────────

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: "CPU"
                    font.bold: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                }
                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: cpuSensor.value || 0
                }
                PlasmaComponents.Label {
                    text: root.formatPercent(cpuSensor.value)
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                }
            }

            // ── Memory ──────────────────────────────────────────────────

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: "Memory"
                    font.bold: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                }
                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: memTotalSensor.value > 0 ? memTotalSensor.value : 1
                    value: memUsedSensor.value || 0
                }
                PlasmaComponents.Label {
                    text: root.formatBytes(memUsedSensor.value)
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: "Total: " + root.formatBytes(memTotalSensor.value)
                color: Kirigami.Theme.disabledTextColor
                horizontalAlignment: Text.AlignRight
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.Theme.disabledTextColor
                opacity: 0.4
            }

            // ── Disk I/O ────────────────────────────────────────────────

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label { text: "Disk Read";  font.bold: true }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.formatRate(diskReadSensor.value)
                    horizontalAlignment: Text.AlignRight
                }

                PlasmaComponents.Label { text: "Disk Write"; font.bold: true }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.formatRate(diskWriteSensor.value)
                    horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.Theme.disabledTextColor
                opacity: 0.4
            }

            // ── Network I/O ─────────────────────────────────────────────

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label { text: "Download"; font.bold: true }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.formatRate(netDownloadSensor.value)
                    horizontalAlignment: Text.AlignRight
                }

                PlasmaComponents.Label { text: "Upload";   font.bold: true }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.formatRate(netUploadSensor.value)
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Spacer so content stays top-aligned when the popup is tall.
            Item { Layout.fillHeight: true }
        }
    }
}
