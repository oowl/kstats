import QtQuick
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami

Item {
    id: root

    property real value: 0
    property string label: ""
    property color accentColor: Kirigami.Theme.focusColor
    property color trackColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
    property real lineWidth: Math.max(5, Math.min(width, height) * 0.11)

    implicitWidth: Kirigami.Units.gridUnit * 5
    implicitHeight: implicitWidth

    onValueChanged: canvas.requestPaint()
    onAccentColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var size = Math.min(width, height);
            if (size <= 0) {
                return;
            }

            var centerX = width / 2;
            var centerY = height / 2;
            var radius = Math.max(1, (size - root.lineWidth) / 2 - 1);
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle + Math.PI * 2 * Math.max(0, Math.min(100, root.value)) / 100;

            ctx.lineWidth = root.lineWidth;
            ctx.lineCap = "round";

            ctx.strokeStyle = root.trackColor;
            ctx.globalAlpha = 1;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false);
            ctx.stroke();

            ctx.strokeStyle = root.accentColor;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
            ctx.stroke();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Controls.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18nc("@label percent value", "%1%", Math.round(Math.max(0, Math.min(100, root.value))))
            color: Kirigami.Theme.textColor
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.25
            font.weight: Font.DemiBold
        }

        Controls.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.label.length > 0
            text: root.label
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
        }
    }
}
