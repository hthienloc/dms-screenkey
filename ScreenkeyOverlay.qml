import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

PanelWindow {
    id: overlayWindow

    property var daemon: null
    readonly property bool isCentered: daemon ? (daemon.position === "bottom_center" || daemon.position === "top_center") : false

    // Dynamic positioning based on settings (e.g. "bottom_center", "top_left", etc.)
    anchors.bottom: daemon ? daemon.position.includes("bottom") : false
    anchors.top: daemon ? daemon.position.includes("top") : false
    anchors.left: isCentered || (daemon ? daemon.position.includes("left") : false)
    anchors.right: isCentered || (daemon ? daemon.position.includes("right") : false)

    // Wayland specific window properties
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None // Absolutely critical: do not steal focus
    WlrLayershell.exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore

    // Add safety margins from screen edges
    WlrLayershell.margins {
        left: 24
        right: 24
        top: 24
        bottom: 24
    }

    // Dummy text to calculate a unified height based on current font size
    StyledText {
        id: dummyText
        visible: false
        font.pixelSize: daemon ? daemon.fontSize : 24
        font.bold: true
        text: "A"
    }

    readonly property real unifiedHeight: dummyText.implicitHeight + Theme.spacingXS * 2

    // Match window size to container size
    implicitWidth: isCentered ? (screen ? screen.width : 1920) : cardContainer.width
    implicitHeight: cardContainer.height
    color: "transparent"

    StyledRect {
        id: cardContainer
        
        // Match contents with padding
        width: contentRow.implicitWidth + Theme.spacingXL * 2
        height: contentRow.implicitHeight + Theme.spacingL * 2
        
        anchors.top: (daemon && daemon.position.includes("top")) ? parent.top : undefined
        anchors.bottom: (daemon && daemon.position.includes("bottom")) ? parent.bottom : undefined
        anchors.left: (daemon && daemon.position.includes("left")) ? parent.left : undefined
        anchors.right: (daemon && daemon.position.includes("right")) ? parent.right : undefined
        anchors.horizontalCenter: isCentered ? parent.horizontalCenter : undefined

        // Smooth scaling when content changes
        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }

        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surface, 0.85) // Elegant glassmorphism
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        // Display with fade-in and scale animations
        opacity: (daemon && daemon.displayText !== "") ? 1.0 : 0.0
        scale: (daemon && daemon.displayText !== "") ? 1.0 : 0.9
        
        Behavior on opacity { OpacityAnimator { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: Theme.spacingS

            readonly property bool isCombo: daemon ? daemon.displayText.includes(" + ") : false
            readonly property var keysList: isCombo ? daemon.displayText.split(" + ") : []

            // Render keycaps for combinations
            Repeater {
                model: contentRow.isCombo ? contentRow.keysList : 0
                delegate: Row {
                    spacing: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter

                    StyledRect {
                        anchors.verticalCenter: parent.verticalCenter
                        width: keycapText.implicitWidth + Theme.spacingM * 2
                        height: overlayWindow.unifiedHeight
                        radius: Theme.cornerRadiusSmall
                        color: Theme.surfaceContainerHighest
                        border.color: Theme.withAlpha(Theme.outline, 0.25)
                        border.width: 1

                        StyledText {
                            id: keycapText
                            anchors.centerIn: parent
                            font.pixelSize: daemon ? daemon.fontSize : 24
                            font.bold: true
                            color: Theme.primary
                            text: modelData
                        }
                    }

                    // Render "+" separator unless it is the last item
                    StyledText {
                        visible: index < contentRow.keysList.length - 1
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: daemon ? daemon.fontSize : 24
                        font.bold: true
                        color: Theme.outline
                        text: "+"
                    }
                }
            }

            // Render standard text for normal typing
            StyledText {
                visible: !contentRow.isCombo
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: daemon ? daemon.fontSize : 24
                font.bold: true
                color: Theme.primary
                text: daemon ? daemon.displayText : ""
                
                // Force implicit height matching keycaps to avoid container height jump
                implicitHeight: overlayWindow.unifiedHeight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
