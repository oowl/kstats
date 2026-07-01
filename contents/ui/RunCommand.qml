import QtQuick
import org.kde.plasma.plasma5support as P5Support

P5Support.DataSource {
    id: dataSource

    property var callbacks: ({})

    signal exited(string command, int exitCode, int exitStatus, string stdout, string stderr)

    function exec(command, callback) {
        if (callback && typeof callback === "function") {
            callbacks[command] = callback;
        }
        dataSource.connectSource(command);
    }

    onExited: function(command, exitCode, exitStatus, stdout, stderr) {
        if (command in callbacks) {
            callbacks[command]({
                command: command,
                exitCode: exitCode,
                exitStatus: exitStatus,
                stdout: stdout || "",
                stderr: stderr || ""
            });
            delete callbacks[command];
        }
    }

    engine: "executable"
    connectedSources: []

    onNewData: function(source, data) {
        exited(source,
            data["exit code"],
            data["exit status"],
            data["stdout"],
            data["stderr"]);
        disconnectSource(source);
    }
}
