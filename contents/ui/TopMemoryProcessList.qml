import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

ColumnLayout {
    id: root

    property int limit: 5
    property int refreshInterval: 2500
    property var processes: []
    property real maxRss: 1
    property string errorText: ""
    property real rowHeight: Kirigami.Units.gridUnit * 1.68

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    clip: true
    implicitHeight: header.implicitHeight + Math.min(root.limit, root.processes.length) * root.rowHeight + Kirigami.Units.largeSpacing

    function formatKiB(kib) {
        var bytes = Math.max(0, Number(kib) || 0) * 1024;
        var gib = bytes / 1073741824;
        if (gib >= 1) {
            return i18nc("@label memory in gigabytes", "%1 GB", gib.toFixed(gib >= 10 ? 1 : 2));
        }

        return i18nc("@label memory in megabytes", "%1 MB", Math.round(bytes / 1048576));
    }

    function refresh() {
        command.exec("ps -eo pid=,rss=,pmem=,comm= --sort=-rss | head -n " + root.limit, function(result) {
            if (result.exitCode !== 0) {
                root.errorText = result.stderr.length > 0 ? result.stderr : i18nc("@info:status", "Unable to read process list");
                root.processes = [];
                root.maxRss = 1;
                return;
            }

            var rows = [];
            var maxSeen = 1;
            var lines = result.stdout.trim().length > 0 ? result.stdout.trim().split(/\n/) : [];

            for (var i = 0; i < lines.length; i++) {
                var match = lines[i].match(/^\s*(\d+)\s+(\d+)\s+([0-9.]+)\s+(.+?)\s*$/);
                if (!match) {
                    continue;
                }

                var rss = Number(match[2]);
                var percent = Number(match[3]);
                if (!isFinite(rss)) {
                    rss = 0;
                }
                if (!isFinite(percent)) {
                    percent = 0;
                }

                maxSeen = Math.max(maxSeen, rss);
                rows.push({
                    pid: match[1],
                    rss: rss,
                    memory: percent,
                    name: match[4]
                });
            }

            root.errorText = "";
            root.maxRss = maxSeen;
            root.processes = rows;
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: root.visible
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    Local.RunCommand {
        id: command
    }

    RowLayout {
        id: header

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18nc("@label", "Top Processes")
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        Controls.Label {
            text: i18nc("@label", "RAM")
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }
    }

    Repeater {
        model: root.processes

        delegate: Rectangle {
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: root.rowHeight
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.035)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Controls.Label {
                        text: modelData.name
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Controls.Label {
                        text: i18nc("@label process id and memory percent", "PID %1 · %2% MEM",
                            modelData.pid,
                            modelData.memory.toFixed(1))
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: 4
                    radius: height / 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, modelData.rss / root.maxRss))
                        radius: parent.radius
                        color: Kirigami.Theme.focusColor
                    }
                }

                Controls.Label {
                    text: root.formatKiB(modelData.rss)
                    horizontalAlignment: Text.AlignRight
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                }
            }
        }
    }

    Controls.Label {
        visible: root.processes.length === 0
        text: root.errorText.length > 0 ? root.errorText : i18nc("@info:status", "No process data yet")
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
