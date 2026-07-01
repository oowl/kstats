import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property alias cfg_updateRateLimit: updateRateLimit.value
    property alias cfg_showCpu: showCpu.checked
    property alias cfg_showMemory: showMemory.checked
    property alias cfg_showDisk: showDisk.checked
    property alias cfg_showNetwork: showNetwork.checked
    property alias cfg_cpuSensorId: cpuSensorId.text
    property alias cfg_memorySensorId: memorySensorId.text
    property alias cfg_diskSensorId: diskSensorId.text
    property alias cfg_diskReadSensorId: diskReadSensorId.text
    property alias cfg_diskWriteSensorId: diskWriteSensorId.text
    property alias cfg_networkDownloadSensorId: networkDownloadSensorId.text
    property alias cfg_networkUploadSensorId: networkUploadSensorId.text
    property alias cfg_gpuUsageSensorId: gpuUsageSensorId.text
    property alias cfg_gpuMemorySensorId: gpuMemorySensorId.text
    property alias cfg_gpuTemperatureSensorId: gpuTemperatureSensorId.text

    property int cfg_updateRateLimitDefault
    property bool cfg_showCpuDefault
    property bool cfg_showMemoryDefault
    property bool cfg_showDiskDefault
    property bool cfg_showNetworkDefault
    property string cfg_cpuSensorIdDefault
    property string cfg_memorySensorIdDefault
    property string cfg_diskSensorIdDefault
    property string cfg_diskReadSensorIdDefault
    property string cfg_diskWriteSensorIdDefault
    property string cfg_networkDownloadSensorIdDefault
    property string cfg_networkUploadSensorIdDefault
    property string cfg_gpuUsageSensorIdDefault
    property string cfg_gpuMemorySensorIdDefault
    property string cfg_gpuTemperatureSensorIdDefault

    Kirigami.FormLayout {
        anchors.fill: parent

        Controls.SpinBox {
            id: updateRateLimit
            Kirigami.FormData.label: i18nc("@label", "Update interval:")
            from: 500
            to: 10000
            stepSize: 250
            textFromValue: function(value) {
                return i18nc("@label milliseconds", "%1 ms", value);
            }
            valueFromText: function(text) {
                return Number.parseInt(text);
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Bar Modules")
            Layout.fillWidth: true
        }

        Controls.CheckBox {
            id: showCpu
            Kirigami.FormData.label: i18nc("@label", "CPU:")
            text: i18nc("@option:check", "Show in bar")
        }

        Controls.CheckBox {
            id: showMemory
            Kirigami.FormData.label: i18nc("@label", "Memory:")
            text: i18nc("@option:check", "Show in bar")
        }

        Controls.CheckBox {
            id: showDisk
            Kirigami.FormData.label: i18nc("@label", "Disk:")
            text: i18nc("@option:check", "Show in bar")
        }

        Controls.CheckBox {
            id: showNetwork
            Kirigami.FormData.label: i18nc("@label", "Network:")
            text: i18nc("@option:check", "Show in bar")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Sensor IDs")
            Layout.fillWidth: true
        }

        Controls.TextField {
            id: cpuSensorId
            Kirigami.FormData.label: i18nc("@label", "CPU:")
            placeholderText: root.cfg_cpuSensorIdDefault
        }

        Controls.TextField {
            id: memorySensorId
            Kirigami.FormData.label: i18nc("@label", "Memory:")
            placeholderText: root.cfg_memorySensorIdDefault
        }

        Controls.TextField {
            id: diskSensorId
            Kirigami.FormData.label: i18nc("@label", "Disk:")
            placeholderText: root.cfg_diskSensorIdDefault
        }

        Controls.TextField {
            id: diskReadSensorId
            Kirigami.FormData.label: i18nc("@label", "Disk read:")
            placeholderText: root.cfg_diskReadSensorIdDefault
        }

        Controls.TextField {
            id: diskWriteSensorId
            Kirigami.FormData.label: i18nc("@label", "Disk write:")
            placeholderText: root.cfg_diskWriteSensorIdDefault
        }

        Controls.TextField {
            id: networkDownloadSensorId
            Kirigami.FormData.label: i18nc("@label", "Network down:")
            placeholderText: root.cfg_networkDownloadSensorIdDefault
        }

        Controls.TextField {
            id: networkUploadSensorId
            Kirigami.FormData.label: i18nc("@label", "Network up:")
            placeholderText: root.cfg_networkUploadSensorIdDefault
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "GPU Sensor IDs")
            Layout.fillWidth: true
        }

        Controls.TextField {
            id: gpuUsageSensorId
            Kirigami.FormData.label: i18nc("@label", "GPU usage:")
            placeholderText: i18nc("@placeholder", "Optional")
        }

        Controls.TextField {
            id: gpuMemorySensorId
            Kirigami.FormData.label: i18nc("@label", "GPU memory:")
            placeholderText: i18nc("@placeholder", "Optional")
        }

        Controls.TextField {
            id: gpuTemperatureSensorId
            Kirigami.FormData.label: i18nc("@label", "GPU temperature:")
            placeholderText: i18nc("@placeholder", "Optional")
        }
    }
}
