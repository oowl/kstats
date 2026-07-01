import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

ColumnLayout {
    id: metric

    property string title
    property string iconName
    property string primaryValue
    property string secondaryValue
    property string sensorId
    property real percent: 0
    property color accentColor: Kirigami.Theme.highlightColor
    property bool showSparkline: true
    property bool showProgress: true

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: metric.iconName
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }

        Controls.Label {
            text: metric.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Controls.Label {
            text: metric.primaryValue
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
        }
    }

    Local.Sparkline {
        visible: metric.showSparkline
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        sampleValue: metric.percent
        lineColor: metric.accentColor
    }

    Rectangle {
        visible: metric.showProgress
        Layout.fillWidth: true
        Layout.preferredHeight: 4
        radius: height / 2
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(100, metric.percent)) / 100
            radius: parent.radius
            color: metric.accentColor
        }
    }

    RowLayout {
        visible: metric.secondaryValue.length > 0 || metric.sensorId.length > 0
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: metric.secondaryValue
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Controls.Label {
            text: metric.sensorId
            color: Kirigami.Theme.disabledTextColor
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            Layout.maximumWidth: Kirigami.Units.gridUnit * 10
        }
    }
}
