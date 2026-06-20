import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    pluginId: "screenkey"
    pluginService: PluginService

    // Control Center UI reads enabled state directly from settings
    readonly property bool enabled: root.pluginData.enabled ?? true

    Component.onCompleted: {
        // Register in PluginService
        if (!pluginService.pluginInstances[pluginId]) {
            const newInstances = Object.assign({}, pluginService.pluginInstances);
            newInstances[pluginId] = root;
            pluginService.pluginInstances = newInstances;
        }
    }

    Component.onDestruction: {
        if (pluginService.pluginInstances[pluginId] === root) {
            const newInstances = Object.assign({}, pluginService.pluginInstances);
            delete newInstances[pluginId];
            pluginService.pluginInstances = newInstances;
        }
    }

    // Control Center Integration
    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: "Screenkey"
    ccWidgetSecondaryText: root.enabled ? "Active" : "Disabled"
    ccWidgetIsActive: root.enabled
    onCcWidgetToggled: {
        root.saveSetting("enabled", !root.enabled);
    }

    function saveSetting(key, value) {
        try {
            pluginService.savePluginData(pluginId, key, value);
            if (pluginData) pluginData[key] = value;
        } catch(e) {
            console.warn("[Screenkey] Failed to save setting:", key, e);
        }
    }
}
