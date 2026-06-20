import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "keyMapper.js" as KeyMapper

PluginComponent {
    id: root

    pluginId: "screenkey"
    pluginService: PluginService

    // Configurable settings
    readonly property bool enabled: root.pluginData.enabled ?? true
    readonly property int fadeTimeout: root.pluginData.fadeTimeout ?? 1500
    readonly property bool showNormalKeys: root.pluginData.showNormalKeys ?? false
    readonly property int fontSize: root.pluginData.fontSize ?? 24
    readonly property string position: root.pluginData.position ?? "bottom_center"
    readonly property string selectedDevicePath: root.pluginData.selectedDevicePath ?? "all"
    readonly property bool showMouseClicks: root.pluginData.showMouseClicks ?? false

    // Output state
    property string displayText: ""
    property string textBuffer: ""

    // Modifiers state
    property bool ctrlActive: false
    property bool shiftActive: false
    property bool altActive: false
    property bool superActive: false

    // Required tools check
    property bool inputToolMissing: false
    property bool notInInputGroup: false
    readonly property bool inputBroken: inputToolMissing || notInInputGroup
    readonly property string requiredTool: selectedDevicePath === "all" ? "libinput" : "evtest"

    Component.onCompleted: {
        checkTools();
    }

    onSelectedDevicePathChanged: {
        inputProc.running = false;
        inputRestartTimer.restart();
    }

    Timer {
        id: inputRestartTimer
        interval: 200
        onTriggered: inputProc.running = true
    }

    Timer {
        id: fadeTimer
        interval: root.fadeTimeout
        onTriggered: {
            root.displayText = "";
            root.textBuffer = "";
        }
    }

    function checkTools() {
        toolCheck.running = false;
        toolCheck.running = true;
        groupCheck.running = false;
        groupCheck.running = true;
    }

    Process {
        id: toolCheck
        command: ["sh", "-c", "command -v " + root.requiredTool + " >/dev/null 2>&1"]
        running: false
        onExited: (exitCode) => {
            root.inputToolMissing = (exitCode !== 0);
        }
    }

    Process {
        id: groupCheck
        command: ["sh", "-c", "id -nG | tr ' ' '\n' | grep -qx input"]
        running: false
        onExited: (exitCode) => {
            root.notInInputGroup = (exitCode !== 0);
        }
    }

    function handleKeyPress(keyName) {
        if (!root.enabled) return;

        // 1. Modifiers tracking
        if (keyName === "KEY_LEFTCTRL" || keyName === "KEY_RIGHTCTRL") {
            root.ctrlActive = true;
            return;
        }
        if (keyName === "KEY_LEFTSHIFT" || keyName === "KEY_RIGHTSHIFT") {
            root.shiftActive = true;
            return;
        }
        if (keyName === "KEY_LEFTALT" || keyName === "KEY_RIGHTALT") {
            root.altActive = true;
            return;
        }
        if (keyName === "KEY_LEFTMETA" || keyName === "KEY_RIGHTMETA") {
            root.superActive = true;
            return;
        }

        fadeTimer.stop();

        // 2. Active modifiers combo logic
        const hasModifiers = root.ctrlActive || root.altActive || root.superActive;
        if (hasModifiers) {
            let combo = [];
            if (root.ctrlActive) combo.push("Ctrl");
            if (root.altActive) combo.push("Alt");
            if (root.shiftActive) combo.push("Shift");
            if (root.superActive) combo.push("Super");
            combo.push(KeyMapper.getDisplayKey(keyName));

            root.textBuffer = ""; // Reset standard typing buffer
            root.displayText = combo.join(" + ");
            fadeTimer.start();
            return;
        }

        // 3. Normal keys typing logic
        if (root.showNormalKeys) {
            const keyChar = KeyMapper.getChar(keyName, root.shiftActive);
            if (keyChar !== "") {
                root.textBuffer += keyChar;
                root.displayText = root.textBuffer;
                fadeTimer.start();
                return;
            }

            // Handles backspace deletion
            if (keyName === "KEY_BACKSPACE") {
                if (root.textBuffer.length > 0) {
                    root.textBuffer = root.textBuffer.slice(0, -1);
                    root.displayText = root.textBuffer;
                } else {
                    root.displayText = "Backspace";
                }
                fadeTimer.start();
                return;
            }

            // Treat other control keys as standalone items
            const label = KeyMapper.getDisplayKey(keyName);
            if (label !== "") {
                root.textBuffer = ""; // Reset buffer
                root.displayText = label;
                fadeTimer.start();
            }
        }
    }

    function handleKeyRelease(keyName) {
        if (keyName === "KEY_LEFTCTRL" || keyName === "KEY_RIGHTCTRL") {
            root.ctrlActive = false;
        } else if (keyName === "KEY_LEFTSHIFT" || keyName === "KEY_RIGHTSHIFT") {
            root.shiftActive = false;
        } else if (keyName === "KEY_LEFTALT" || keyName === "KEY_RIGHTALT") {
            root.altActive = false;
        } else if (keyName === "KEY_LEFTMETA" || keyName === "KEY_RIGHTMETA") {
            root.superActive = false;
        }
    }

    function handleMouseClick(buttonName) {
        if (!root.enabled || !root.showMouseClicks) return;
        fadeTimer.stop();
        root.textBuffer = "";
        root.displayText = buttonName;
        fadeTimer.start();
    }

    // Input monitoring process
    Process {
        id: inputProc
        command: {
            const cmd = selectedDevicePath === "all"
                ? ["libinput", "debug-events", "--show-keycodes"]
                : ["evtest", selectedDevicePath];
            console.log("[Screenkey] Starting input process:", JSON.stringify(cmd));
            return cmd;
        }
        running: root.enabled && !root.inputToolMissing

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("EV_KEY")) {
                    const keyMatch = data.match(/(KEY_[A-Z0-9_]+)/);
                    if (keyMatch) {
                        const keyName = keyMatch[1];
                        if (data.includes("value 1")) {
                            root.handleKeyPress(keyName);
                        } else if (data.includes("value 0")) {
                            root.handleKeyRelease(keyName);
                        }
                    }
                } else if (data.includes("KEYBOARD_KEY")) {
                    const keyMatch = data.match(/(KEY_[A-Z0-9_]+)/);
                    if (keyMatch) {
                        const keyName = keyMatch[1];
                        if (data.includes("pressed")) {
                            root.handleKeyPress(keyName);
                        } else if (data.includes("released")) {
                            root.handleKeyRelease(keyName);
                        }
                    }
                } else if (root.showMouseClicks && data.includes("POINTER_BUTTON")) {
                    if (data.includes("pressed")) {
                        let btnName = "Mouse Click";
                        if (data.includes("BTN_LEFT") || data.includes("(272)")) btnName = "LMB Click";
                        else if (data.includes("BTN_RIGHT") || data.includes("(273)")) btnName = "RMB Click";
                        else if (data.includes("BTN_MIDDLE") || data.includes("(274)")) btnName = "MMB Click";
                        root.handleMouseClick(btnName);
                    }
                }
            }
        }

        stderr: StdioCollector {}
    }

    // Floating overlay window instance
    ScreenkeyOverlay {
        id: overlay
        daemon: root
        visible: root.enabled && root.displayText !== ""
    }
}
