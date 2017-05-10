
{MyoUI, Theme, mixins, css_utils, react_utils} = require 'myoui'

# adding default css code to the document
require 'myoui/default_fonts'
require 'myoui/default_animations'

theme = new Theme
window.theme = theme
# adding webkitAppRegion to default theme
theme.UIElement.push {WebkitAppRegion: 'no-drag', cursor: 'pointer'}
theme.UIElementContainer = (disabled, useHighlight, forceHighlight)-> [
    if useHighlight
        ':hover': [
            mixins.boxShadow theme.shadows.smallSoft
            background: 'white'
            ]
    if forceHighlight
        [
            mixins.boxShadow theme.shadows.smallSoft
            background: 'white'
        ]
    mixins.transition '250ms', 'background shadow width'
    if disabled
        opacity: 0.5
        pointerEvents: 'none'
    else
        opacity: 1
        pointerEvents:'all'
    minHeight:'auto'
    borderRadius: theme.radius.r3
]

myoui = new MyoUI theme

# Creating instances of myoui elements
text_input = new myoui.TextInput
    label: (maxWidth='calc(100% - 30px)')->
        maxWidth: 'calc(100% - 10px)'
        margin: "0px #{theme.spacing}px"

button = new myoui.Button
    button:
        maxWidth: 200

{div} = react_utils.React.DOM
message = (message, custom_style) ->
    div
        className: 'myoui'
        style:[
            whiteSpace: 'pre-wrap'
            theme.UIElement
            minHeight: 'auto'
            textAlign: 'center'
            fontSize: 20
            fontWeight: 100
            alignSelf: 'center'
            WebkitAppRegion: 'drag'
            custom_style
        ]
        message

components = {
    button:button.ui
    text_input: text_input.ui,
    message
}
sounds = {
    notification: new Audio('sounds/notification.mp3')
}

module.exports = {react_utils, theme, mixins, components, sounds}
