-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")
-- Set date in local language
os.setlocale(os.getenv("LANG"))

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
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
--local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- Widget from github.com/streetturtle/awesome-wm-widgets
local logout_menu_widget = require("awesome-wm-widgets.logout-menu-widget.logout-menu")
local net_speed_widget = require("awesome-wm-widgets.net-speed-widget.net-speed")
local ram_widget = require("awesome-wm-widgets.ram-widget.ram-widget")
local cpu_widget = require("awesome-wm-widgets.cpu-widget.cpu-widget")
--To get instant name on rhythmbox
local watch = require("awful.widget.watch")
--local mpris_widget = require("awesome-wm-widgets.mpris-widget")
-- New volume
local volume_pip = require('awesome-wm-widgets.pactl-widget.volume')
-- Battery widget
local batteryarc_widget = require("awesome-wm-widgets.batteryarc-widget.batteryarc")
local screenshot = require("awesome-wm-widgets.screenshot.screenshot")
-- Wifi widget
local net_widgets = require("awesome-wm-widgets.net_widgets")

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
--beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.wallpaper = "/home/pierrot/Images/Spidey.png"

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max,
--    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.termfair,
--    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
    mymainmenu = freedesktop.menu.build({
        before = { menu_awesome },
        after =  { menu_terminal }
    })
else
    mymainmenu = awful.menu({
        items = {
                  menu_awesome,
--                  { "Debian", debian.menu.Debian_menu.Debian },
                  menu_terminal,
                }
    })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
--mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock("%a %d %b, %H:%M:%S",1)

--Separator
sprtr = wibox.widget.textbox()
sprtr:set_text(" | ")

--Redshift
myredshift_temp   = wibox.widget.textbox("6.5kK")
myredshift_bright = wibox.widget.textbox("100%")
myredshift_logo   = {
    image = "/home/pierrot/.config/awesome/Others/temperature.svg",
    widget = wibox.widget.imagebox
}

--Set default value
rs_temperature = 6500
-- Get brightness
local brightness_path = "/sys/class/backlight/amdgpu_bl1/brightness"
awful.spawn.easy_async(
    {"sh", "-c", "cat " .. brightness_path},
    function(stdout, stderr, reason, exit_code)
        if exit_code == 0 and stdout then
            local brightness = tonumber(stdout:match("%d+"))
            brightness = math.floor((brightness*100+127)/255)
            rs_brightness = brightness
        else
            -- Handle errors
            awful.spawn.easy_async(
                {"notify-send", "Error", "Could not read brightness: " .. (stderr or reason or "Unknown error")},
                function() end
            )
            rs_brightness = 100
        end
        myredshift_bright.text = " " .. rs_brightness .. "%"
    end
)

-- Function to really set brightness with backlight and redshift
function f_set_brightness()
    --awful.spawn.with_shell("echo " .. math.floor(1.0+(rs_brightness/10)) .. " > /dev/shm/test")
    os.setlocale('C')
    local brightness_backlight = math.floor(rs_brightness*255/100)
    if rs_brightness < 0 then
        local brightness = 1.0+(rs_brightness/10)
        awful.spawn.with_shell("echo 0 > /sys/class/backlight/amdgpu_bl1/brightness") 
        awful.spawn("redshift -oP -O " .. rs_temperature .. " -b " .. brightness)
    else
        awful.spawn.with_shell("echo " .. brightness_backlight .. " > /sys/class/backlight/amdgpu_bl1/brightness") 
        awful.spawn("redshift -oP -O " .. rs_temperature .. " -b 1.0")
    end
    os.setlocale(os.getenv("LANG"))
end
-- Function to set temperature
function f_redshift_temperature(button)
		if button == 1 then
				rs_temperature = 6500
		elseif button == 3 then
				rs_temperature = 3500
		elseif button == 4 and rs_temperature < 6500 then 
				rs_temperature = rs_temperature + 500
		elseif button == 5 and rs_temperature > 2000 then
				rs_temperature = rs_temperature - 500
		end
		myredshift_temp.text = rs_temperature/1000 .. "kK"
        f_set_brightness(rs_brightness)
end
-- Function to set brightness
function f_redshift_brightness(button)
		if button == 1 then
				rs_brightness = 100
		elseif button == 3 then
				rs_brightness = 60
		elseif button == 4 and rs_brightness < 100 and rs_brightness >= 20 then 
				rs_brightness = rs_brightness + 5
		elseif button == 4 and rs_brightness < 100 then 
				rs_brightness = rs_brightness + 1
		elseif button == 5 and rs_brightness > -10 and rs_brightness <= 20 then 
				rs_brightness = rs_brightness - 1
		elseif button == 5 and rs_brightness > -10 then 
				rs_brightness = rs_brightness - 5
		end
		myredshift_bright.text = " " .. rs_brightness .. "%"
        f_set_brightness(rs_brightness)
