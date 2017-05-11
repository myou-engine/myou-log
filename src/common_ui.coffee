
{MyoUI, Theme, mixins, css_utils, react_utils} = require 'myoui'

# adding default css code to the document
require 'myoui/default_fonts'
require 'myoui/default_animations'
markdown = react_utils.React.createFactory require('react-remarkable')
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

theme.colors.green = 'rgb(194, 228, 157)'
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

format_time = (time=Date.now())->
    pre_formated_time = new Date(time).toTimeString().split(' ')[0].split(':')
    hours = parseInt(pre_formated_time[0]) - 1 # WHY???
    min = parseInt(pre_formated_time[1])
    sec = parseInt(pre_formated_time[2])


    if hours or min or sec
        formated_time = "#{sec} sec"
        if hours or min
            formated_time = "#{min} min " + formated_time
            if hours
                formated_time = "#{hours} hours " + formated_time

    return formated_time

module.exports = {react_utils, theme, mixins, components, sounds, markdown, format_time}
