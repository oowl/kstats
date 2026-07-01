import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Rectangle {
    id: root

    property int refreshInterval: 1500
    property int sampleLimit: 72
    property var previous: null
    property var samples: []
    property real userPercent: 0
    property real systemPercent: 0
    property real idlePercent: 0
    property string errorText: ""

    radius: Kirigami.Units.cornerRadius
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 8

    function percentText(value) {
        return i18nc("@label percent", "%1%", value.toFixed(1));
    }

    function refresh() {
        command.exec("awk '/^cpu / {print $2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' /proc/stat", function(result) {
            if (result.exitCode !== 0) {
                root.errorText = result.stderr.length > 0 ? result.stderr : i18nc("@info:status", "Unable to read CPU details");
                return;
            }

            var fields = result.stdout.trim().split(/\s+/).map(function(item) {
                var value = Number(item);
                return isFinite(value) ? value : 0;
            });

            if (fields.length < 7) {
                root.errorText = i18nc("@info:status", "Unexpected CPU detail format");
                return;
            }

            var current = {
                user: fields[0] + fields[1],
                system: fields[2] + fields[5] + fields[6],
                idle: fields[3] + fields[4],
                steal: fields.length > 7 ? fields[7] : 0
            };
            current.total = current.user + current.system + current.idle + current.steal;

            if (root.previous !== null) {
                var totalDelta = Math.max(1, current.total - root.previous.total);
                var user = Math.max(0, current.user - root.previous.user) / totalDelta * 100;
                var system = Math.max(0, current.system - root.previous.system) / totalDelta * 100;
                var idle = Math.max(0, current.idle - root.previous.idle) / totalDelta * 100;

                root.userPercent = Math.max(0, Math.min(100, user));
                root.systemPercent = Math.max(0, Math.min(100, system));
                root.idlePercent = Math.max(0, Math.min(100, idle));

                var next = root.samples.slice(0);
                next.push({
                    user: root.userPercent,
                    system: root.systemPercent,
                    idle: root.idlePercent
                });
                while (next.length > root.sampleLimit) {
                    next.shift();
                }
                root.samples = next;
                chart.requestPaint();
            }

            root.previous = current;
            root.errorText = "";
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    Local.RunCommand {
        id: command
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Controls.Label {
                text: i18nc("@label", "Details")
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Controls.Label {
                text: root.errorText
                visible: root.errorText.length > 0
                color: Kirigami.Theme.negativeTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                elide: Text.ElideRight
                Layout.maximumWidth: Kirigami.Units.gridUnit * 10
            }
        }

        Canvas {
            id: chart

            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            property bool showScale: true

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                if (width <= 0 || height <= 0 || root.samples.length < 2) {
                    return;
                }

                var fontSize = Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1);
                ctx.font = fontSize + "px sans-serif";
                var scaleWidth = chart.showScale ? Math.ceil(ctx.measureText("100%").width + Kirigami.Units.smallSpacing) : 0;
                var plotLeft = scaleWidth;
                var plotTop = chart.showScale ? 2 : 0;
                var plotWidth = Math.max(1, width - plotLeft);
                var plotHeight = Math.max(1, height - (chart.showScale ? 4 : 0));
                var gridTicks = [100, 75, 50, 25, 0];
                var labelTicks = [100, 50, 0];

                ctx.lineWidth = 1;
                ctx.strokeStyle = Kirigami.Theme.textColor;
                for (var grid = 0; grid < gridTicks.length; grid++) {
                    var gy = plotTop + plotHeight - (gridTicks[grid] / 100 * plotHeight);
                    ctx.globalAlpha = gridTicks[grid] === 0 || gridTicks[grid] === 100 ? 0.08 : 0.12;
                    ctx.beginPath();
                    ctx.moveTo(plotLeft, gy);
                    ctx.lineTo(width, gy);
                    ctx.stroke();
                }

                if (chart.showScale) {
                    ctx.fillStyle = Kirigami.Theme.disabledTextColor;
                    ctx.textBaseline = "middle";
                    ctx.globalAlpha = 0.68;
                    for (var labelIndex = 0; labelIndex < labelTicks.length; labelIndex++) {
                        var tick = labelTicks[labelIndex];
                        var labelY = plotTop + plotHeight - (tick / 100 * plotHeight);
                        labelY = Math.max(fontSize / 2, Math.min(height - fontSize / 2, labelY));
                        ctx.fillText(tick.toString() + "%", 0, labelY);
                    }
                }

                drawLine(ctx, "idle", Kirigami.Theme.disabledTextColor, plotLeft, plotTop, plotWidth, plotHeight);
                drawLine(ctx, "system", Kirigami.Theme.neutralTextColor, plotLeft, plotTop, plotWidth, plotHeight);
                drawLine(ctx, "user", Kirigami.Theme.positiveTextColor, plotLeft, plotTop, plotWidth, plotHeight);
            }

            function drawLine(ctx, key, color, plotLeft, plotTop, plotWidth, plotHeight) {
                var step = plotWidth / Math.max(1, root.sampleLimit - 1);
                ctx.lineWidth = key === "user" ? 2.25 : 1.8;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.strokeStyle = color;
                ctx.globalAlpha = key === "idle" ? 0.60 : 0.90;
                ctx.beginPath();

                for (var i = 0; i < root.samples.length; i++) {
                    var x = plotLeft + plotWidth - (root.samples.length - 1 - i) * step;
                    var y = plotTop + plotHeight - (Math.max(0, Math.min(100, root.samples[i][key])) / 100 * plotHeight);
                    if (i === 0) {
                        ctx.moveTo(x, y);
                    } else {
                        ctx.lineTo(x, y);
                    }
                }

                ctx.stroke();
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            LegendValue {
                label: i18nc("@label", "User")
                value: root.percentText(root.userPercent)
                color: Kirigami.Theme.positiveTextColor
                Layout.fillWidth: true
            }

            LegendValue {
                label: i18nc("@label", "System")
                value: root.percentText(root.systemPercent)
                color: Kirigami.Theme.neutralTextColor
                Layout.fillWidth: true
            }

            LegendValue {
                label: i18nc("@label", "Idle")
                value: root.percentText(root.idlePercent)
                color: Kirigami.Theme.disabledTextColor
                Layout.fillWidth: true
            }
        }
    }

    component LegendValue: RowLayout {
        property string label
        property string value
        property color color

        spacing: Kirigami.Units.smallSpacing / 2

        Rectangle {
            Layout.preferredWidth: 7
            Layout.preferredHeight: 7
            radius: width / 2
            color: parent.color
        }

        Controls.Label {
            text: parent.label
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        Controls.Label {
            text: parent.value
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
