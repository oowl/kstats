import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.process as Process

ColumnLayout {
    id: root

    property string metric: "cpu"
    property int limit: 5
    property int refreshInterval: 1500
    property var applications: []
    property real maxValue: 1
    property real rowHeight: Kirigami.Units.gridUnit * 1.82
    property bool reserveRowSpace: true
    readonly property int visibleRowSlots: reserveRowSpace ? Math.max(1, limit) : Math.max(1, applications.length)
    readonly property real listAreaHeight: visibleRowSlots * rowHeight + Math.max(0, visibleRowSlots - 1) * spacing

    spacing: Kirigami.Units.smallSpacing * 1.2
    Layout.fillWidth: true
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    clip: true
    implicitHeight: header.implicitHeight + root.spacing + root.listAreaHeight

    function metricTitle() {
        if (metric === "memory") {
            return i18nc("@label", "RAM");
        }
        if (metric === "network") {
            return i18nc("@label", "NET");
        }
        if (metric === "disk") {
            return i18nc("@label", "DISK");
        }
        return i18nc("@label", "CPU");
    }

    function formatBytes(bytes) {
        var value = Math.max(0, Number(bytes) || 0);
        var gib = value / 1073741824;
        if (gib >= 1) {
            return i18nc("@label data in gigabytes", "%1 GB", gib.toFixed(gib >= 10 ? 1 : 2));
        }

        var mib = value / 1048576;
        if (mib >= 1) {
            return i18nc("@label data in megabytes", "%1 MB", mib.toFixed(mib >= 10 ? 0 : 1));
        }

        return i18nc("@label data in kilobytes", "%1 KB", Math.round(value / 1024));
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

    function columnIndex(attribute) {
        return appModel.enabledAttributes.indexOf(attribute);
    }

    function valueAt(row, attribute, defaultValue) {
        var column = columnIndex(attribute);
        if (column < 0) {
            return defaultValue;
        }

        var value = appModel.data(appModel.index(row, column), Process.ProcessDataModel.Value);
        return value === undefined || value === null ? defaultValue : value;
    }

    function pidsAt(row) {
        var pids = appModel.data(appModel.index(row, 0), Process.ProcessDataModel.PIDs);
        return pids || [];
    }

    function numeric(value) {
        var parsed = Number(value);
        return isFinite(parsed) ? parsed : 0;
    }

    function rebuild() {
        if (!appModel.available) {
            root.applications = [];
            root.maxValue = 1;
            return;
        }

        var rows = [];
        var maximum = 1;
        var rowCount = appModel.rowCount();

        for (var row = 0; row < rowCount; row++) {
            var name = String(valueAt(row, "appName", ""));
            var iconName = String(valueAt(row, "iconName", "application-x-executable"));
            var menuId = String(valueAt(row, "menuId", ""));
            var cpu = numeric(valueAt(row, "usage", 0));
            var memoryBytes = numeric(valueAt(row, "memory", 0)) * 1024;
            var download = numeric(valueAt(row, "netInbound", 0));
            var upload = numeric(valueAt(row, "netOutbound", 0));
            var read = numeric(valueAt(row, "ioCharactersActuallyReadRate", 0));
            var write = numeric(valueAt(row, "ioCharactersActuallyWrittenRate", 0));
            var pids = pidsAt(row);

            if (name.length === 0 || pids.length === 0) {
                continue;
            }

            var metricValue = cpu;
            var valueText = i18nc("@label cpu percent", "%1%", cpu.toFixed(1));
            var subtitle = i18ncp("@label application process count and memory", "%1 process · %2", "%1 processes · %2",
                pids.length,
                formatBytes(memoryBytes));

            if (metric === "memory") {
                metricValue = memoryBytes;
                valueText = formatBytes(memoryBytes);
                subtitle = i18ncp("@label application process count and cpu", "%1 process · %2% CPU", "%1 processes · %2% CPU",
                    pids.length,
                    cpu.toFixed(1));
            } else if (metric === "network") {
                metricValue = download + upload;
                valueText = formatRate(download);
                subtitle = i18nc("@label network upload rate", "Upload %1", formatRate(upload));
            } else if (metric === "disk") {
                metricValue = read + write;
                valueText = formatRate(read);
                subtitle = i18nc("@label disk write rate", "Write %1", formatRate(write));
            }

            maximum = Math.max(maximum, metricValue);
            rows.push({
                name: name,
                iconName: iconName.length > 0 ? iconName : "application-x-executable",
                menuId: menuId,
                value: metricValue,
                valueText: valueText,
                subtitle: subtitle
            });
        }

        rows.sort(function(left, right) {
            return right.value - left.value;
        });

        root.maxValue = maximum;
        root.applications = rows.slice(0, root.limit);
    }

    Component.onCompleted: rebuild()
    onMetricChanged: rebuild()
    onVisibleChanged: if (visible) {
        rebuild();
    }

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: root.visible
        triggeredOnStart: false
        onTriggered: root.rebuild()
    }

    Connections {
        target: appModel
        function onRowsInserted() { root.rebuild(); }
        function onRowsRemoved() { root.rebuild(); }
        function onModelReset() { root.rebuild(); }
        function onLayoutChanged() { root.rebuild(); }
    }

    Process.ApplicationDataModel {
        id: appModel

        property var requiredAttributes: [
            "iconName",
            "appName",
            "menuId",
            "usage",
            "memory",
            "netInbound",
            "netOutbound",
            "ioCharactersActuallyReadRate",
            "ioCharactersActuallyWrittenRate"
        ]

        enabled: root.visible

        cgroupMapping: {
            "session.slice": "services",
            "background.slice": "services",
            "org.a11y.atspi.Registry": "services",
            "org.kde.discover.notifier": "services",
            "geoclue": "services",
            "org.kde.kunifiedpush": "services",
            "dconf.service": "services",
            "flatpak-session-helper.service": "services",
            "gpg-agent.service": "services",
            "org.kde.xwaylandvideobridge": "services",
            "org.kde.kalendarac": "services",
            "xdg-desktop-portal-gtk.service": "services",
            "org.kde.kdeconnect": "services",
            "org.kde.kwalletd6": "services",
            "org.kde.kclockd": "services"
        }

        applicationOverrides: {
            "services": {
                "menuId": "services",
                "appName": i18nc("@label", "Background Services"),
                "iconName": "preferences-system-services"
            }
        }

        enabledAttributes: {
            var result = [];
            for (var i = 0; i < requiredAttributes.length; i++) {
                if (availableAttributes.indexOf(requiredAttributes[i]) >= 0) {
                    result.push(requiredAttributes[i]);
                }
            }
            return result;
        }
    }

    RowLayout {
        id: header

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Controls.Label {
            text: i18nc("@label", "Top Applications")
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        Controls.Label {
            text: root.metricTitle()
            color: Kirigami.Theme.disabledTextColor
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }
    }

    Item {
        id: listArea

        Layout.fillWidth: true
        Layout.preferredHeight: root.listAreaHeight
        Layout.minimumHeight: root.listAreaHeight
        clip: true

        Column {
            id: rowsColumn

            width: parent.width
            spacing: root.spacing

            Repeater {
                model: root.applications

                delegate: Rectangle {
                    required property var modelData

                    width: rowsColumn.width
                    height: root.rowHeight
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.035)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            source: modelData.iconName
                            fallback: "application-x-executable"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Layout.preferredWidth
                        }

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Controls.Label {
                                text: modelData.name
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Controls.Label {
                                text: modelData.subtitle
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                            Layout.preferredHeight: 4
                            radius: height / 2
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.max(0, Math.min(1, modelData.value / root.maxValue))
                                radius: parent.radius
                                color: root.metric === "disk"
                                    ? Kirigami.Theme.neutralTextColor
                                    : root.metric === "memory" || root.metric === "network"
                                        ? Kirigami.Theme.focusColor
                                        : Kirigami.Theme.positiveTextColor
                            }
                        }

                        Controls.Label {
                            text: modelData.valueText
                            horizontalAlignment: Text.AlignRight
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                        }
                    }
                }
            }
        }

        Controls.Label {
            id: emptyState

            visible: root.applications.length === 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Kirigami.Units.smallSpacing
            text: appModel.available
                ? i18nc("@info:status", "No application data yet")
                : i18nc("@info:status", "Applications view is unsupported on this system")
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
        }
    }
}
