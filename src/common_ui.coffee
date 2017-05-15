
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
theme.colors.light_green = 'rgb(200, 244, 187)'
theme.colors.light_orange = 'rgb(255, 181, 132)'
theme.colors.orange = 'rgb(255, 171, 112)'



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
    sec = Math.floor (time / 1000) % 60
    min = Math.floor (time / (1000*60)) % 60
    hours = Math.floor (time / (1000*60*60)) % 24
    days = Math.floor time / (1000*60*60*24)

    formated_time = ''
    if days or hours or min or sec
        if not(hours or days)
            formated_time = "#{sec} sec"
        if days or hours or min
            if not (days)
                formated_time = "#{min} min " + formated_time
            if days or hours
                formated_time = "#{hours} hour#{if hours > 1 then 's' else ''} " + formated_time
                if days
                    formated_time = "#{days} day#{if days > 1 then 's' else ''} " + formated_time
    return formated_time

module.exports = {react_utils, theme, mixins, components, sounds, markdown, format_time}
