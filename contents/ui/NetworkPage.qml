import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Item {
    id: page

    required property var rootItem
    property string interfaceName: ""
    property string localIp: i18nc("@info:status", "N/A")
    property string publicIp: i18nc("@info:status", "N/A")
    property string networkName: i18nc("@info:status", "N/A")
    property string physicalAddress: i18nc("@info:status", "N/A")
    property real downloadRate: 0
    property real uploadRate: 0
    property real lastRxBytes: -1
    property real lastTxBytes: -1
    property real lastSampleTime: 0
    property int chartTick: 0
    property int detailsTick: 0

    clip: true
    Layout.fillWidth: true
    Layout.fillHeight: true

    function formatRate(bytesPerSecond) {
        var value = Math.max(0, Number(bytesPerSecond) || 0);
        if (value >= 1048576) {
            return i18nc("@label network megabytes per second", "%1 MB/s", (value / 1048576).toFixed(value >= 10485760 ? 1 : 2));
        }
        if (value >= 1024) {
            return i18nc("@label network kilobytes per second", "%1 KB/s", (value / 1024).toFixed(value >= 10240 ? 0 : 1));
        }
        return i18nc("@label network bytes per second", "%1 B/s", Math.round(value));
    }

    function niceInterfaceName(name) {
        if (name.length === 0) {
            return i18nc("@info:status", "N/A");
        }
        if (name.indexOf("wl") === 0) {
            return i18nc("@label wifi interface", "Wi-Fi (%1)", name);
        }
        if (name.indexOf("en") === 0 || name.indexOf("eth") === 0) {
            return i18nc("@label wired interface", "Ethernet (%1)", name);
        }
        return name;
    }

    function isIgnoredInterface(name) {
        return name === "lo"
            || name.indexOf("docker") === 0
            || name.indexOf("br-") === 0
            || name.indexOf("veth") === 0
            || name.indexOf("tun") === 0;
    }

    function refreshRoute() {
        routeCommand.exec("ip route get 1.1.1.1", function(result) {
            if (result.exitCode !== 0) {
                return;
            }

            var devMatch = result.stdout.match(/\bdev\s+(\S+)/);
            var srcMatch = result.stdout.match(/\bsrc\s+(\S+)/);

            if (devMatch) {
                page.interfaceName = devMatch[1];
                page.refreshInterfaceDetails();
            }
            if (srcMatch) {
                page.localIp = srcMatch[1];
            }
        });
    }

    function refreshInterfaceDetails() {
        if (page.interfaceName.length === 0) {
            return;
        }

        macCommand.exec("cat /sys/class/net/" + page.interfaceName + "/address", function(result) {
            if (result.exitCode === 0 && result.stdout.trim().length > 0) {
                page.physicalAddress = result.stdout.trim();
            }
        });

        addrCommand.exec("ip -o -4 addr show dev " + page.interfaceName, function(result) {
            if (result.exitCode === 0) {
                var match = result.stdout.match(/\binet\s+([0-9.]+)/);
                if (match) {
                    page.localIp = match[1];
                }
            }
        });

        wifiCommand.exec("iwgetid " + page.interfaceName + " -r", function(result) {
            var name = result.exitCode === 0 ? result.stdout.trim() : "";
            if (name.length > 0) {
                page.networkName = name;
            } else if (page.interfaceName.indexOf("wl") === 0) {
                page.networkName = i18nc("@label", "Wi-Fi");
            } else if (page.interfaceName.length > 0) {
                page.networkName = i18nc("@label", "Wired");
            }
        });
    }

    function refreshNetwork() {
        netdevCommand.exec("cat /proc/net/dev", function(result) {
            if (result.exitCode !== 0) {
                return;
            }

            var candidates = [];
            var selected = null;
            var lines = result.stdout.split(/\n/);

            for (var i = 2; i < lines.length; i++) {
                var colon = lines[i].indexOf(":");
                if (colon < 0) {
                    continue;
                }

                var name = lines[i].slice(0, colon).trim();
                var fields = lines[i].slice(colon + 1).trim().split(/\s+/);
                if (fields.length < 16) {
                    continue;
                }

                var rx = Number(fields[0]);
                var tx = Number(fields[8]);
                if (!isFinite(rx) || !isFinite(tx)) {
                    continue;
                }

                var row = {
                    name: name,
                    rx: rx,
                    tx: tx,
                    total: rx + tx
                };

                if (name === page.interfaceName) {
                    selected = row;
                }
                if (!page.isIgnoredInterface(name)) {
                    candidates.push(row);
                }
            }

            if (!selected && candidates.length > 0) {
                candidates.sort(function(left, right) {
                    return right.total - left.total;
                });
                selected = candidates[0];
                if (page.interfaceName !== selected.name) {
                    page.interfaceName = selected.name;
                    page.refreshInterfaceDetails();
                }
            }

            if (!selected) {
                return;
            }

            var now = Date.now();
            if (page.lastSampleTime > 0 && page.lastRxBytes >= 0 && page.lastTxBytes >= 0) {
                var seconds = Math.max(0.001, (now - page.lastSampleTime) / 1000);
                page.downloadRate = Math.max(0, (selected.rx - page.lastRxBytes) / seconds);
                page.uploadRate = Math.max(0, (selected.tx - page.lastTxBytes) / seconds);
                page.chartTick += 1;
            }

            page.lastRxBytes = selected.rx;
            page.lastTxBytes = selected.tx;
            page.lastSampleTime = now;
        });
    }

    component NetworkDetailRow: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

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
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            elide: Text.ElideRight
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }
    }

    Component.onCompleted: {
        refreshRoute();
        refreshNetwork();
    }

    Timer {
        interval: Math.max(1000, page.rootItem.sensorUpdateRate)
        repeat: true
        running: page.visible
        triggeredOnStart: false
        onTriggered: {
            page.refreshNetwork();
            page.detailsTick += 1;
            if (page.detailsTick % 5 === 0) {
                page.refreshRoute();
            }
        }
    }

    Local.RunCommand {
        id: routeCommand
    }

    Local.RunCommand {
        id: netdevCommand
    }

    Local.RunCommand {
        id: macCommand
    }

    Local.RunCommand {
        id: addrCommand
    }

    Local.RunCommand {
        id: wifiCommand
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.3
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    Controls.Label {
                        text: page.formatRate(page.uploadRate)
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.45
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing / 2

                        Rectangle {
                            Layout.preferredWidth: 9
                            Layout.preferredHeight: 9
                            radius: 2
                            color: Kirigami.Theme.negativeTextColor
                        }

                        Controls.Label {
                            text: i18nc("@label", "Upload")
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    Controls.Label {
                        text: page.formatRate(page.downloadRate)
                        color: Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.45
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing / 2

                        Rectangle {
                            Layout.preferredWidth: 9
                            Layout.preferredHeight: 9
                            radius: 2
                            color: Kirigami.Theme.focusColor
                        }

                        Controls.Label {
                            text: i18nc("@label", "Download")
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5.2
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Controls.Label {
                    text: i18nc("@label", "Usage History")
                    color: Kirigami.Theme.disabledTextColor
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                Local.NetworkHistoryChart {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sampleLimit: page.rootItem.networkHistorySampleLimit
                    uploadSamples: page.rootItem.networkUploadSamples
                    downloadSamples: page.rootItem.networkDownloadSamples
                    autoSample: false
                    uploadColor: Kirigami.Theme.negativeTextColor
                    downloadColor: Kirigami.Theme.focusColor
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6.1
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing / 2

                Controls.Label {
                    text: i18nc("@label", "Details")
                    color: Kirigami.Theme.disabledTextColor
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                NetworkDetailRow {
                    label: i18nc("@label", "Public IP")
                    value: page.publicIp
                }

                NetworkDetailRow {
                    label: i18nc("@label", "Local IP")
                    value: page.localIp
                }

                NetworkDetailRow {
                    label: i18nc("@label", "Interface")
                    value: page.niceInterfaceName(page.interfaceName)
                }

                NetworkDetailRow {
                    label: i18nc("@label", "Network")
                    value: page.networkName
                }

                NetworkDetailRow {
                    label: i18nc("@label", "Physical address")
                    value: page.physicalAddress
                }
            }
        }

        Local.TopApplicationList {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            metric: "network"
            limit: 5
            refreshInterval: Math.max(3000, page.rootItem.sensorUpdateRate * 3)
        }
    }
}
