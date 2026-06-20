import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import "./dms-common"

PluginSettings {
    id: root

    pluginId: "screenkey"

    // Keyboard devices scanned dynamically
    property var deviceOptions: [{ label: "All Keyboards (Auto)", value: "all" }]

    Component.onCompleted: {
        scanDevices();
    }

    function scanDevices() {
        const script = `
import os, json, re

include_pattern = "kanata"
exclude_pattern = [
    "power button", "video bus", "speaker", "headphone",
    "lid switch", "touchpad", "extra buttons", "uinput",
    "server", "hitune", "inphic", "instant", "webcam", "video"
]

devs = []
if os.path.exists('/proc/bus/input/devices'):
    with open('/proc/bus/input/devices') as f:
        content = f.read()
        
    sections = content.strip().split('\\n\\n')
    for section in sections:
        name = ""
        handlers = ""
        for line in section.split('\\n'):
            if line.startswith('N: Name='):
                name = re.search(r'Name="([^"]+)"', line).group(1)
            elif line.startswith('H: Handlers='):
                handlers = line.split('=')[1]
        
        if name and handlers:
            lower_name = name.lower()
            is_included = include_pattern in lower_name
            is_excluded = any(x in lower_name for x in exclude_pattern)
            
            # Check for kbd handler and filter out non-keyboards
            if 'kbd' in handlers and (is_included or ('mouse' not in handlers and not is_excluded)):
                # Find event path
                event_match = re.search(r'event(\\d+)', handlers)
                if event_match:
                    event_path = "/dev/input/event" + event_match.group(1)
                    devs.append((name + " (" + event_path.split('/')[-1] + ")", event_path))

print(json.dumps(devs))
`;
        Proc.runCommand("screenkey.scanDevices", ["python3", "-c", script], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const data = JSON.parse(stdout.trim());
                var options = [{ label: "All Keyboards (Auto)", value: "all" }];
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                }
                root.deviceOptions = options;
            } catch(e) {
                console.warn("[Screenkey] Failed to parse device scanner output:", e);
            }
        });
    }

    SettingsCard {
        id: generalSection
        SectionTitle {
            text: I18n.tr("General Settings")
            icon: "tune"
            showReset: enabledSetting.isDirty || fadeTimeoutSetting.isDirty || fontSizeSetting.isDirty
            onResetClicked: {
                enabledSetting.resetToDefault();
                fadeTimeoutSetting.resetToDefault();
                fontSizeSetting.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: enabledSetting
            settingKey: "enabled"
            label: I18n.tr("Enable Visualizer")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: fadeTimeoutSetting
            settingKey: "fadeTimeout"
            label: I18n.tr("Fade Timeout")
            description: I18n.tr("Inactivity duration before overlay disappears")
            minimum: 500
            maximum: 5000
            defaultValue: 1500
            unit: "ms"
            leftLabel: "500ms"
            rightLabel: "5000ms"
        }

        Separator {}

        SliderSettingPlus {
            id: fontSizeSetting
            settingKey: "fontSize"
            label: I18n.tr("Font Size")
            description: I18n.tr("Size of the text on overlay")
            minimum: 16
            maximum: 64
            defaultValue: 24
            unit: "px"
            leftLabel: "16px"
            rightLabel: "64px"
        }
    }

    SettingsCard {
        id: appearanceSection
        SectionTitle {
            text: I18n.tr("Layout & Behavior")
            icon: "display_settings"
            showReset: positionSetting.isDirty || showNormalKeysSetting.isDirty || showMouseClicksSetting.isDirty
            onResetClicked: {
                positionSetting.resetToDefault();
                showNormalKeysSetting.resetToDefault();
                showMouseClicksSetting.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: positionSetting
            settingKey: "position"
            label: I18n.tr("Display Position")
            options: [
                { label: I18n.tr("Top Left"), value: "top_left" },
                { label: I18n.tr("Top Center"), value: "top_center" },
                { label: I18n.tr("Top Right"), value: "top_right" },
                { label: I18n.tr("Bottom Left"), value: "bottom_left" },
                { label: I18n.tr("Bottom Center"), value: "bottom_center" },
                { label: I18n.tr("Bottom Right"), value: "bottom_right" }
            ]
            defaultValue: "bottom_center"
        }

        Separator {}

        ToggleSettingPlus {
            id: showNormalKeysSetting
            settingKey: "showNormalKeys"
            label: I18n.tr("Show Normal Keystrokes")
            description: I18n.tr("Toggle to display normal letters instead of just modifier shortcuts")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showMouseClicksSetting
            settingKey: "showMouseClicks"
            label: I18n.tr("Show Mouse Clicks")
            description: I18n.tr("Toggle to display mouse click events")
            defaultValue: false
        }
    }

    SettingsCard {
        id: deviceSection
        SectionTitle {
            text: I18n.tr("Input Device")
            icon: "keyboard"
            showReset: selectedDevicePathSetting.isDirty
            onResetClicked: {
                selectedDevicePathSetting.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: selectedDevicePathSetting
            settingKey: "selectedDevicePath"
            label: I18n.tr("Keyboard Device")
            options: root.deviceOptions
            defaultValue: "all"
        }
    }

    SettingsCard {
        id: ipcSection
        SectionTitle {
            id: ipcTitle
            text: I18n.tr("IPC Commands")
            icon: "terminal"
            collapsible: true
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: ipcTitle.isExpanded

            Repeater {
                model: [
                    { text: "dms ipc screenkey toggle", label: I18n.tr("Toggle visualizer") },
                    { text: "dms ipc screenkey enable", label: I18n.tr("Enable visualizer") },
                    { text: "dms ipc screenkey disable", label: I18n.tr("Disable visualizer") }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.text
                }
            }
        }
    }

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("Displays keystrokes on an always-on-top floating screen overlay."),
                I18n.tr("Key combinations are rendered as visual keycaps, and standard typing as stream text."),
                I18n.tr("Ensure your user belongs to the <b>input</b> group to read keyboard events without root.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/loccun/dms-screenkey"
    }
}
