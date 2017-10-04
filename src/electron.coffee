fs = require 'fs'
path = require 'path'

platform = process.platform
is_linux = platform == 'linux'
app_proccess = process.execPath.split(path.sep).pop()

console.log app_proccess
isDebug = /^\.?electron/.test app_proccess
isElectron = /^\.?electron|myou-log/.test  app_proccess

if isElectron
    {app, BrowserWindow, globalShortcut} = require 'electron'

    # Disallow multiple instances.
    shouldQuit = app.makeSingleInstance (commandLine, workingDirectory)->
      console.warn "Multiple instances not allowed."

    if shouldQuit
      app.quit()

    {settings, save_settings, load_settings,
    apply_default_settings, add_post_save_callback} = require './settings'
    load_settings()

    if not app? # old electron api
        app = require('app') # Module to control application life.
        BrowserWindow = require('browser-window')  # Module to create native browser window.
    path = require 'path'
    url = require 'url'

    created_windows = []

    # Keep a global reference of the window object, if you don't, the window will
    # be closed automatically when the JavaScript object is garbage collected.

    create_settings_window = ->
        options =
            title: 'MyouLog - Settings'
            width: 710
            height: 680
            minWidth: 600
            minHeight: 200
            icon: path.join __dirname, '../assets/icons/png/64x64.png'

        win = new BrowserWindow options
        win.recreate = create_settings_window
        win.loadURL url.format
            pathname: path.join __dirname, 'UI/html/settings.html'
            protocol: 'file:'
            slashes: true
        win.setMenuBarVisibility false
        win.settings = settings
        win.load_settings = load_settings
        win.save_settings = save_settings
        win.apply_default_settings = apply_default_settings
        win.isDebug = isDebug
        return win

    create_report_window = ->
        options =
            title: 'MyouLog - Report'
            width: 600
            height: 600
            minWidth: 600
            minHeight: 200
            icon: path.join __dirname, '../assets/icons/png/64x64.png'

        win = new BrowserWindow options
        win.recreate = create_report_window
        win.loadURL url.format
            pathname: path.join __dirname, 'UI/html/report.html'
            protocol: 'file:'
            slashes: true
        win.setMenuBarVisibility false
        win.settings = settings
        win.isDebug = isDebug
        return win

    create_main_window = ->
        if isDebug
            save_settings(settings, true)

        options =
            width: 350
            height: 220
            frame: if is_linux then true else false
            transparent: if is_linux then false else true
            show: true
            icon: path.join __dirname, '../assets/icons/png/64x64.png'
            title: 'MyouLog'
            skipTaskbar: true
            resizable: false

        # Create the browser window.
        win = new BrowserWindow options

        win.setMenuBarVisibility false
        # Open the DevTools.
        if settings.auto_open_dev_tools
            win.webContents.openDevTools({mode:'detach'})

        # Emitted when the window is closed.
        win.on 'closed', =>
            # Dereference the window object, usually you would store windows
            # in an array if your app supports multi windows, this is the time
            # when you should delete the corresponding element.
            win.tray?.destroy()
            win = null

        win.isDebug = isDebug
        win.recreate = create_main_window
        win.create_report_window = create_report_window
        win.create_settings_window = create_settings_window
        win.add_post_save_callback = add_post_save_callback
        win.load_settings = load_settings
        win.settings = settings

        # Load the html of the app.
        win.loadURL url.format
            pathname: path.join __dirname, 'UI/html/main.html'
            protocol: 'file:'
            slashes: true
        return win

    # Quit when all windows are closed.
    app.on 'window-all-closed', =>
        # On macOS it is common for applications and their menu bar
        # to stay active until the user quits explicitly with Cmd + Q
        if process.platform != 'darwin'
            app.quit()

    app.on 'will-quit', ->
        globalShortcut.unregisterAll()

    app.on 'activate', ->
        # On macOS it's common to re-create a window in the app when the
        # dock icon is clicked and there are no other windows open.
        if not win?
            create_main_window()

    # In this file you can include the rest of your app's specific main process
    # code. You can also put them in separate files and require them here.

    # This method will be called when Electron has finished
    # initialization and is ready to create browser windows.
    # Some APIs can only be used after this event occurs.
    app.on 'ready', ->
        create_main_window()
else
    electron = require 'electron-prebuilt'
    proc = require 'child_process'
    # spawn electron
    child = proc.spawnSync electron, ["node_modules/coffeescript/bin/coffee", __filename], {stdio: 'inherit', shell: true}
