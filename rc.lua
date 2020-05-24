-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
naughty.config.defaults['icon_size'] = 70
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Variables personalizadas
local terminal = "alacritty"
local xrandr = require("lumartch/xrandr")
local terminal_editor = os.getenv("EDITOR") or "nano"
local gui_editor   = os.getenv("GUI_EDITOR") or "code"
local freedesktop = require("freedesktop")
local browser      = os.getenv("BROWSER") or "chromium"
-- Widgets
local spotify_widget = require("widgets/spotify/spotify")
local spotify_shell = require("widgets/spotify-shell/spotify-shell")
local volumearc_widget = require("widgets/volume/volumearc")
local stackoverflow_widget = require("widgets/stackoverflow/stackoverflow")
local calendar_widget = require("widgets/calendar/calendar")
local cpu_widget = require("widgets/cpu/cpu-widget")
local battery_widget = require("widgets/battery/battery")
local ram_widget = require("widgets/ram/ram-widget")
local run_shell = require("widgets/run-shell/run-shell-3")
local brightness_widget = require("widgets/brightness/brightness")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/lumartch/.config/awesome/lumartch/theme.lua")

-- Audio widget
local APW = require("apw/widget")
-- Network Manager applet
awful.util.spawn("nm-applet")
local net_widgets = require("widgets/net_widgets")
-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"
local alt = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
local custom_menu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "file manager", string.format("%s -e ranger", terminal) },
    { "edit config", string.format("%s -e %s %s", terminal, gui_editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}

awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or dpi(16),
    before = {
        { "Awesome", custom_menu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock("<span font='Terminus 5'> </span>%H:%M ")
local cw = calendar_widget({
    theme = 'dark',
    placement = 'top_right'
})
mytextclock:connect_signal("button::press", 
    function(_, _, _, button)
        if button == 1 then cw.toggle() end
    end)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
        awful.button({ }, 1, function(t) t:view_only() end),
        awful.button({ modkey }, 1, function(t)
                                    if client.focus then
                                        client.focus:move_to_tag(t)
                                    end
                                end),
        awful.button({ }, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
                                    if client.focus then
                                        client.focus:toggle_tag(t)
                                    end
                                end),
        awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
        awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
    )

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function (c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal(
                    "request::activate",
                    "tasklist",
                    {raise = true}
                )
            end
        end),
    awful.button({ }, 3, function()
            awful.menu.client_list({ theme = { width = 250 } })
        end),
    awful.button({ }, 4, function ()
            awful.client.focus.byidx(1)
        end),
    awful.button({ }, 5, function ()
            awful.client.focus.byidx(-1)
        end)
    )

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

--

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    local names = { "A", "R", "C", "H", "-", "L", "I", "N", "U", "X" }
    local l = awful.layout.suit
    local layouts = { l.tile, l.tile, l.tile, l.fair, l.max,
    l.floating, l.tile.left, l.floating, l.floating, l.floating }
    awful.tag(names, s, layouts)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create top the wibox
    s.mywibox = awful.wibar({ 
        osition = "top", 
        screen = s, layout   = {
            spacing = 20,
            spacing_widget = {
                {
                    forced_width = 5,
                    shape        = gears.shape.circle,
                    widget       = wibox.widget.separator
                },
                valign = 'center',
                halign = 'center',
                widget = wibox.container.place,
            },
            layout  = wibox.layout.flex.horizontal
        },
        widget_template = {
            {
                {
                    {
                        {
                            id     = 'icon_role',
                            widget = wibox.widget.imagebox,
                        },
                        margins = 2,
                        widget  = wibox.container.margin,
                    },
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left  = 10,
                right = 10,
                widget = wibox.container.margin
            },
            id     = 'background_role',
            widget = wibox.container.background,
        },
    })
    
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            spotify_widget({
                font = 'Ubuntu Mono 9',
                play_icon = '/usr/share/icons/Papirus-Light/24x24/categories/spotify.svg',
                pause_icon = '/usr/share/icons/Papirus-Dark/24x24/panel/spotify-indicator.svg'
             }),
            s.mypromptbox,
        },
        -- Middle widget
        awful.widget.tasklist{screen = s},
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            net_wireless = net_widgets.wireless({interface   = "wlp3s0", 
                onclick     = terminal .. " -e sudo wifi-menu" }),
            net_wired = net_widgets.indicator({
                timeout     = 5
            }),
            net_internet = net_widgets.internet({indent = 0, timeout = 5}),
            volumearc_widget(),
            brightness_widget({
                get_brightness_cmd = 'xbacklight -get',
                inc_brightness_cmd = 'xbacklight -inc 5',
                dec_brightness_cmd = 'xbacklight -dec 5'
              }),
            ram_widget(),
            cpu_widget({
                width = 70,
                step_width = 2,
                step_spacing = 0,
                color = '#434c5e'
            }),
            wibox.widget.systray(),
            mytextclock,
            battery_widget(),
            s.mylayoutbox,
        },
    }

    -- Create the bottom  wibox
    s.mywibox = awful.wibar({ position = "bottom", screen = s })
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.flex.horizontal ,
        s.mytasklist -- Middle widget
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    -- Audio
    awful.key({ }, "XF86AudioRaiseVolume",  APW.Up, 
            {description = "increase global volume", group = "sound"}),
    awful.key({ }, "XF86AudioLowerVolume",  APW.Down,
            {description = "decrease global volume", group = "sound"}),
    awful.key({ }, "XF86AudioMute",         APW.ToggleMute,
            {description = "mute global volume", group = "sound"}),

    -- Microphone
    --awful.key({"Shift"}, "XF86AudioRaiseVolume", pulse.volume_up_mic),
    --awful.key({"Shift"}, "XF86AudioLowerVolume", pulse.volume_down_mic),
    --awful.key({ }, "XF86MicMute",  pulse.toggle_muted_mic)

    -- Screen manipulation
    awful.key({ }, "XF86MonBrightnessUp", function () awful.spawn("light -A 5") end, 
            {description = "increase screen brightness", group = "screen"}),
    awful.key({ }, "XF86MonBrightnessDown", function () awful.spawn("light -U 5") end, 
            {description = "decrease screen brightness", group = "screen"}),

    -- Media manipulation
    awful.key({ modkey,        }, "d", function () spotify_shell.launch() end, 
            {description = "spotify shell", group = "music"}),
    awful.key({ }, "XF86AudioPlay", function () 
        awful.util.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause") 
        end,
        {description = "play / pause song", group = "music"}),
    awful.key({ }, "XF86AudioNext", function () 
        awful.util.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next") 
        end,
        {description = "next song", group = "music"}),
    awful.key({ }, "XF86AudioPrev", function () 
        awful.util.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous") 
        end,
        {description = "previous song", group = "music"}),
    awful.key({ }, "XF86AudioStop", function () 
        awful.util.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop") 
        end,
        {description = "stop song", group = "music"}),
    awful.key({ modkey }, "c", function () awful.spawn(string.format("%s -e cmus", terminal)) end,
        {description = "run cmus player", group = "music"}),
    awful.key({ modkey, "Shift" }, "s", function () awful.spawn("spotify") end,
        {description = "run spotify", group = "music"}),
    

    -- Awesome manipulation
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "w", function () awful.util.mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    -- Tag shortcutsthu
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- User programs
    awful.key({ modkey }, "q", function () awful.spawn(browser) end,
              {description = "run browser", group = "launcher"}),
    awful.key({ modkey }, "e", function () awful.spawn(gui_editor) end,
              {description = "run gui editor", group = "launcher"}),
    awful.key({ modkey, "Control" }, "c", function() xrandr.xrandr() end,
            {description = "run xrandr auto configurations", group = "launcher"}),
    awful.key({ modkey },            "r",     function () run_shell.launch() end,
            {description = "run prompt", group = "launcher"}),
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
            {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey }, "p", function() menubar.show() end,
            {description = "show the menubar", group = "launcher"}),
    awful.key({  }, "Print", function () awful.spawn("xfce4-screenshooter") end,
            {description = "run screenshooter tool", group = "launcher"}),
    awful.key({ modkey }, "g", function () awful.spawn("peek") end,
            {description = "run gif tool", group = "launcher"}),
    awful.key({ modkey }, "a", function () awful.spawn(string.format("%s -e ranger", terminal)) end,
           {description = "run terminal file manager", group = "launcher"}),
    awful.key({ modkey, "Control" }, "a", function () awful.spawn("thunar") end,
           {description = "run gui file manager", group = "launcher"}),
    -- 

    -- Client manipulation
    awful.key({ modkey, "Shift"   }, "Right", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "Left", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "Up", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
        awful.key({ modkey, "Control"}, "Right",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey, "Control"}, "Left",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    )
    -- Layout manipulation 
    --awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
    --          {description = "increase master width factor", group = "layout"}),
    --awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
    --          {description = "decrease master width factor", group = "layout"}),
    --awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
    --          {description = "increase the number of master clients", group = "layout"}),
    --awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
    --          {description = "decrease the number of master clients", group = "layout"}),
    --awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
    --          {description = "increase the number of columns", group = "layout"}),
    --awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
    --          {description = "decrease the number of columns", group = "layout"}),
    --awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
    --          {description = "select next", group = "layout"}),
    --awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
    --          {description = "select previous", group = "layout"})
    
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
--        awful.key({ modkey, "Control" }, "#" .. i + 9,
--                  function ()
--                      local screen = awful.screen.focused()
--                      local tag = screen.tags[i]
--                      if tag then
--                         awful.tag.viewtoggle(tag)
--                      end
--                  end,
--                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"})
--           Toggle tag on focused client.
--          awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
--                  function ()
--                      if client.focus then
--                          local tag = client.focus.screen.tags[i]
--                          if tag then
--                              client.focus:toggle_tag(tag)
--                          end
--                      end
--                  end,
--                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
--client.connect_signal("mouse::enter", function(c)
--    c:emit_signal("request::activate", "mouse_enter", {raise = false})
--end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}