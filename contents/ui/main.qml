import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "." as Local

PlasmoidItem {
    id: root

    property int sensorUpdateRate: Math.max(500, Plasmoid.configuration.updateRateLimit)

    property alias cpuUsageSensor: cpuUsage
    property alias cpuCountSensor: cpuCount
    property alias cpuCoreCountSensor: cpuCoreCount
    property alias memoryUsageSensor: memoryUsage
    property alias diskUsageSensor: diskUsage
    property alias diskReadSensor: diskRead
    property alias diskWriteSensor: diskWrite
    property alias networkDownloadSensor: networkDownload
    property alias networkUploadSensor: networkUpload
    property int selectedTab: 0
    readonly property int historySampleLimit: 72
    readonly property int networkHistorySampleLimit: 48
    property var memoryUsageSamples: []
    property var networkUploadSamples: []
    property var networkDownloadSamples: []

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.title: i18n("KStats")
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    Layout.minimumWidth: Kirigami.Units.gridUnit * 4
    Layout.minimumHeight: Kirigami.Units.gridUnit

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 8

    toolTipMainText: i18n("KStats")
    toolTipSubText: i18n("CPU %1 | Memory %2 | Disk %3 | Down %4 | Up %5",
        sensorText(cpuUsage),
        sensorText(memoryUsage),
        sensorText(diskUsage),
        sensorText(networkDownload),
        sensorText(networkUpload))

    function sensorText(sensor) {
        if (!sensor || !sensor.enabled || sensor.sensorId.length === 0) {
            return i18nc("@info:status", "Off");
        }

        if (sensor.formattedValue && sensor.formattedValue.length > 0) {
            return sensor.formattedValue;
        }

        if (sensor.value !== undefined && sensor.value !== null && sensor.value !== "") {
            return String(sensor.value);
        }

        return i18nc("@info:status", "N/A");
    }

    function configString(value) {
        if (value === undefined || value === null) {
            return "";
        }
        return String(value);
    }

    function sensorPercent(sensor) {
        if (!sensor || !sensor.enabled) {
            return 0;
        }

        var value = Number(sensor.value);
        if (!isFinite(value)) {
            value = Number.parseFloat(sensor.formattedValue);
        }
        if (!isFinite(value)) {
            return 0;
        }

        if (sensor.maximum > 0 && sensor.maximum !== 100) {
            value = value / sensor.maximum * 100;
        }

        return Math.max(0, Math.min(100, value));
    }

    function sensorRateValue(sensor) {
        if (!sensor || !sensor.enabled) {
            return 0;
        }

        var value = Number(sensor.value);
        if (isFinite(value)) {
            return Math.max(0, value);
        }

        var text = String(sensor.formattedValue || "").trim();
        var match = text.match(/^([0-9.]+)\s*([KMGT]?i?B)\/s$/i);
        if (!match) {
            return Math.max(0, Number.parseFloat(text) || 0);
        }

        value = Number(match[1]);
        if (!isFinite(value)) {
            return 0;
        }

        var unit = match[2].toLowerCase();
        var multiplier = 1;
        if (unit === "kib" || unit === "kb") {
            multiplier = 1024;
        } else if (unit === "mib" || unit === "mb") {
            multiplier = 1048576;
        } else if (unit === "gib" || unit === "gb") {
            multiplier = 1073741824;
        } else if (unit === "tib" || unit === "tb") {
            multiplier = 1099511627776;
        }

        return Math.max(0, value * multiplier);
    }

    function appendSample(samples, value, limit, clampPercent) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            numeric = 0;
        }
        numeric = clampPercent ? Math.max(0, Math.min(100, numeric)) : Math.max(0, numeric);

        var next = samples.slice(0);
        next.push(numeric);
        while (next.length > limit) {
            next.shift();
        }
        return next;
    }

    function sampleHistory() {
        root.memoryUsageSamples = root.appendSample(root.memoryUsageSamples,
            root.sensorPercent(root.memoryUsageSensor),
            root.historySampleLimit,
            true);
        root.networkUploadSamples = root.appendSample(root.networkUploadSamples,
            root.sensorRateValue(root.networkUploadSensor),
            root.networkHistorySampleLimit,
            false);
        root.networkDownloadSamples = root.appendSample(root.networkDownloadSamples,
            root.sensorRateValue(root.networkDownloadSensor),
            root.networkHistorySampleLimit,
            false);
    }

    function activeCount() {
        var count = 0;
        count += Plasmoid.configuration.showCpu ? 1 : 0;
        count += Plasmoid.configuration.showMemory ? 1 : 0;
        count += Plasmoid.configuration.showDisk ? 1 : 0;
        count += Plasmoid.configuration.showNetwork ? 1 : 0;
        return Math.max(1, count);
    }

    function selectTab(tabIndex) {
        var parsed = Number(tabIndex);
        if (!isFinite(parsed)) {
            parsed = 0;
        }
        root.selectedTab = Math.max(0, Math.min(4, Math.round(parsed)));
    }

    function openTab(tabIndex) {
        root.selectTab(tabIndex);
        root.expanded = true;
    }

    function toggleTab(tabIndex) {
        var previousTab = root.selectedTab;
        root.selectTab(tabIndex);

        if (root.expanded && root.selectedTab === previousTab) {
            root.expanded = false;
            return;
        }

        root.expanded = true;
    }

    function openSystemMonitor() {
        systemMonitorLauncher.exec("plasma-systemmonitor >/dev/null 2>&1 &", function(result) {
            if (result.exitCode !== 0) {
                Qt.openUrlExternally("applications:org.kde.plasma-systemmonitor.desktop");
            }
        });
    }

    compactRepresentation: Local.CompactRepresentation {
        rootItem: root
    }

    fullRepresentation: Local.FullRepresentation {
        rootItem: root
    }

    Local.RunCommand {
        id: systemMonitorLauncher
    }

    Sensors.Sensor {
        id: cpuUsage
        enabled: root.configString(Plasmoid.configuration.cpuSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.cpuSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: cpuCount
        sensorId: "cpu/all/cpuCount"
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: cpuCoreCount
        sensorId: "cpu/all/coreCount"
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: memoryUsage
        enabled: root.configString(Plasmoid.configuration.memorySensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.memorySensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: diskUsage
        enabled: root.configString(Plasmoid.configuration.diskSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.diskSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: diskRead
        enabled: root.configString(Plasmoid.configuration.diskReadSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.diskReadSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: diskWrite
        enabled: root.configString(Plasmoid.configuration.diskWriteSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.diskWriteSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: networkDownload
        enabled: root.configString(Plasmoid.configuration.networkDownloadSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.networkDownloadSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: networkUpload
        enabled: root.configString(Plasmoid.configuration.networkUploadSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.networkUploadSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Timer {
        interval: Math.max(1000, root.sensorUpdateRate)
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.sampleHistory()
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action", "Open System Monitor")
            icon.name: "utilities-system-monitor"
            onTriggered: root.openSystemMonitor()
        }
    ]
}
