import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "." as Local

Item {
    id: page

    required property var rootItem
    property string cpuModel: ""
    property string temperatureSensorId: ""
    property string fanSensorId: ""
    property bool temperatureDiscoveryLocked: false
    property bool fanDiscoveryLocked: false
    readonly property bool hardwareDiscoveryLocked: temperatureDiscoveryLocked && fanDiscoveryLocked

    clip: true
    Layout.fillWidth: true
    Layout.fillHeight: true

    function cpuModelText() {
        return page.cpuModel.length > 0 ? page.cpuModel : i18nc("@info:status", "N/A");
    }

    function optionalSensorText(sensor, sensorId) {
        if (sensorId.length === 0) {
            return i18nc("@info:status", "N/A");
        }
        return page.rootItem.sensorText(sensor);
    }

    function parseCpuModel(text) {
        var fallback = "";
        var lines = String(text || "").split(/\r?\n/);
        for (var i = 0; i < lines.length; i++) {
            var separator = lines[i].indexOf(":");
            if (separator < 0) {
                continue;
            }

            var key = lines[i].slice(0, separator).trim().toLowerCase();
            var value = lines[i].slice(separator + 1).trim();
            if (value.length === 0) {
                continue;
            }

            if (key === "model name") {
                return value;
            }
            if ((key === "hardware" || key === "processor" || key === "cpu model") && fallback.length === 0) {
                fallback = value;
            }
        }

        return fallback;
    }

    function loadCpuModel() {
        cpuInfoCommand.exec("cat /proc/cpuinfo", function(result) {
            if (result.exitCode !== 0) {
                page.cpuModel = "";
                return;
            }
            page.cpuModel = page.parseCpuModel(result.stdout);
        });
    }

    function cleanName(value) {
        return String(value || "").trim();
    }

    function isTemplateSensorId(sensorId) {
        var id = String(sensorId || "");
        return id.indexOf("\\") >= 0
            || id.indexOf("[") >= 0
            || id.indexOf("]") >= 0
            || id.indexOf("(") >= 0
            || id.indexOf(")") >= 0
            || id.indexOf("*") >= 0
            || id.indexOf("+") >= 0;
    }

    function sensorSearchText(sensorId, pathNames) {
        return (String(sensorId || "") + " " + pathNames.join(" ")).toLowerCase();
    }

    function hasAny(text, needles) {
        for (var i = 0; i < needles.length; i++) {
            if (text.indexOf(needles[i]) >= 0) {
                return true;
            }
        }
        return false;
    }

    function hardwareScore(sensorId, pathNames, metric) {
        if (page.isTemplateSensorId(sensorId)) {
            return 0;
        }

        var text = page.sensorSearchText(sensorId, pathNames);
        if (page.hasAny(text, ["gpu", "graphics", "amdgpu", "radeon", "nvidia", "nouveau", "vram", "nvme", "ssd", "hdd", "disk", "drive", "battery"])) {
            return 0;
        }

        if (metric === "temperature") {
            if (page.hasAny(text, ["fan", "rpm", "voltage", "power", "clock", "frequency"])) {
                return 0;
            }

            var temperatureScore = 0;
            if (page.hasAny(text, ["temperature", " temp", "/temp", "temp1", "tctl", "tdie", "package", "package_id", "package id", "cputin", "coretemp", "k10temp", "zenpower", "cpu_thermal", "cpu thermal"])) {
                temperatureScore += 20;
            }
            if (page.hasAny(text, ["cpu", "processor"])) {
                temperatureScore += 25;
            }
            if (page.hasAny(text, ["package", "package_id", "package id", "tctl", "tdie"])) {
                temperatureScore += 40;
            }
            if (page.hasAny(text, ["coretemp", "k10temp", "zenpower"])) {
                temperatureScore += 20;
            }
            return temperatureScore;
        }

        if (metric === "fan") {
            if (!page.hasAny(text, ["fan", "rpm"])) {
                return 0;
            }

            var fanScore = 10;
            if (page.hasAny(text, ["cpu", "processor", "cpu_fan", "cpu fan"])) {
                fanScore += 50;
            }
            if (page.hasAny(text, ["fan1", "fan 1"])) {
                fanScore += 8;
            }
            if (page.hasAny(text, ["pump", "aio"])) {
                fanScore -= 20;
            }
            return fanScore;
        }

        return 0;
    }

    function considerHardwareSensor(best, sensorId, pathNames) {
        var temperatureScore = page.hardwareScore(sensorId, pathNames, "temperature");
        if (temperatureScore > best.temperatureScore) {
            best.temperatureScore = temperatureScore;
            best.temperatureSensorId = sensorId;
        }

        var fanScore = page.hardwareScore(sensorId, pathNames, "fan");
        if (fanScore > best.fanScore) {
            best.fanScore = fanScore;
            best.fanSensorId = sensorId;
        }
    }

    function collectHardwareSensors(parentIndex, pathNames, best) {
        var rows = parentIndex === undefined ? cpuSensorTree.rowCount() : cpuSensorTree.rowCount(parentIndex);
        for (var row = 0; row < rows; row++) {
            var index = parentIndex === undefined ? cpuSensorTree.index(row, 0) : cpuSensorTree.index(row, 0, parentIndex);
            var display = page.cleanName(cpuSensorTree.data(index, Qt.DisplayRole));
            var sensorId = page.cleanName(cpuSensorTree.data(index, Sensors.SensorTreeModel.SensorId));
            var nextPath = pathNames.slice(0);
            if (display.length > 0) {
                nextPath.push(display);
            }

            if (sensorId.length > 0) {
                page.considerHardwareSensor(best, sensorId, nextPath);
            } else {
                page.collectHardwareSensors(index, nextPath, best);
            }
        }
    }

    function rebuildHardwareSensors() {
        if (page.hardwareDiscoveryLocked) {
            return;
        }

        var best = {
            temperatureSensorId: "",
            temperatureScore: 0,
            fanSensorId: "",
            fanScore: 0
        };
        page.collectHardwareSensors(undefined, [], best);

        if (!page.temperatureDiscoveryLocked && best.temperatureScore > 0) {
            page.temperatureSensorId = best.temperatureSensorId;
            page.temperatureDiscoveryLocked = true;
        }
        if (!page.fanDiscoveryLocked && best.fanScore > 0) {
            page.fanSensorId = best.fanSensorId;
            page.fanDiscoveryLocked = true;
        }
    }

    function scheduleHardwareDiscovery() {
        if (page.hardwareDiscoveryLocked) {
            return;
        }
        hardwareDiscoveryTimer.restart();
    }

    Component.onCompleted: {
        page.loadCpuModel();
        page.scheduleHardwareDiscovery();
    }

    component CpuSummaryRow: RowLayout {
        property string label: ""
        property string value: ""
        property color markerColor: Kirigami.Theme.positiveTextColor
        property bool showMarker: true
        property real valueMaximumWidth: Kirigami.Units.gridUnit * 10

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
            Layout.minimumWidth: 0
            Layout.fillWidth: true
        }

        Controls.Label {
            text: value
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.minimumWidth: 0
            Layout.maximumWidth: valueMaximumWidth
        }
    }

    Local.RunCommand {
        id: cpuInfoCommand
    }

    Sensors.SensorTreeModel {
        id: cpuSensorTree
    }

    Connections {
        target: cpuSensorTree

        function onModelReset() {
            page.scheduleHardwareDiscovery();
        }

        function onRowsInserted() {
            page.scheduleHardwareDiscovery();
        }

        function onRowsRemoved() {
            page.scheduleHardwareDiscovery();
        }
    }

    Timer {
        id: hardwareDiscoveryTimer

        interval: 100
        repeat: false
        onTriggered: page.rebuildHardwareSensors()
    }

    Sensors.Sensor {
        id: cpuTemperatureSensor

        enabled: page.temperatureSensorId.length > 0
        sensorId: page.temperatureSensorId
        updateRateLimit: page.rootItem.sensorUpdateRate
    }

    Sensors.Sensor {
        id: cpuFanSensor

        enabled: page.fanSensorId.length > 0
        sensorId: page.fanSensorId
        updateRateLimit: page.rootItem.sensorUpdateRate
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit * 7.2, cpuSummaryContent.implicitHeight + Kirigami.Units.smallSpacing * 2)
            clip: true
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            RowLayout {
                id: cpuSummaryContent

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
                        label: i18nc("@label", "Model")
                        value: page.cpuModelText()
                        showMarker: false
                        valueMaximumWidth: Kirigami.Units.gridUnit * 13
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

                    CpuSummaryRow {
                        label: i18nc("@label", "Temperature")
                        value: page.optionalSensorText(cpuTemperatureSensor, page.temperatureSensorId)
                        markerColor: Kirigami.Theme.neutralTextColor
                    }

                    CpuSummaryRow {
                        label: i18nc("@label", "Fan")
                        value: page.optionalSensorText(cpuFanSensor, page.fanSensorId)
                        markerColor: Kirigami.Theme.visitedLinkColor
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