end
myredshift_temp:connect_signal("button::press", function(_, _, _, button) f_redshift_temperature(button) end)
myredshift_bright:connect_signal("button::press", function(_, _, _, button) f_redshift_brightness(button) end)
--end of redshift

--Rhythmbox
rhythmbox_widget = wibox.widget {
        {
            id = 'icon',
--            forced_width = 10,
--            image = ICONS_DIR .. 'down.svg',
            widget = wibox.widget.imagebox
        },
        {
            id = 'title',
            align = 'right',
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal
    }
watch(
    "rhythmbox-client --no-start --print-playing", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local handle = io.popen("playerctl status -p rhythmbox 2>/dev/null")
        if handle then
            local result = handle:read("*a") -- Lit toute la sortie
            handle:close()
            status = result:match("^%s*(.-)%s*$") -- Nettoie la sortie de playerctl
            if status == "Playing" then
                rhythmbox_widget:get_children_by_id('icon')[1]:set_image("/usr/share/icons/AdwaitaLegacy/48x48/legacy/media-playback-start.png")
                rhythmbox_widget:get_children_by_id('title')[1]:set_text(stdout)
            elseif status == "Paused" then
                rhythmbox_widget:get_children_by_id('icon')[1]:set_image(nil)
                rhythmbox_widget:get_children_by_id('title')[1]:set_text(" "..stdout)
            end
        else
            rhythmbox_widget:get_children_by_id('title')[1]:set_text(" "..stdout)
        end
    end)
rhythmbox_widget:connect_signal("button::press",
    function(_, _, _, button)
        if button == 3 then
            awful.spawn("rhythmbox-client --play")
            rhythmbox_widget:get_children_by_id('icon')[1]:set_image("/usr/share/icons/AdwaitaLegacy/48x48/legacy/media-playback-start.png")
        elseif button == 1 then
            awful.spawn("rhythmbox-client --pause")
            rhythmbox_widget:get_children_by_id('icon')[1]:set_image(nil)
        elseif button == 9 then
            awful.spawn("rhythmbox-client --next")
            rhythmbox_widget:get_children_by_id('icon')[1]:set_image("/usr/share/icons/AdwaitaLegacy/48x48/legacy/media-playback-start.png")
        elseif button == 8 then
            awful.spawn("rhythmbox-client --previous")
            rhythmbox_widget:get_children_by_id('icon')[1]:set_image("/usr/share/icons/AdwaitaLegacy/48x48/legacy/media-playback-start.png")
        end
    end)
--End of rhythmbox

--Start temperature
temperature_widget =  wibox.widget {
        {   
            image = "/home/pierrot/.config/awesome/Others/cpu.svg",
            widget = wibox.widget.imagebox
        },
        {
            id = 'temp_cpu',
            widget = wibox.widget.textbox
        },
        {   
            image = "/home/pierrot/.config/awesome/Others/gpu.svg",
            widget = wibox.widget.imagebox
        },
        {
            id = 'temp_gpu',
            widget = wibox.widget.textbox
        },
        layout = wibox.layout.fixed.horizontal
    }
watch(
    --Desktop version :
    --'bash -c "sensors | grep \'Sensor 2:\' | awk \'{print $3}\'"', 5,
    --Laptop version :
    --'bash -c "sensors | grep \'Package id\' | awk \'{print $4}\'"', 5,
    'bash -c "sensors | grep \'Tctl:\' | awk \'{print $2}\'"', 5,
    function(widget, stdout, stderr, exitreason, exitcode)
        temperature_widget:get_children_by_id('temp_cpu')[1]:set_text(stdout)
    end)
watch(
    --Desktop version :
    --'bash -c "sensors | grep \'Tctl:\' | awk \'{print $2}\'"', 5,
    --Laptop version :
    'bash -c "sensors | grep \'edge:\' | awk \'{print $2}\'"', 5,
    function(widget, stdout, stderr, exitreason, exitcode)
        temperature_widget:get_children_by_id('temp_gpu')[1]:set_text(stdout)
    end)
--End of temperature
-- Open Tuxedo CC when click on temperature
temperature_widget:connect_signal("button::press", 
    function(_, _, _, button) 
        if button == 1 then
            awful.spawn("tuxedo-control-center")
        elseif button == 3 then
            awful.spawn("gnome-system-monitor")
        end
    end
)
-- End of TCC

-- Wifi connection
net_wireless = net_widgets.wireless({
    interface   = "wlan0",
    timeout     = 5,
    popup_signal = true,
    onclick      = "env XDG_CURRENT_DESKTOP=GNOME gnome-control-center wifi"
})
-- Ethernet connection
net_wired = net_widgets.indicator({
    interfaces  = {"enp1s0"},
    timeout     = 5,
    onclick      = "env XDG_CURRENT_DESKTOP=GNOME gnome-control-center network",
    hidedisconnected = true
})

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
                    awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end)
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
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(-1)
                                          end),
                  --Close client when click prev in tasklist
                     awful.button({ }, 8, function (c) 
                                            c:kill()
                                        end),
                     awful.button({ }, 2, function (c) c:kill() end)
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
        --gears.wallpaper.centered(wallpaper, s)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({"²", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "°", "+" }, s, awful.layout.layouts[2])

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

    -- Set widget for each screen
    if s == screen.primary then
        list_prim_wdg = {
            layout = awful.widget.only_on_screen,
            screen = screen.primary, -- Only display on primary screen
            {
                layout = wibox.layout.fixed.horizontal,
                rhythmbox_widget,
                sprtr,
                cpu_widget({enable_kill_button=true}),
                ram_widget(),
                temperature_widget,
                sprtr,
                net_speed_widget({timeout=2, width=50}),
                sprtr,
                myredshift_temp,
                myredshift_logo,
                myredshift_bright,
                sprtr,
                volume_pip({widget_type = 'arc'}),
                sprtr,
                net_wireless,
                net_wired,
                sprtr,
				batteryarc_widget({show_current_level=true, 
					arc_thickness=1,
                    size=24,
                    font="Play 7",
                    warning_msg_position="top_right",
					show_notification_mode="on_click"}),
                sprtr,
                mytextclock,
                sprtr
            }
        }
    end

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mylayoutbox,
            --mylauncher, -- icon of menu
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
--            mykeyboardlayout,
            list_prim_wdg,
            logout_menu_widget(),
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Down",
        function()
            if awful.screen.focused().selected_tag.index >= 10 then
                awful.screen.focused().tags[13]:view_only()
            else
                awful.tag.viewidx(3)
            end
        end,
              {description = "view 3 next", group = "tag"}),
    awful.key({ modkey,           }, "Up",
        function()
            if awful.screen.focused().selected_tag.index <= 3 then
                awful.screen.focused().tags[1]:view_only()
            else
                awful.tag.viewidx(-3)
            end
        end,
              {description = "view 3 next", group = "tag"}),
    -- Move client to next screen
    awful.key({ modkey, "Shift"   }, "Left",
        function()
            if awful.screen.focused().selected_tag.index>=2 then
                client.focus:move_to_tag(client.focus.screen.tags[awful.screen.focused().selected_tag.index-1])
                awful.tag.viewidx(-1)
            end
        end,
              {description = "Move previous", group = "tag"}),
    awful.key({ modkey, "Shift"   }, "Right",
        function()
            if awful.screen.focused().selected_tag.index<=12 then
                client.focus:move_to_tag(client.focus.screen.tags[awful.screen.focused().selected_tag.index+1])
                awful.tag.viewidx(1)
            end
        end,
              {description = "Move previous", group = "tag"}),

