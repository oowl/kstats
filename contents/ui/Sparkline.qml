import QtQuick

import org.kde.kirigami as Kirigami

Canvas {
    id: spark

    property real sampleValue: 0
    property int sampleLimit: 36
    property var samples: []
    property color lineColor: "white"
    property bool showFill: false
    property bool showGrid: false
    property bool showScale: false
    property var scaleTicks: [100, 50, 0]
    property string scaleSuffix: "%"
    property color scaleColor: Kirigami.Theme.disabledTextColor

    antialiasing: true

    onSampleValueChanged: addSample(sampleValue)
    Component.onCompleted: addSample(sampleValue)

    function addSample(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            numeric = 0;
        }

        var next = samples.slice(0);
        next.push(Math.max(0, Math.min(100, numeric)));
        while (next.length > sampleLimit) {
            next.shift();
        }
        samples = next;
        requestPaint();
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function scaleLabel(value) {
        return Math.round(value).toString() + scaleSuffix;
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        if (samples.length < 2 || width <= 0 || height <= 0) {
            return;
        }

        var fontSize = Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1);
        ctx.font = fontSize + "px sans-serif";

        var leftInset = 0;
        if (showScale) {
            for (var measureIndex = 0; measureIndex < scaleTicks.length; measureIndex++) {
                leftInset = Math.max(leftInset, ctx.measureText(scaleLabel(scaleTicks[measureIndex])).width);
            }
            leftInset = Math.ceil(leftInset + Kirigami.Units.smallSpacing);
        }

        var plotLeft = leftInset;
        var plotTop = showScale ? 2 : 0;
        var plotWidth = Math.max(1, width - plotLeft);
        var plotHeight = Math.max(1, height - (showScale ? 4 : 0));
        var step = plotWidth / Math.max(1, sampleLimit - 1);

        if (showGrid || showScale) {
            ctx.lineWidth = 1;
            ctx.strokeStyle = showScale ? scaleColor : lineColor;

            if (showScale) {
                ctx.fillStyle = scaleColor;
                ctx.textBaseline = "middle";
                ctx.globalAlpha = 0.68;
                for (var tickIndex = 0; tickIndex < scaleTicks.length; tickIndex++) {
                    var tick = Math.max(0, Math.min(100, Number(scaleTicks[tickIndex]) || 0));
                    var ty = plotTop + plotHeight - (tick / 100 * plotHeight);
                    var labelY = Math.max(fontSize / 2, Math.min(height - fontSize / 2, ty));
                    ctx.fillText(scaleLabel(tick), 0, labelY);
                    ctx.globalAlpha = tick === 0 || tick === 100 ? 0.10 : 0.16;
                    ctx.beginPath();
                    ctx.moveTo(plotLeft, ty);
                    ctx.lineTo(width, ty);
                    ctx.stroke();
                    ctx.globalAlpha = 0.68;
                }
            } else {
                ctx.globalAlpha = 0.12;
            }

            if (!showScale) {
                for (var grid = 1; grid < 4; grid++) {
                    var gy = plotTop + plotHeight * grid / 4;
                    ctx.beginPath();
                    ctx.moveTo(plotLeft, gy);
                    ctx.lineTo(width, gy);
                    ctx.stroke();
                }
            }
        }

        if (showFill) {
            ctx.fillStyle = lineColor;
            ctx.globalAlpha = 0.16;
            ctx.beginPath();
            ctx.moveTo(plotLeft + plotWidth - (samples.length - 1) * step, plotTop + plotHeight);
            for (var fillIndex = 0; fillIndex < samples.length; fillIndex++) {
                var fillX = plotLeft + plotWidth - (samples.length - 1 - fillIndex) * step;
                var fillY = plotTop + plotHeight - (samples[fillIndex] / 100 * plotHeight);
                ctx.lineTo(fillX, fillY);
            }
            ctx.lineTo(plotLeft + plotWidth, plotTop + plotHeight);
            ctx.closePath();
            ctx.fill();
        }

        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.strokeStyle = lineColor;
        ctx.globalAlpha = 0.9;
        ctx.beginPath();

        for (var i = 0; i < samples.length; i++) {
            var x = plotLeft + plotWidth - (samples.length - 1 - i) * step;
            var y = plotTop + plotHeight - (samples[i] / 100 * plotHeight);
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }

        ctx.stroke();
    }
}
