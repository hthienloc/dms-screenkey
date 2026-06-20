import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

PanelWindow {
    id: overlayWindow

    // Dynamic positioning based on settings (e.g. "bottom_center", "top_left", etc.)
    anchors.bottom: daemon.position.includes("bottom")
    anchors.top: daemon.position.includes("top")
    anchors.left: daemon.position.includes("left")
    anchors.right: daemon.position.includes("right")
    anchors.horizontalCenter: daemon.position === "bottom_center" || daemon.position === "top_center"

    // Wayland specific window properties
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None // Absolutely critical: do not steal focus

    // Match window size to container size
    width: cardContainer.width
    height: cardContainer.height
    color: "transparent"

    // Access the daemon (parent)
    readonly property var daemon: parent

    StyledRect {
        id: cardContainer
        
        // Match contents with padding
        width: textLabel.implicitWidth + Theme.spacingXL * 2
        height: textLabel.implicitHeight + Theme.spacingL * 2
        
        // Smooth scaling when content changes
        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }

        radius: Theme.cornerRadiusLarge
        color: Theme.withAlpha(Theme.surface, 0.85) // Elegant glassmorphism
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        // Display with fade-in and scale animations
        opacity: daemon.displayText !== "" ? 1.0 : 0.0
        scale: daemon.displayText !== "" ? 1.0 : 0.9
        
        Behavior on opacity { OpacityAnimator { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        StyledText {
            id: textLabel
            anchors.centerIn: parent
            font.pixelSize: daemon.fontSize
            font.bold: true
            color: Theme.primary
            text: daemon.displayText
        }
    }
}
