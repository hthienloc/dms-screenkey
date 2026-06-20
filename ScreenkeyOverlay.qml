import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

PanelWindow {
    id: overlayWindow

    property var daemon: null
    readonly property bool isCentered: daemon ? (daemon.position === "bottom_center" || daemon.position === "top_center") : false
    readonly property bool isMouseClick: daemon ? (daemon.displayText === "LMB Click" || daemon.displayText === "RMB Click" || daemon.displayText === "MMB Click") : false

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

        // Display with dynamic animations based on settings
        opacity: (daemon && daemon.displayText !== "") ? 1.0 : 0.0
        scale: (daemon && daemon.displayText !== "") ? 1.0 : (daemon && daemon.animationType === "zoom" ? 0.9 : 1.0)

        property real yOffset: {
            if (!daemon || daemon.animationType !== "slide") return 0;
            const isVisible = daemon.displayText !== "";
            if (isVisible) return 0;
            const isTop = daemon.position.includes("top");
            return isTop ? -20 : 20;
        }

        transform: Translate {
            y: cardContainer.yOffset
        }

        Behavior on opacity {
            enabled: daemon && daemon.animationType !== "none"
            OpacityAnimator { duration: 150 }
        }

        Behavior on scale {
            enabled: daemon && daemon.animationType === "zoom"
            NumberAnimation { duration: 150; easing.type: Easing.OutBack }
        }

        Behavior on yOffset {
            enabled: daemon && daemon.animationType === "slide"
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

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

            // Render mouse click indicator
            Row {
                id: mouseIcon
                visible: overlayWindow.isMouseClick
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS
                height: overlayWindow.unifiedHeight

                readonly property bool isLeft: daemon ? daemon.displayText === "LMB Click" : false
                readonly property bool isRight: daemon ? daemon.displayText === "RMB Click" : false
                readonly property bool isMiddle: daemon ? daemon.displayText === "MMB Click" : false

                Rectangle {
                    width: 14
                    height: 22
                    radius: 7
                    color: "transparent"
                    border.color: Theme.outline
                    border.width: 1.5
                    anchors.verticalCenter: parent.verticalCenter

                    // Left click indicator
                    Rectangle {
                        width: 7
                        height: 11
                        radius: 3
                        color: mouseIcon.isLeft ? Theme.primary : "transparent"
                        border.color: Theme.outline
                        border.width: 1
                        anchors.left: parent.left
                        anchors.top: parent.top
                    }

                    // Right click indicator
                    Rectangle {
                        width: 7
                        height: 11
                        radius: 3
                        color: mouseIcon.isRight ? Theme.primary : "transparent"
                        border.color: Theme.outline
                        border.width: 1
                        anchors.right: parent.right
                        anchors.top: parent.top
                    }

                    // Scroll wheel (middle button)
                    Rectangle {
                        width: 2
                        height: 5
                        radius: 1
                        color: mouseIcon.isMiddle ? Theme.primary : Theme.outline
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 3
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: daemon ? daemon.fontSize : 24
                    font.bold: true
                    color: Theme.primary
                    text: mouseIcon.isLeft ? "L" : (mouseIcon.isRight ? "R" : "M")
                }
            }

            // Render standard text for normal typing
            StyledText {
                visible: !contentRow.isCombo && !overlayWindow.isMouseClick
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: daemon ? daemon.fontSize : 24
                font.bold: true
                color: Theme.primary
                text: daemon ? daemon.displayText : ""
                
                // Force height matching keycaps to avoid container height jump
                height: overlayWindow.unifiedHeight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
