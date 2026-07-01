import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import "." as Local

Controls.Pane {
    id: full

    required property var rootItem
    readonly property int currentTab: rootItem.selectedTab

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 27
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 38

    padding: Kirigami.Units.largeSpacing

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Controls.Label {
                    text: i18n("KStats")
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Controls.Label {
                    text: i18nc("@label", "Live system stats")
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    Layout.fillWidth: true
                }
            }

            Controls.ToolButton {
                icon.name: "utilities-system-monitor"
                text: i18nc("@action", "Open System Monitor")
                display: Controls.AbstractButton.IconOnly
                onClicked: full.rootItem.openSystemMonitor()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.055)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing / 2
                spacing: Kirigami.Units.smallSpacing / 2

                Local.TabPill {
                    checked: full.currentTab === 0
                    iconName: "cpu"
                    accentColor: Kirigami.Theme.positiveTextColor
                    text: i18nc("@title:tab", "CPU")
                    onClicked: full.rootItem.selectTab(0)
                }

                Local.TabPill {
                    checked: full.currentTab === 1
                    iconName: "memory"
                    accentColor: Kirigami.Theme.focusColor
                    text: i18nc("@title:tab", "RAM")
                    onClicked: full.rootItem.selectTab(1)
                }

                Local.TabPill {
                    checked: full.currentTab === 2
                    iconName: "video-display"
                    accentColor: Kirigami.Theme.focusColor
                    text: i18nc("@title:tab", "GPU")
                    onClicked: full.rootItem.selectTab(2)
                }

                Local.TabPill {
                    checked: full.currentTab === 3
                    iconName: "network-wired"
                    accentColor: Kirigami.Theme.visitedLinkColor
                    text: i18nc("@title:tab", "NET")
                    onClicked: full.rootItem.selectTab(3)
                }

                Local.TabPill {
                    checked: full.currentTab === 4
                    iconName: "drive-harddisk"
                    accentColor: Kirigami.Theme.neutralTextColor
                    text: i18nc("@title:tab", "DISK")
                    onClicked: full.rootItem.selectTab(4)
                }
            }
        }

        StackLayout {
            currentIndex: full.currentTab
            Layout.fillWidth: true
            Layout.fillHeight: true

            Local.CpuPage {
                rootItem: full.rootItem
            }

            Local.RamPage {
                rootItem: full.rootItem
            }

            Local.GpuPage {
                rootItem: full.rootItem
            }

            Local.NetworkPage {
                rootItem: full.rootItem
            }

            Local.DiskPage {
                rootItem: full.rootItem
            }
        }
    }
}