--Mod1 is Alt_L
    awful.key({ modkey, "Mod1"     }, "j",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey, "Mod1"     }, "k",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),

    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Control"   }, "q", function() awful.spawn.with_shell("i3lock -i /home/pierrot/Images/Spidey_screen.png && systemctl hibernate") end,
              {description = "Suspend", group = "awesome"}),
    -- Custom program
    awful.key({ modkey,           }, "e", function () awful.spawn("nemo") end,
              {description = "open nemo", group = "launcher"}),
    awful.key({ modkey,           }, "z", function () awful.spawn("alacritty -e ranger") end,
              {description = "open ranger", group = "launcher"}),
    awful.key({ modkey,           }, "$", function () awful.spawn("speedcrunch") end,
              {description = "Launch speedcrunch", group = "launcher"}),
    awful.key({ modkey,           }, "!", function () awful.spawn.with_shell("feh ~/Images/header_pinout.jpg") end,
              {description = "Launch RPI GPIO", group = "launcher"}),
    awful.key({ "Ctrl" }, "Print", function() scrot_full() end,
          {description = "Take a screenshot of entire screen", group = "screenshot"}),
    awful.key({        }, "Print", function() scrot_full("/dev/shm/screenshot") end,
          {description = "Take a snapshot of entire screen", group = "screenshot"}),
    awful.key({ "Shift", "Ctrl" }, "Print", scrot_selection,
          {description = "Take a screenshot of selection", group = "screenshot"}),
    awful.key({ "Shift",        }, "Print", function() scrot_selection("/dev/shm/screenshot") end,
          {description = "Copy a snapshot of selection", group = "screenshot"}),
    awful.key({ modkey, "Ctrl" }, "Print", scrot_window,
          {description = "Take a screenshot of window", group = "screenshot"}),
    awful.key({ modkey, }, "Print", function() scrot_window("/dev/shm/screenshot") end,
          {description = "Take a snapshot of window", group = "screenshot"}),
    awful.key({ "Mod1" }, "Print", scrot_delay,
          {description = "Take a screenshot of delay", group = "screenshot"}),
    awful.key({ "Ctrl", "Mod1" }, "Delete", function () awful.spawn("NeoHtop") end,
          {description = "Launch NeoHtop", group = "launcher"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),

    -- Sound shortcut
    awful.key({}, "XF86AudioLowerVolume", function () volume_pip:dec(5) end),
    awful.key({}, "XF86AudioRaiseVolume", function () volume_pip:inc(5) end),
    awful.key({}, "XF86AudioMute", function () volume_pip:toggle() end),
    -- Media Keys
    awful.key({}, "XF86AudioPlay", function()
        awful.util.spawn("playerctl play-pause", false) end),
    awful.key({}, "XF86AudioNext", function()
        awful.util.spawn("playerctl next", false) end),
    awful.key({}, "XF86AudioPrev", function()
        awful.util.spawn("playerctl previous", false) end),
    awful.key({}, "XF86MonBrightnessDown", function() f_redshift_brightness(5) end),
    awful.key({}, "XF86MonBrightnessUp", function() f_redshift_brightness(4) end),
    --End of shortcut

    -- Power shortcut
    awful.key({}, "XF86PowerOff", function() 
        awful.spawn.with_shell("zenity --question --title='Extinction !' --text='Confirmation?' --timeout 60; [ $? == 1 ] || shutdown -h now")
    end)
    -- End of power shortcut


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
    awful.key({ modkey,           }, "y",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"}),
    awful.key({ modkey }, "t", function (c) awful.titlebar.toggle(c) end,
        {description = 'toggle title bar', group = 'client'})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
tag_list_print = {'²', '1','2','3','4','5','6','7','8','9','0','°','+'}
tag_list_key   = {'²', '&','é','"',"'",'(','-','è','_','ç','à',')','='}
for i = 1, 13 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, tag_list_key[i],
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..tag_list_print[i], group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, tag_list_key[i],
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. tag_list_print[i], group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, tag_list_key[i],
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..tag_list_print[i], group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, tag_list_key[i],
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. tag_list_print[i], group = "tag"})
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
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen+awful.placement.centered
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
          "speedcrunch",
          "nemo",
          "loupe",
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
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "9" on screen 1.
    { rule = { class = "Firefox" },
       properties = { screen = 1, tag = "8" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then awful.client.setslave(c) end
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
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Set screen
--awful.spawn.with_shell("xrandr --output DP-0 --mode 2560x1440 --rate 240 --primary")
awful.spawn.with_shell("xrandr --output DP-2 --mode 2560x1440 --rate 240 --above eDP-1")
--awful.spawn.with_shell("xrandr --output HDMI-0 --mode 1920x1080 --rate 60 --left-of DP-0")
--awful.spawn.with_shell("setxkbmap -option caps:escape")

-- Work on calendar from :
-- cd ~/.config/awesome/ && git clone https://github.com/streetturtle/awesome-wm-widgets.git
local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")
local cw = calendar_widget({
    theme = 'nord',
    placement = 'top_right',
    start_sunday = false,
    radius = 8,
-- with customized next/previous (see table above)
    previous_month_button = 1,
    previous_month_button = 4,
    next_month_button = 3,
    next_month_button = 5,
})
mytextclock:connect_signal("button::press",
    function(_, _, _, button)
        if button == 1 then cw.toggle() end
    end)
-- End of calendar

--Auto launch app
awful.spawn.with_shell("~/.config/awesome/autorun.sh")
