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
    property real maxCpu: 1
    property string errorText: ""
    property real rowHeight: Kirigami.Units.gridUnit * 1.68

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    clip: true
    implicitHeight: header.implicitHeight + Math.min(root.limit, root.processes.length) * root.rowHeight + Kirigami.Units.largeSpacing

    function refresh() {
        command.exec("ps -eo pid=,pcpu=,pmem=,comm= --sort=-pcpu | head -n " + root.limit, function(result) {
            if (result.exitCode !== 0) {
                root.errorText = result.stderr.length > 0 ? result.stderr : i18nc("@info:status", "Unable to read process list");
                root.processes = [];
                root.maxCpu = 1;
                return;
            }

            var rows = [];
            var maxSeen = 1;
            var lines = result.stdout.trim().length > 0 ? result.stdout.trim().split(/\n/) : [];

            for (var i = 0; i < lines.length; i++) {
                var match = lines[i].match(/^\s*(\d+)\s+([0-9.]+)\s+([0-9.]+)\s+(.+?)\s*$/);
                if (!match) {
                    continue;
                }

                var cpu = Number(match[2]);
                var memory = Number(match[3]);
                if (!isFinite(cpu)) {
                    cpu = 0;
                }
                if (!isFinite(memory)) {
                    memory = 0;
                }

                maxSeen = Math.max(maxSeen, cpu);
                rows.push({
                    pid: match[1],
                    cpu: cpu,
                    memory: memory,
                    name: match[4]
                });
            }

            root.errorText = "";
            root.maxCpu = maxSeen;
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
            text: i18nc("@label", "CPU")
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
                        width: parent.width * Math.max(0, Math.min(1, modelData.cpu / root.maxCpu))
                        radius: parent.radius
                        color: Kirigami.Theme.positiveTextColor
                    }
                }

                Controls.Label {
                    text: i18nc("@label cpu percent", "%1%", modelData.cpu.toFixed(1))
                    horizontalAlignment: Text.AlignRight
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3.2
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
