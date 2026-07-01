import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Controls.AbstractButton {
    id: tab

    property string iconName
    property color accentColor: Kirigami.Theme.highlightColor

    hoverEnabled: true
    checkable: true
    implicitHeight: Kirigami.Units.gridUnit * 2
    Layout.fillWidth: true

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: tab.checked
            ? Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, 0.16)
            : tab.hovered
                ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
                : "transparent"
        border.width: tab.checked ? 1 : 0
        border.color: Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, 0.45)

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing / 2

        Item {
            Layout.fillWidth: true
        }

        Kirigami.Icon {
            source: tab.iconName
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            color: tab.checked ? tab.accentColor : Kirigami.Theme.disabledTextColor
        }

        Controls.Label {
            text: tab.text
            color: tab.checked ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.weight: tab.checked ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
