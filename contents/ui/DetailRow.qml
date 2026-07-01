import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

RowLayout {
    id: row

    property string label
    property string value

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Controls.Label {
        text: row.label
        color: Kirigami.Theme.disabledTextColor
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    Controls.Label {
        text: row.value
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideMiddle
        Layout.maximumWidth: Kirigami.Units.gridUnit * 12
    }
}
