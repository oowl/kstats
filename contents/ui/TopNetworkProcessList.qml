import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

ColumnLayout {
    id: root

    property int limit: 5
    property int refreshInterval: 3000
    property var processes: []
    property string errorText: ""
    property real rowHeight: Kirigami.Units.gridUnit * 1.32

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true
    clip: true
    implicitHeight: header.implicitHeight + Math.min(root.limit, root.processes.length) * root.rowHeight + Kirigami.Units.largeSpacing

    function refresh() {
        command.exec("ss -Htunp", function(result) {
            var text = (result.stdout || "") + "\n" + (result.stderr || "");
            var lines = text.split(/\n/);
            var byProcess = {};

            for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("Cannot open netlink") >= 0) {
                    continue;
                }

                var match = lines[i].match(/users:\(\(\"([^\"]+)\",pid=(\d+)/);
                if (!match) {
                    continue;
                }

                var key = match[2] + ":" + match[1];
                if (!(key in byProcess)) {
                    byProcess[key] = {
                        pid: match[2],
                        name: match[1],
                        connections: 0
                    };
                }
                byProcess[key].connections += 1;
            }

            var rows = [];
            for (var key in byProcess) {
                rows.push(byProcess[key]);
            }

            rows.sort(function(left, right) {
                return right.connections - left.connections;
            });

            root.processes = rows.slice(0, root.limit);
            root.errorText = rows.length === 0 && result.exitCode !== 0
                ? (result.stderr.length > 0 ? result.stderr : i18nc("@info:status", "Unable to read socket list"))
                : "";
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
            text: i18nc("@label", "CONN")
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

                Controls.Label {
                    text: modelData.name
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Controls.Label {
                    text: i18nc("@label process id", "PID %1", modelData.pid)
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                    elide: Text.ElideRight
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                }

                Controls.Label {
                    text: String(modelData.connections)
                    horizontalAlignment: Text.AlignRight
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                }
            }
        }
    }

    Controls.Label {
        visible: root.processes.length === 0
        text: root.errorText.length > 0 ? root.errorText : i18nc("@info:status", "No socket process data")
        color: Kirigami.Theme.disabledTextColor
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
