
{MyoUI, Theme, mixins, css_utils, react_utils} = require 'myoui'

# adding default css code to the document
require 'myoui/default_fonts'
require 'myoui/default_animations'

path = require 'path'

markdown = react_utils.React.createFactory require('react-remarkable')
theme = new Theme

# adding WebkitAppRegion to default theme
theme.UIElement.WebkitAppRegion = 'no-drag'
theme.UIElementContainer = (disabled, highlighted)-> {
    (if highlighted
        boxShadow: theme.shadows.smallSoft
        background: 'white'
    else
        boxShadow: null
        background: 'transparent'
    )...
    mixins.transition('500ms', 'background shadow width')...
    (if disabled
        opacity: 0.5
        pointerEvents: 'none'
    else
        opacity: 1
        pointerEvents:'all'
    )...
    minHeight:'auto'
    borderRadius: theme.radius.r3
}

# global theme customization
theme.colors.green = 'rgb(194, 228, 157)'
theme.colors.light_green = 'rgb(200, 244, 187)'
theme.colors.light_orange = 'rgb(255, 181, 132)'
theme.colors.orange = 'rgb(255, 171, 112)'

theme.button.maxWidth = 200
theme.slider.value.width = 'auto'
theme.slider.value.textAlign = 'center'

myoui = new MyoUI theme

components =
    slider: (props={}, children)-> react_utils.React.createElement myoui.Slider, props, children
    button: (props={}, children)-> react_utils.React.createElement myoui.Button, props, children
    text_input: (props={}, children)-> react_utils.React.createElement myoui.TextInput, props, children
    switch: (props={}, children)-> react_utils.React.createElement myoui.Switch, props, children
    message: (message, custom_style, key=Math.floor(1000000*Math.random())) ->
        react_utils.React.createElement 'div',
            key:key
            className: 'myoui'
            style: {
                theme.UIElement...
                whiteSpace: 'pre-wrap'
                minHeight: 'auto'
                textAlign: 'center'
                fontSize: 20
                fontWeight: 100
                alignSelf: 'center'
                WebkitAppRegion: 'drag'
                custom_style...
            }
            message

sounds = {
    notification: new Audio path.join __dirname, '../../assets/sounds/notification.mp3'
}



module.exports = {react_utils, theme, mixins, components, sounds, markdown}
