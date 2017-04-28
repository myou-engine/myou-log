
{MyoUI, Theme, mixins, css_utils, react_utils} = require '../myoui/main.coffee'

# adding default css code to the document
require '../myoui/default_fonts'
require '../myoui/default_animations'

theme = new Theme
window.theme = theme
# adding webkitAppRegion to default theme
theme.UIElement.push {WebkitAppRegion: 'no-drag', cursor: 'pointer'}
theme.UIElementContainer = (disabled, useHighlight)-> [
    if useHighlight
        ':hover': [
            mixins.boxShadow theme.shadows.smallSoft
            background: 'white'
            color: 'black !important' # it's not working
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

window.ewin = ewin = require('electron').remote.getCurrentWindow();
window.isDebug = ewin.isDebug

app = document.getElementById 'app'

# Creating instances of myoui elements
label =

text_input = new myoui.TextInput
    label: (maxWidth='calc(100% - 30px)')->
        maxWidth: 'calc(100% - 10px)'
        margin: "0px #{theme.spacing}px"


button = new myoui.Button
    button:
        maxWidth: 200



# MyoUI includes some React utils.
{Component, React, ReactDOM} = react_utils
{div} = React.DOM
# "Component" returns a radium component which will allow us
# to use arrays and objects combined in the same style property.

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

main_component = Component
    getInitialState: ->
        dialog: 0
    render: ->
        working_on_value = "Last task by default"
        working_on_submit = ()=>
            console.log 'working_on submit'
            @setState dialog: @state.dialog + 1
        working_on =
            useHighlight: true
            label: "I'm working on"
            read: -> working_on_value
            onSubmit: working_on_submit
            onChange: (new_value)-> working_on_value = new_value
            onClick: (event)->
                if event.target.className != 'text_input'
                    working_on_submit()

        dialogs = [

            [
                message '''
                    You've been distracted for 5 min.
                    Did you start working?
                    '''

                div
                    id: "yes_no_container"
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                    ]
                    button.ui
                        label:'yes'
                        useHighlight:true
                        onClick: => @setState dialog: @state.dialog+1
                    button.ui
                        label:'no'
                        useHighlight:true
                        title:"I'll ask you again in 5 minutes"
            ]

            [
                message '''
                    What are you working on?
                    '''
                div
                    title:"I'll ask you again in 5 minutes"
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                        width: 'calc(100% - 30px)'
                    ]
                    text_input.ui working_on
                    button.ui
                        label:"I don't know"
                        useHighlight:true
                        fontSize: 20
                message '''
                    Time to auto-hide: 5s
                    '''
            ]
        ]

        dialog = dialogs[@state.dialog]
        if not dialog?
            ewin.close()
            return

        div
            id: 'main_container'
            style: [
                mixins.columnFlex
                justifyContent: 'center'
                alignItems: 'flex-start'
                top: '0'
                left: 4
                width: 'calc(100vw - 8px)'
                height: 'calc(100vh - 8px)'
                backgroundColor: theme.colors.light
                borderRadius: theme.radius.r4
                position: 'absolute'
                overflowX: 'hidden'
                WebkitAppRegion: 'drag'
                mixins.border3d 0.5
                mixins.boxShadow theme.shadows.hard
            ]
            dialog
            # text_input.ui working_on




# Rendering main_component with ReactDOM in our HTML element ```app```
render_all= ->
    ReactDOM.render main_component(), app

render_all()
window.addEventListener 'resize', render_all
