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
        id: layoutSection
        SectionTitle {
            text: I18n.tr("Layout & Animations")
            icon: "display_settings"
            showReset: positionSetting.isDirty || animationTypeSetting.isDirty || roundedKeycapsSetting.isDirty || overlayOpacitySetting.isDirty || charLimitSetting.isDirty || textColorSetting.isDirty || keycapTextColorSetting.isDirty
            onResetClicked: {
                positionSetting.resetToDefault();
                animationTypeSetting.resetToDefault();
                roundedKeycapsSetting.resetToDefault();
                overlayOpacitySetting.resetToDefault();
                charLimitSetting.resetToDefault();
                textColorSetting.resetToDefault();
                keycapTextColorSetting.resetToDefault();
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

        SelectionSettingPlus {
            id: animationTypeSetting
            settingKey: "animationType"
            label: I18n.tr("Animation Style")
            options: [
                { label: I18n.tr("Zoom"), value: "zoom" },
                { label: I18n.tr("Fade Only"), value: "fade" },
                { label: I18n.tr("Slide"), value: "slide" },
                { label: I18n.tr("None"), value: "none" }
            ]
            defaultValue: "none"
        }

        Separator {}

        ToggleSettingPlus {
            id: roundedKeycapsSetting
            settingKey: "roundedKeycaps"
            label: I18n.tr("Rounded Keycap Corners")
            description: I18n.tr("Toggle between rounded or sharp square keycap corners")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: overlayOpacitySetting
            settingKey: "overlayOpacity"
            label: I18n.tr("Overlay Opacity")
            description: I18n.tr("Adjust the transparency of the overlay visualizer")
            minimum: 10
            maximum: 100
            defaultValue: 90
            unit: "%"
            leftLabel: "10%"
            rightLabel: "100%"
        }

        Separator {}

        SliderSettingPlus {
            id: charLimitSetting
            settingKey: "charLimit"
            label: I18n.tr("Normal Typing Limit")
            description: I18n.tr("Maximum characters buffer shown for normal text")
            minimum: 5
            maximum: 50
            defaultValue: 20
            unit: "chars"
            leftLabel: "5"
            rightLabel: "50"
        }

        Separator {}

        ColorDropdownSettingPlus {
            id: textColorSetting
            settingKey: "textColor"
            label: I18n.tr("Normal Text Color")
            defaultValueMode: "default"
        }

        Separator {}

        ColorDropdownSettingPlus {
            id: keycapTextColorSetting
            settingKey: "keycapTextColor"
            label: I18n.tr("Keycap & Mouse Color")
            defaultValueMode: "default"
        }
    }

    SettingsCard {
        id: visibilitySection
        SectionTitle {
            text: I18n.tr("Visibility Options")
            icon: "visibility"
            showReset: showShortcutsSetting.isDirty || showNormalKeysSetting.isDirty || showMouseClicksSetting.isDirty
            onResetClicked: {
                showShortcutsSetting.resetToDefault();
                showNormalKeysSetting.resetToDefault();
                showMouseClicksSetting.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showShortcutsSetting
            settingKey: "showShortcuts"
            label: I18n.tr("Show Key Combinations")
            description: I18n.tr("Toggle to display modifier shortcuts (e.g., Ctrl + Alt + T)")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showNormalKeysSetting
            settingKey: "showNormalKeys"
            label: I18n.tr("Show Normal Keystrokes")
            description: I18n.tr("Toggle to display normal letters instead of just modifier shortcuts")
            defaultValue: false
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
