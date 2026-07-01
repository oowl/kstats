import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Rectangle {
    id: root

    property int refreshInterval: 1500
    property var previous: ({})
    property var cores: []
    property string errorText: ""

    radius: Kirigami.Units.cornerRadius
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
    border.width: 1
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 4.6

    function percentText(value) {
        return i18nc("@label percent", "%1%", value.toFixed(0));
    }

    function averagePercent() {
        if (cores.length === 0) {
            return 0;
        }

        var total = 0;
        for (var i = 0; i < cores.length; i++) {
            total += cores[i].usage;
        }
        return total / cores.length;
    }

    function parseOutput(output) {
        var lines = output.trim().length > 0 ? output.trim().split(/\n/) : [];
        var current = {};
        var rows = [];

        for (var i = 0; i < lines.length; i++) {
            var fields = lines[i].trim().split(/\s+/);
            if (fields.length < 8 || fields[0].indexOf("cpu") !== 0) {
                continue;
            }

            var values = [];
            for (var fieldIndex = 1; fieldIndex < fields.length; fieldIndex++) {
                var value = Number(fields[fieldIndex]);
                values.push(isFinite(value) ? value : 0);
            }

            var name = fields[0];
            var user = values[0] + values[1];
            var system = values[2] + values[5] + values[6];
            var idle = values[3] + values[4];
            var steal = values.length > 7 ? values[7] : 0;
            var total = user + system + idle + steal;
            var snapshot = {
                idle: idle,
                total: total
            };

            current[name] = snapshot;

            var previousCore = root.previous[name];
            var usage = 0;
            if (previousCore !== undefined) {
                var totalDelta = Math.max(1, snapshot.total - previousCore.total);
                var idleDelta = Math.max(0, snapshot.idle - previousCore.idle);
                usage = Math.max(0, Math.min(100, (totalDelta - idleDelta) / totalDelta * 100));
            }

            rows.push({
                name: name,
                index: Math.max(0, Number(name.replace("cpu", ""))),
                usage: usage
            });
        }

        rows.sort(function(left, right) {
            return left.index - right.index;
        });

        root.previous = current;
        root.cores = rows;
        chart.requestPaint();
    }

    function refresh() {
        command.exec("awk '/^cpu[0-9]+ / {print}' /proc/stat", function(result) {
            if (result.exitCode !== 0) {
                root.errorText = result.stderr.length > 0 ? result.stderr : i18nc("@info:status", "Unable to read CPU cores");
                return;
            }

            root.errorText = "";
            root.parseOutput(result.stdout);
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
                text: i18nc("@label", "CPU Cores")
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Controls.Label {
                text: root.errorText.length > 0
                    ? root.errorText
                    : i18nc("@label core count and average usage", "%1 cores · avg %2",
                        root.cores.length,
                        root.percentText(root.averagePercent()))
                color: root.errorText.length > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                elide: Text.ElideRight
                Layout.maximumWidth: Kirigami.Units.gridUnit * 12
            }
        }

        Canvas {
            id: chart

            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                if (width <= 0 || height <= 0) {
                    return;
                }

                var fontSize = Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1);
                ctx.font = fontSize + "px sans-serif";

                var labelWidth = Math.ceil(ctx.measureText("100%").width + Kirigami.Units.smallSpacing);
                var labelBottom = root.cores.length > 0 ? fontSize + 2 : 0;
                var plotLeft = labelWidth;
                var plotTop = 1;
                var plotWidth = Math.max(1, width - plotLeft);
                var plotHeight = Math.max(1, height - plotTop - labelBottom);
                var gridTicks = [100, 50, 0];

                ctx.lineWidth = 1;
                ctx.strokeStyle = Kirigami.Theme.textColor;
                ctx.fillStyle = Kirigami.Theme.disabledTextColor;
                ctx.textBaseline = "middle";

                for (var tickIndex = 0; tickIndex < gridTicks.length; tickIndex++) {
                    var tick = gridTicks[tickIndex];
                    var y = plotTop + plotHeight - (tick / 100 * plotHeight);
                    var labelY = Math.max(fontSize / 2, Math.min(height - labelBottom - fontSize / 2, y));
                    ctx.globalAlpha = 0.68;
                    ctx.fillText(tick.toString() + "%", 0, labelY);
                    ctx.globalAlpha = tick === 0 || tick === 100 ? 0.08 : 0.14;
                    ctx.beginPath();
                    ctx.moveTo(plotLeft, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }

                if (root.cores.length === 0) {
                    return;
                }

                var gap = Math.max(2, Math.min(5, plotWidth / Math.max(1, root.cores.length * 10)));
                var barWidth = Math.max(2, (plotWidth - gap * Math.max(0, root.cores.length - 1)) / root.cores.length);
                var labelEvery = barWidth >= 14 ? 1 : barWidth >= 7 ? 2 : 4;

                for (var i = 0; i < root.cores.length; i++) {
                    var usage = Math.max(0, Math.min(100, root.cores[i].usage));
                    var x = plotLeft + i * (barWidth + gap);
                    var barHeight = Math.max(1, usage / 100 * plotHeight);
                    var yTop = plotTop + plotHeight - barHeight;

                    ctx.fillStyle = Kirigami.Theme.positiveTextColor;
                    ctx.globalAlpha = 0.88;
                    ctx.fillRect(x, yTop, barWidth, barHeight);

                    ctx.fillStyle = Kirigami.Theme.textColor;
                    ctx.globalAlpha = 0.08;
                    ctx.fillRect(x, plotTop, barWidth, plotHeight - barHeight);

                    if (i % labelEvery === 0) {
                        ctx.fillStyle = Kirigami.Theme.disabledTextColor;
                        ctx.globalAlpha = 0.58;
                        ctx.textAlign = "center";
                        ctx.textBaseline = "alphabetic";
                        ctx.fillText(root.cores[i].index.toString(), x + barWidth / 2, height);
                    }
                }
            }
        }
    }
}
