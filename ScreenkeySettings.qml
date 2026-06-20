import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "screenkey"

    ToggleSetting {
        settingKey: "enabled"
        label: qsTr("Enable Visualizer")
        description: qsTr("Show keystrokes on the screen overlay")
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "position"
        label: qsTr("Display Position")
        description: qsTr("Where the overlay card appears on screen")
        options: [
            { label: qsTr("Top Left"), value: "top_left" },
            { label: qsTr("Top Center"), value: "top_center" },
            { label: qsTr("Top Right"), value: "top_right" },
            { label: qsTr("Bottom Left"), value: "bottom_left" },
            { label: qsTr("Bottom Center"), value: "bottom_center" },
            { label: qsTr("Bottom Right"), value: "bottom_right" }
        ]
        defaultValue: "bottom_center"
    }

    SliderSetting {
        settingKey: "fadeTimeout"
        label: qsTr("Fade Timeout")
        description: qsTr("Inactivity duration (ms) before overlay disappears")
        minimum: 500
        maximum: 5000
        defaultValue: 1500
    }

    SliderSetting {
        settingKey: "fontSize"
        label: qsTr("Font Size")
        description: qsTr("Size of the text on overlay")
        minimum: 16
        maximum: 64
        defaultValue: 24
    }

    ToggleSetting {
        settingKey: "showNormalKeys"
        label: qsTr("Show Normal Keystrokes")
        description: qsTr("Toggle to display normal letters and words instead of just modifier key shortcuts")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showMouseClicks"
        label: qsTr("Show Mouse Clicks")
        description: qsTr("Toggle to display left, middle, and right mouse click events")
        defaultValue: false
    }
}
