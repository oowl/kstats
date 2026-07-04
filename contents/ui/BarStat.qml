import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

RowLayout {
    id: stat

    property string label
    property string value
    property real percent: 0
    property color accentColor: Kirigami.Theme.highlightColor
    property bool showMeter: true
    property string previewMode: "sparkline"
    readonly property real labelWidth: Math.max(labelText.implicitWidth, stat.label.length <= 1 ? Kirigami.Units.gridUnit * 0.7 : Kirigami.Units.gridUnit * 1.25)
    readonly property real valueWidth: showMeter ? valueMetrics.width + 1 : Kirigami.Units.gridUnit * 3
    readonly property real previewWidth: showMeter
        ? (previewMode === "bar" ? Kirigami.Units.gridUnit * 0.85 : Kirigami.Units.gridUnit * 2.2)
        : 0
    readonly property real fixedWidth: labelWidth + valueWidth + (showMeter ? previewWidth + spacing * 2 : spacing)

    spacing: Math.max(1, Kirigami.Units.smallSpacing / 4)
    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: fixedWidth
    Layout.preferredWidth: fixedWidth
    Layout.maximumWidth: fixedWidth
    implicitWidth: fixedWidth

    TextMetrics {
        id: valueMetrics

        font: valueText.font
        text: stat.showMeter ? "100.0%" : stat.value
    }

    Controls.Label {
        id: labelText

        text: stat.label
        color: stat.accentColor
        elide: Text.ElideRight
        font.pixelSize: (plasmoid.configuration.barLabelFontSize != 0) ? plasmoid.configuration.barLabelFontSize : Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: stat.labelWidth
        Layout.preferredWidth: stat.labelWidth
        Layout.maximumWidth: stat.labelWidth
    }

    Rectangle {
        visible: stat.showMeter
        clip: true
        Layout.minimumWidth: stat.previewWidth
        Layout.preferredWidth: stat.previewWidth
        Layout.maximumWidth: stat.previewWidth
        Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit * 0.9, stat.height - Kirigami.Units.smallSpacing)
        radius: 2
        color: Qt.rgba(0, 0, 0, 0.86)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.32)

        Rectangle {
            visible: stat.previewMode === "sparkline"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0, Math.min(100, stat.percent)) / 100
            color: Qt.rgba(stat.accentColor.r, stat.accentColor.g, stat.accentColor.b, 0.28)
        }

        Rectangle {
            visible: stat.previewMode === "bar"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            anchors.bottomMargin: 2
            height: Math.max(0, parent.height - 4) * Math.max(0, Math.min(100, stat.percent)) / 100
            color: Qt.rgba(stat.accentColor.r, stat.accentColor.g, stat.accentColor.b, 0.72)
        }

        Local.Sparkline {
            visible: stat.previewMode === "sparkline"
            anchors.fill: parent
            anchors.margins: 2
            sampleValue: stat.percent
            sampleLimit: 24
            lineColor: stat.accentColor
            showFill: true
        }
    }

    Controls.Label {
        id: valueText

        text: stat.value
        color: Kirigami.Theme.textColor
        elide: Text.ElideRight
        font.pixelSize: (plasmoid.configuration.barValueFontSize != 0) ? plasmoid.configuration.barValueFontSize : Kirigami.Theme.smallFont.pixelSize
        font.features: { "tnum": 1 }
        horizontalAlignment: Text.AlignRight
        Layout.minimumWidth: stat.valueWidth
        Layout.preferredWidth: stat.valueWidth
        Layout.maximumWidth: stat.valueWidth
    }
}
