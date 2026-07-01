import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import "." as Local

Item {
    id: page

    required property var rootItem
    property var gpuDevices: []
    property bool discoveryLocked: false

    clip: true
    Layout.fillWidth: true
    Layout.fillHeight: true

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

    function metricType(sensorId) {
        if (page.isTemplateSensorId(sensorId)) {
            return "";
        }

        var id = String(sensorId || "").toLowerCase();
        if (id.indexOf("gpu/") !== 0) {
            return "";
        }

        var parts = id.split("/");
        var tail = parts.length > 0 ? parts[parts.length - 1] : id;

        if (id.indexOf("clock") >= 0 || id.indexOf("frequency") >= 0 || id.indexOf("total") >= 0) {
            return "";
        }
        if (tail === "usage" || tail === "usedpercent" || tail === "activity") {
            return "usage";
        }
        if (tail === "temperature" || tail === "temp" || tail.indexOf("temp") === 0 || id.indexOf("temperature") >= 0) {
            return "temperature";
        }
        if (tail === "memory"
                || tail === "usedvram"
                || tail === "memoryused"
                || tail === "usedmemory"
                || id.indexOf("mem_info_vram_used") >= 0
                || id.indexOf("fbmemoryusage") >= 0) {
            return "memory";
        }

        return "";
    }

    function deviceKey(sensorId) {
        var parts = String(sensorId || "").split("/");
        if (parts.length >= 3 && parts[0] === "gpu") {
            return parts[1];
        }
        return "configured";
    }

    function fallbackDeviceName(key, index) {
        if (key === "all") {
            return i18nc("@label", "All GPUs");
        }

        var match = String(key).match(/^gpu(\d+)$/i);
        if (match) {
            return i18nc("@label GPU index", "GPU %1", Number(match[1]) + 1);
        }

        return index >= 0 ? i18nc("@label GPU index", "GPU %1", index + 1) : key;
    }

    function nameFromPath(key, pathNames, index) {
        for (var i = pathNames.length - 1; i >= 0; i--) {
            var name = page.cleanName(pathNames[i]);
            var lower = name.toLowerCase();
            if (name.length === 0
                    || lower.indexOf("[group]") >= 0
                    || lower === "gpu"
                    || lower === "gpus"
                    || lower === "graphics"
                    || lower === "sensors"
                    || lower === "all gpus"
                    || lower.indexOf("usage") >= 0
                    || lower.indexOf("memory") >= 0
                    || lower.indexOf("temperature") >= 0) {
                continue;
            }
            return name;
        }

        return page.fallbackDeviceName(key, index);
    }

    function sortKey(key) {
        var match = String(key).match(/(\d+)/);
        return match ? Number(match[1]) : 9999;
    }

    function fallbackDevices() {
        return [{
            key: "gpu0",
            name: i18nc("@label GPU index", "GPU %1", 1),
            usageSensorId: "gpu/gpu0/usage",
            memorySensorId: "gpu/gpu0/usedVram",
            temperatureSensorId: "gpu/gpu0/temperature"
        }];
    }

    function addMetric(devices, sensorId, pathNames) {
        var metric = page.metricType(sensorId);
        if (metric.length === 0) {
            return;
        }

        var key = page.deviceKey(sensorId);
        if (!devices[key]) {
            devices[key] = {
                key: key,
                pathNames: pathNames.slice(0),
                usageSensorId: "",
                memorySensorId: "",
                temperatureSensorId: ""
            };
        }

        if (metric === "usage" && devices[key].usageSensorId.length === 0) {
            devices[key].usageSensorId = sensorId;
        } else if (metric === "memory" && devices[key].memorySensorId.length === 0) {
            devices[key].memorySensorId = sensorId;
        } else if (metric === "temperature" && devices[key].temperatureSensorId.length === 0) {
            devices[key].temperatureSensorId = sensorId;
        }
    }

    function collectFromTree(parentIndex, pathNames, devices) {
        var rows = parentIndex === undefined ? gpuSensorTree.rowCount() : gpuSensorTree.rowCount(parentIndex);
        for (var row = 0; row < rows; row++) {
            var index = parentIndex === undefined ? gpuSensorTree.index(row, 0) : gpuSensorTree.index(row, 0, parentIndex);
            var display = page.cleanName(gpuSensorTree.data(index, Qt.DisplayRole));
            var sensorId = page.cleanName(gpuSensorTree.data(index, Sensors.SensorTreeModel.SensorId));
            var nextPath = pathNames.slice(0);
            if (display.length > 0) {
                nextPath.push(display);
            }

            if (sensorId.length > 0) {
                page.addMetric(devices, sensorId, nextPath);
            } else {
                page.collectFromTree(index, nextPath, devices);
            }
        }
    }

    function rebuildDevices() {
        if (page.discoveryLocked) {
            return;
        }

        var devicesByKey = {};
        page.collectFromTree(undefined, [], devicesByKey);

        var perDevice = [];
        var aggregate = null;
        var keys = Object.keys(devicesByKey).sort(function(left, right) {
            var leftSort = page.sortKey(left);
            var rightSort = page.sortKey(right);
            if (leftSort !== rightSort) {
                return leftSort - rightSort;
            }
            return left.localeCompare(right);
        });

        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            var device = devicesByKey[key];
            device.name = page.nameFromPath(key, device.pathNames || [], i);
            delete device.pathNames;

            if (key === "all") {
                aggregate = device;
            } else {
                perDevice.push(device);
            }
        }

        if (perDevice.length > 0) {
            page.gpuDevices = perDevice;
            page.discoveryLocked = true;
        } else if (aggregate !== null) {
            page.gpuDevices = [aggregate];
        } else {
            page.gpuDevices = page.fallbackDevices();
        }
    }

    function scheduleRebuild() {
        if (page.discoveryLocked) {
            return;
        }
        rebuildTimer.restart();
    }

    Component.onCompleted: scheduleRebuild()

    Sensors.SensorTreeModel {
        id: gpuSensorTree
    }

    Connections {
        target: gpuSensorTree

        function onModelReset() {
            page.scheduleRebuild();
        }

        function onRowsInserted() {
            page.scheduleRebuild();
        }

        function onRowsRemoved() {
            page.scheduleRebuild();
        }

        function onDataChanged() {
            page.scheduleRebuild();
        }
    }

    Timer {
        id: rebuildTimer

        interval: 100
        repeat: false
        onTriggered: page.rebuildDevices()
    }

    Controls.ScrollView {
        id: gpuScroll

        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.max(gpuScroll.availableWidth, implicitWidth)
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: page.gpuDevices

                delegate: Rectangle {
                    id: gpuCard

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: gpuCardContent.implicitHeight + Kirigami.Units.largeSpacing * 2
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

                    Sensors.Sensor {
                        id: usageSensor

                        enabled: gpuCard.modelData.usageSensorId.length > 0
                        sensorId: gpuCard.modelData.usageSensorId
                        updateRateLimit: page.rootItem.sensorUpdateRate
                    }

                    Sensors.Sensor {
                        id: memorySensor

                        enabled: gpuCard.modelData.memorySensorId.length > 0
                        sensorId: gpuCard.modelData.memorySensorId
                        updateRateLimit: page.rootItem.sensorUpdateRate
                    }

                    Sensors.Sensor {
                        id: temperatureSensor

                        enabled: gpuCard.modelData.temperatureSensorId.length > 0
                        sensorId: gpuCard.modelData.temperatureSensorId
                        updateRateLimit: page.rootItem.sensorUpdateRate
                    }

                    ColumnLayout {
                        id: gpuCardContent

                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "video-display"
                                implicitWidth: Kirigami.Units.iconSizes.small
                                implicitHeight: Kirigami.Units.iconSizes.small
                            }

                            Controls.Label {
                                text: gpuCard.modelData.name
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Local.DropdownMetric {
                            visible: gpuCard.modelData.usageSensorId.length > 0
                            title: i18nc("@label", "GPU")
                            iconName: "video-display"
                            primaryValue: page.rootItem.sensorText(usageSensor)
                            secondaryValue: i18nc("@label", "Graphics processor usage")
                            sensorId: usageSensor.sensorId
                            percent: page.rootItem.sensorPercent(usageSensor)
                            accentColor: Kirigami.Theme.positiveTextColor
                        }

                        Local.DropdownMetric {
                            visible: gpuCard.modelData.memorySensorId.length > 0
                            title: i18nc("@label", "GPU Memory")
                            iconName: "memory"
                            primaryValue: page.rootItem.sensorText(memorySensor)
                            secondaryValue: i18nc("@label", "Graphics memory used")
                            sensorId: memorySensor.sensorId
                            percent: page.rootItem.sensorPercent(memorySensor)
                            accentColor: Kirigami.Theme.focusColor
                        }

                        Local.DropdownMetric {
                            visible: gpuCard.modelData.temperatureSensorId.length > 0
                            title: i18nc("@label", "GPU Temperature")
                            iconName: "temperature-normal"
                            primaryValue: page.rootItem.sensorText(temperatureSensor)
                            secondaryValue: i18nc("@label", "Graphics processor temperature")
                            sensorId: temperatureSensor.sensorId
                            percent: page.rootItem.sensorPercent(temperatureSensor)
                            accentColor: Kirigami.Theme.neutralTextColor
                        }
                    }
                }
            }

            Controls.Label {
                visible: page.gpuDevices.length === 0
                text: i18nc("@info:status", "No GPU sensors found")
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
