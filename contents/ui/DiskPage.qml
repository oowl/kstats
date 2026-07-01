import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Item {
    id: page

    required property var rootItem
    property var disks: []
    property var mounts: []
    property var previousDiskStats: ({})
    property real previousDiskStatsTime: 0
    property string errorText: ""
    property int maxDisks: 3
    property int maxMounts: 3
    property int currentView: 0
    readonly property real sectionSpacing: Kirigami.Units.smallSpacing * 1.15
    readonly property real headerHeight: Kirigami.Units.gridUnit * 1.55
    readonly property real switchHeight: Kirigami.Units.gridUnit * 2.1
    readonly property real diskRowHeight: Kirigami.Units.gridUnit * 3.95

    clip: true
    Layout.fillWidth: true
    Layout.fillHeight: true

    function formatBytes(bytes) {
        var value = Math.max(0, Number(bytes) || 0);
        var tib = value / 1099511627776;
        if (tib >= 1) {
            return i18nc("@label storage in terabytes", "%1 TB", tib.toFixed(tib >= 10 ? 1 : 2));
        }

        var gib = value / 1073741824;
        if (gib >= 1) {
            return i18nc("@label storage in gigabytes", "%1 GB", gib.toFixed(gib >= 10 ? 1 : 2));
        }

        return i18nc("@label storage in megabytes", "%1 MB", Math.round(value / 1048576));
    }

    function formatRate(bytesPerSecond) {
        var value = Math.max(0, Number(bytesPerSecond) || 0);
        if (value >= 1048576) {
            return i18nc("@label disk megabytes per second", "%1 MB/s", (value / 1048576).toFixed(value >= 10485760 ? 1 : 2));
        }
        if (value >= 1024) {
            return i18nc("@label disk kilobytes per second", "%1 KB/s", (value / 1024).toFixed(value >= 10240 ? 0 : 1));
        }
        return i18nc("@label disk bytes per second", "%1 B/s", Math.round(value));
    }

    function isIgnoredDisk(name) {
        return name.indexOf("zram") === 0
            || name.indexOf("loop") === 0
            || name.indexOf("sr") === 0
            || name.indexOf("ram") === 0;
    }

    function isHiddenMount(mountPoint) {
        return mountPoint.length === 0
            || mountPoint === "[SWAP]"
            || mountPoint.indexOf("/proc") === 0
            || mountPoint.indexOf("/sys") === 0
            || mountPoint.indexOf("/dev") === 0
            || mountPoint.indexOf("/run") === 0
            || mountPoint.indexOf("/var/lib/docker") === 0;
    }

    function rememberDevice(map, name, diskName) {
        if (!name || name.length === 0) {
            return;
        }
        map[name] = diskName;
        map["/dev/" + name] = diskName;
    }

    function appendMount(disk, mountPoint) {
        if (!disk || page.isHiddenMount(mountPoint)) {
            return;
        }
        if (disk.mounts.indexOf(mountPoint) < 0) {
            disk.mounts.push(mountPoint);
        }
    }

    function parseBlockDevices(output) {
        var parsed = JSON.parse(output);
        var rows = [];
        var diskByName = {};
        var deviceToDisk = {};
        var mountToDisk = {};
        var mountRows = [];

        function walk(block, activeDiskName) {
            if (!block) {
                return;
            }

            var name = block.name || "";
            var kname = block.kname || name;
            var type = block.type || "";
            var diskName = activeDiskName;

            if (type === "disk" && !page.isIgnoredDisk(name)) {
                diskName = kname;
                var disk = {
                    name: kname,
                    title: name,
                    model: block.model || "",
                    size: Number(block.size) || 0,
                    used: 0,
                    percent: 0,
                    readRate: 0,
                    writeRate: 0,
                    mounts: []
                };
                rows.push(disk);
                diskByName[diskName] = disk;
                page.rememberDevice(deviceToDisk, name, diskName);
                page.rememberDevice(deviceToDisk, kname, diskName);
            } else if (diskName && diskName in diskByName) {
                page.rememberDevice(deviceToDisk, name, diskName);
                page.rememberDevice(deviceToDisk, kname, diskName);
            }

            if (diskName && diskName in diskByName) {
                var mountpoints = block.mountpoints || [];
                for (var i = 0; i < mountpoints.length; i++) {
                    var mountPoint = mountpoints[i] || "";
                    if (!page.isHiddenMount(mountPoint)) {
                        mountToDisk[mountPoint] = diskName;
                        page.appendMount(diskByName[diskName], mountPoint);
                    }
                }
            }

            var children = block.children || [];
            for (var childIndex = 0; childIndex < children.length; childIndex++) {
                walk(children[childIndex], diskName);
            }
        }

        var blockdevices = parsed.blockdevices || [];
        for (var i = 0; i < blockdevices.length; i++) {
            walk(blockdevices[i], "");
        }

        return {
            rows: rows,
            diskByName: diskByName,
            deviceToDisk: deviceToDisk,
            mountToDisk: mountToDisk,
            mountRows: mountRows
        };
    }

    function applyFilesystemUsage(layout, output) {
        var seenSources = {};
        var lines = output.trim().length > 0 ? output.trim().split(/\n/) : [];

        for (var i = 1; i < lines.length; i++) {
            var match = lines[i].match(/^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.+?)\s*$/);
            if (!match) {
                continue;
            }

            var source = match[1];
            var total = Number(match[2]);
            var used = Number(match[3]);
            var available = Number(match[4]);
            var percent = Number(match[5]);
            var mountPoint = match[6];
            var diskName = layout.mountToDisk[mountPoint] || layout.deviceToDisk[source];

            if (!diskName || !(diskName in layout.diskByName) || page.isHiddenMount(mountPoint)) {
                continue;
            }

            var disk = layout.diskByName[diskName];
            page.appendMount(disk, mountPoint);

            layout.mountRows.push({
                source: source,
                mountPoint: mountPoint,
                diskName: diskName,
                diskTitle: disk.title,
                total: isFinite(total) ? total : 0,
                used: isFinite(used) ? used : 0,
                available: isFinite(available) ? available : 0,
                percent: isFinite(percent) ? Math.max(0, Math.min(100, percent)) : 0,
                readRate: 0,
                writeRate: 0
            });

            if (source in seenSources) {
                continue;
            }
            seenSources[source] = true;

            if (isFinite(used)) {
                layout.diskByName[diskName].used += used;
            }
        }
    }

    function parseDiskStats(output) {
        var stats = {};
        var lines = output.split(/\n/);

        for (var i = 0; i < lines.length; i++) {
            var fields = lines[i].trim().split(/\s+/);
            if (fields.length < 10) {
                continue;
            }

            var name = fields[2];
            var readSectors = Number(fields[5]);
            var writtenSectors = Number(fields[9]);
            if (!isFinite(readSectors) || !isFinite(writtenSectors)) {
                continue;
            }

            stats[name] = {
                readBytes: readSectors * 512,
                writeBytes: writtenSectors * 512
            };
        }

        return stats;
    }

    function finishRefresh(layout, statsOutput) {
        var now = Date.now();
        var stats = page.parseDiskStats(statsOutput);
        var nextPrevious = {};
        var elapsed = page.previousDiskStatsTime > 0 ? Math.max(0.001, (now - page.previousDiskStatsTime) / 1000) : 0;

        for (var i = 0; i < layout.rows.length; i++) {
            var disk = layout.rows[i];
            var diskStats = stats[disk.name];

            if (disk.size > 0) {
                disk.percent = Math.max(0, Math.min(100, disk.used / disk.size * 100));
            }

            if (diskStats) {
                var previous = page.previousDiskStats[disk.name];
                if (previous && elapsed > 0) {
                    disk.readRate = Math.max(0, (diskStats.readBytes - previous.readBytes) / elapsed);
                    disk.writeRate = Math.max(0, (diskStats.writeBytes - previous.writeBytes) / elapsed);
                }
                nextPrevious[disk.name] = diskStats;
            }
        }

        for (var mountIndex = 0; mountIndex < layout.mountRows.length; mountIndex++) {
            var mount = layout.mountRows[mountIndex];
            if (mount.diskName in layout.diskByName) {
                mount.readRate = layout.diskByName[mount.diskName].readRate;
                mount.writeRate = layout.diskByName[mount.diskName].writeRate;
            }
        }

        layout.rows.sort(function(left, right) {
            return right.size - left.size;
        });

        layout.mountRows.sort(function(left, right) {
            if (left.mountPoint === "/") {
                return -1;
            }
            if (right.mountPoint === "/") {
                return 1;
            }
            return left.mountPoint.localeCompare(right.mountPoint);
        });

        page.previousDiskStats = nextPrevious;
        page.previousDiskStatsTime = now;
        page.errorText = "";
        page.disks = layout.rows.slice(0, page.maxDisks);
        page.mounts = layout.mountRows.slice(0, page.maxMounts);
    }

    function refresh() {
        layoutCommand.exec("lsblk -b -J -o NAME,KNAME,TYPE,SIZE,MODEL,PKNAME,MOUNTPOINTS", function(layoutResult) {
            if (layoutResult.exitCode !== 0) {
                page.errorText = layoutResult.stderr.length > 0 ? layoutResult.stderr : i18nc("@info:status", "Unable to read disk devices");
                page.disks = [];
                page.mounts = [];
                return;
            }

            var layout;
            try {
                layout = page.parseBlockDevices(layoutResult.stdout);
            } catch (error) {
                page.errorText = i18nc("@info:status", "Unable to parse disk devices");
                page.disks = [];
                page.mounts = [];
                return;
            }

            usageCommand.exec("df -P -B1 -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs", function(usageResult) {
                if (usageResult.exitCode === 0) {
                    page.applyFilesystemUsage(layout, usageResult.stdout);
                }

                statsCommand.exec("cat /proc/diskstats", function(statsResult) {
                    page.finishRefresh(layout, statsResult.exitCode === 0 ? statsResult.stdout : "");
                });
            });
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: Math.max(2500, page.rootItem.sensorUpdateRate * 2)
        repeat: true
        running: page.visible
        triggeredOnStart: false
        onTriggered: page.refresh()
    }

    Local.RunCommand {
        id: layoutCommand
    }

    Local.RunCommand {
        id: usageCommand
    }

    Local.RunCommand {
        id: statsCommand
    }

    Column {
        anchors.fill: parent
        spacing: page.sectionSpacing

        RowLayout {
            width: parent.width
            height: page.headerHeight
            spacing: Kirigami.Units.smallSpacing

            Controls.Label {
                text: page.currentView === 0 ? i18nc("@label", "Physical Disks") : i18nc("@label", "Mount Points")
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Controls.Label {
                text: i18nc("@label", "R/W per disk")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }
        }

        Rectangle {
            width: parent.width
            height: page.switchHeight
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.055)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing / 2
                spacing: Kirigami.Units.smallSpacing / 2

                Local.TabPill {
                    checked: page.currentView === 0
                    iconName: "drive-harddisk"
                    accentColor: Kirigami.Theme.focusColor
                    text: i18nc("@title:tab", "Disks")
                    onClicked: page.currentView = 0
                }

                Local.TabPill {
                    checked: page.currentView === 1
                    iconName: "folder"
                    accentColor: Kirigami.Theme.focusColor
                    text: i18nc("@title:tab", "Mounts")
                    onClicked: page.currentView = 1
                }
            }
        }

        Repeater {
            model: page.currentView === 0 ? page.disks : []

            delegate: Rectangle {
                required property var modelData

                width: parent.width
                height: page.diskRowHeight
                clip: true
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Controls.Label {
                                text: modelData.title
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Controls.Label {
                                text: modelData.model.length > 0 ? modelData.model : modelData.name
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing / 2

                            Controls.Label {
                                text: i18nc("@label disk read indicator", "R")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 2
                                color: Kirigami.Theme.focusColor
                            }

                            Controls.Label {
                                text: page.formatRate(modelData.readRate)
                                font.weight: Font.DemiBold
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.3
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing / 2

                            Controls.Label {
                                text: i18nc("@label disk write indicator", "W")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 2
                                color: Kirigami.Theme.negativeTextColor
                            }

                            Controls.Label {
                                text: page.formatRate(modelData.writeRate)
                                font.weight: Font.DemiBold
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.3
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: height / 2
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * modelData.percent / 100
                            radius: parent.radius
                            color: Kirigami.Theme.focusColor
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Controls.Label {
                            text: i18nc("@label disk used from total", "Used %1 from %2",
                                page.formatBytes(modelData.used),
                                page.formatBytes(modelData.size))
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Controls.Label {
                            text: i18nc("@label disk percent", "%1%", Math.round(modelData.percent))
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        Repeater {
            model: page.currentView === 1 ? page.mounts : []

            delegate: Rectangle {
                required property var modelData

                width: parent.width
                height: page.diskRowHeight
                clip: true
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Controls.Label {
                                text: modelData.mountPoint
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Controls.Label {
                                text: i18nc("@label mount source and disk", "%1 on %2", modelData.source, modelData.diskTitle)
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing / 2

                            Controls.Label {
                                text: i18nc("@label disk read indicator", "R")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 2
                                color: Kirigami.Theme.focusColor
                            }

                            Controls.Label {
                                text: page.formatRate(modelData.readRate)
                                font.weight: Font.DemiBold
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.3
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing / 2

                            Controls.Label {
                                text: i18nc("@label disk write indicator", "W")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 2
                                color: Kirigami.Theme.negativeTextColor
                            }

                            Controls.Label {
                                text: page.formatRate(modelData.writeRate)
                                font.weight: Font.DemiBold
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.3
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: height / 2
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * modelData.percent / 100
                            radius: parent.radius
                            color: Kirigami.Theme.focusColor
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Controls.Label {
                            text: i18nc("@label disk used from total", "Used %1 from %2",
                                page.formatBytes(modelData.used),
                                page.formatBytes(modelData.total))
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Controls.Label {
                            text: i18nc("@label disk percent", "%1%", Math.round(modelData.percent))
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        Controls.Label {
            visible: page.currentView === 0 ? page.disks.length === 0 : page.mounts.length === 0
            width: parent.width
            height: visible ? implicitHeight : 0
            text: page.errorText.length > 0 ? page.errorText : i18nc("@info:status", "No disk data yet")
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
        }

        Item {
            width: parent.width
            height: Kirigami.Units.smallSpacing
        }

        Local.TopApplicationList {
            width: parent.width
            height: implicitHeight
            metric: "disk"
            limit: 5
            rowHeight: Kirigami.Units.gridUnit * 1.88
            refreshInterval: Math.max(3000, page.rootItem.sensorUpdateRate * 3)
        }
    }
}
