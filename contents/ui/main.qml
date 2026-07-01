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
    property alias gpuUsageSensor: gpuUsage
    property alias gpuMemorySensor: gpuMemory
    property alias gpuTemperatureSensor: gpuTemperature
    property int selectedTab: 0

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

    Sensors.Sensor {
        id: gpuUsage
        enabled: root.configString(Plasmoid.configuration.gpuUsageSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.gpuUsageSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: gpuMemory
        enabled: root.configString(Plasmoid.configuration.gpuMemorySensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.gpuMemorySensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Sensors.Sensor {
        id: gpuTemperature
        enabled: root.configString(Plasmoid.configuration.gpuTemperatureSensorId).length > 0
        sensorId: root.configString(Plasmoid.configuration.gpuTemperatureSensorId)
        updateRateLimit: root.sensorUpdateRate
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18nc("@action", "Open System Monitor")
            icon.name: "utilities-system-monitor"
            onTriggered: root.openSystemMonitor()
        }
    ]
}
