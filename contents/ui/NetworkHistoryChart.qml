import QtQuick

import org.kde.kirigami as Kirigami

Canvas {
    id: chart

    property real uploadValue: 0
    property real downloadValue: 0
    property int sampleKey: 0
    property int sampleLimit: 48
    property var uploadSamples: []
    property var downloadSamples: []
    property bool autoSample: true
    property color uploadColor: Kirigami.Theme.negativeTextColor
    property color downloadColor: Kirigami.Theme.focusColor
    property bool showScale: true
    property color scaleColor: Kirigami.Theme.disabledTextColor

    antialiasing: true

    onSampleKeyChanged: if (autoSample) addSample(uploadValue, downloadValue)
    onUploadSamplesChanged: requestPaint()
    onDownloadSamplesChanged: requestPaint()
    Component.onCompleted: if (autoSample) addSample(uploadValue, downloadValue)
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function normalize(value) {
        var numeric = Number(value);
        return isFinite(numeric) ? Math.max(0, numeric) : 0;
    }

    function addSample(upload, download) {
        var nextUpload = uploadSamples.slice(0);
        var nextDownload = downloadSamples.slice(0);

        nextUpload.push(normalize(upload));
        nextDownload.push(normalize(download));

        while (nextUpload.length > sampleLimit) {
            nextUpload.shift();
        }
        while (nextDownload.length > sampleLimit) {
            nextDownload.shift();
        }

        uploadSamples = nextUpload;
        downloadSamples = nextDownload;
        requestPaint();
    }

    function maxSample() {
        var maximum = 1;
        for (var i = 0; i < uploadSamples.length; i++) {
            maximum = Math.max(maximum, uploadSamples[i]);
        }
        for (var j = 0; j < downloadSamples.length; j++) {
            maximum = Math.max(maximum, downloadSamples[j]);
        }
        return maximum;
    }

    function formatRate(bytesPerSecond) {
        var value = Math.max(0, Number(bytesPerSecond) || 0);
        if (value >= 1048576) {
            return i18nc("@label rate in megabytes per second", "%1 MB/s", (value / 1048576).toFixed(value >= 10485760 ? 1 : 2));
        }
        if (value >= 1024) {
            return i18nc("@label rate in kilobytes per second", "%1 KB/s", (value / 1024).toFixed(value >= 10240 ? 0 : 1));
        }
        return i18nc("@label rate in bytes per second", "%1 B/s", Math.round(value));
    }

    function drawSeries(ctx, samples, color, baseline, scale, direction, step, plotLeft, plotWidth) {
        if (samples.length < 2) {
            return;
        }

        var startX = plotLeft + plotWidth - (samples.length - 1) * step;

        ctx.fillStyle = color;
        ctx.globalAlpha = 0.12;
        ctx.beginPath();
        ctx.moveTo(startX, baseline);
        for (var fillIndex = 0; fillIndex < samples.length; fillIndex++) {
            var fillX = plotLeft + plotWidth - (samples.length - 1 - fillIndex) * step;
            var fillY = baseline + direction * samples[fillIndex] * scale;
            ctx.lineTo(fillX, fillY);
        }
        ctx.lineTo(plotLeft + plotWidth, baseline);
        ctx.closePath();
        ctx.fill();

        ctx.strokeStyle = color;
        ctx.globalAlpha = 0.9;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        for (var i = 0; i < samples.length; i++) {
            var x = plotLeft + plotWidth - (samples.length - 1 - i) * step;
            var y = baseline + direction * samples[i] * scale;
            if (i === 0) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }
        ctx.stroke();
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        if (width <= 0 || height <= 0) {
            return;
        }

        var baseline = height / 2;
        var maxValue = maxSample();
        var fontSize = Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1);
        ctx.font = fontSize + "px sans-serif";

        var maxLabel = formatRate(maxValue);
        var zeroLabel = formatRate(0);
        var leftInset = showScale
            ? Math.ceil(Math.max(ctx.measureText(maxLabel).width, ctx.measureText(zeroLabel).width) + Kirigami.Units.smallSpacing)
            : 0;
        var plotLeft = leftInset;
        var plotTop = showScale ? 2 : 0;
        var plotWidth = Math.max(1, width - plotLeft);
        var plotHeight = Math.max(1, height - (showScale ? 4 : 0));
        baseline = plotTop + plotHeight / 2;

        var scale = Math.max(1, plotHeight / 2 - 6) / maxValue;
        var step = plotWidth / Math.max(1, sampleLimit - 1);
        var topLine = baseline - maxValue * scale;
        var bottomLine = baseline + maxValue * scale;

        ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14);
        ctx.lineWidth = 1;
        ctx.globalAlpha = 1;
        ctx.beginPath();
        ctx.moveTo(plotLeft, topLine);
        ctx.lineTo(width, topLine);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(plotLeft, baseline);
        ctx.lineTo(width, baseline);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(plotLeft, bottomLine);
        ctx.lineTo(width, bottomLine);
        ctx.stroke();

        if (showScale) {
            ctx.fillStyle = scaleColor;
            ctx.textBaseline = "middle";
            ctx.globalAlpha = 0.72;
            ctx.fillText(maxLabel, 0, Math.max(fontSize / 2, topLine));
            ctx.fillText(zeroLabel, 0, baseline);
            ctx.fillText(maxLabel, 0, Math.min(height - fontSize / 2, bottomLine));
        }

        drawSeries(ctx, uploadSamples, uploadColor, baseline, scale, -1, step, plotLeft, plotWidth);
        drawSeries(ctx, downloadSamples, downloadColor, baseline, scale, 1, step, plotLeft, plotWidth);
    }
}
