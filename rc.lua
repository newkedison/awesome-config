-- Standard awesome library
-- Library source: /usr/share/awesome/lib/
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")
-- Load volume control module
require("volume")
-- Load some common function written by me
require("common")

require("topbar")

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
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
--    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
--    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
--    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- path where the config files located
config_path = awful.util.getdir("config") .. "/"
-- }}}

-- util function {{{
function show_debug_info(str, timeout)
  naughty.notify({
    present = naughty.config.presets.normal,
    title = "<span color='#888'>Debug Info</span>",
    text = str,
    timeout = timeout or 20,
    ontop = true,
    bg = "#222222",
    fg = "green",
  })
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
  names  = { '1 Term', '2 Web', '3 VIM', '4 VBox', '5 Misc' },
  layouts = { layouts[2], layouts[3], layouts[3], layouts[3], layouts[1] }
}
for s = 1, screen.count() do
  -- Each screen has its own tag table.
  tags[s] = awful.tag(tags.names, s, tags.layouts)
end
-- }}}

-- {{{ Menu

-- load menu from another file
mymainmenu = dofile(config_path .. "menu.lua")
mylauncher = awful.widget.launcher(
  { image = image(beautiful.awesome_icon),
  menu = mymainmenu })
-- }}}

-- {{{ Wibox
promptboxes = {}
for s = 1, screen.count() do
  promptboxes[s] = awful.widget.prompt(
    { layout = awful.widget.layout.horizontal.leftright })
end
wb_top = topbar.build_wibox(mylauncher, promptboxes)
--Test for multiple wiboxes
--wb_left = awful.wibox({ position = "left", screen = 1 })
--tb_test = widget({type="textbox"})
--tb_test.text = "test"
--wb_left.widgets = {
--  tb_test,
--  layout = awful.widget.layout.horizontal.rightleft
--}
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 1, function () mymainmenu:hide() end),
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    -- use "Ctrl+Alt+l" to lock screen and close lcd
    awful.key({ "Control", "Mod1"  }, "l", function () awful.util.spawn('myscript/closelcd') end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () promptboxes[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  promptboxes[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
        ---  modify from:http://awesome.naquadah.org/wiki/Move_Window_to_Workspace_Left/Right 
    awful.key({ modkey, "Shift"   }, ",",
      function (c)
        local curidx = awful.tag.getidx(c:tags()[1])
        local new_tag = 1
        if curidx == 1 then
          new_tag = 5
        else
          new_tag = curidx - 1
        end
        c:tags({screen[mouse.screen]:tags()[new_tag]})
        if tags[mouse.screen][new_tag] then
          awful.tag.viewonly(tags[mouse.screen][new_tag])
        end
      end),
    awful.key({ modkey, "Shift"   }, ".",
      function (c)
        local curidx = awful.tag.getidx(c:tags()[1])
        local new_tag = 1
        if curidx == 5 then
          new_tag = 1
        else
          new_tag = curidx + 1
        end
        c:tags({screen[mouse.screen]:tags()[new_tag]})
        if tags[mouse.screen][new_tag] then
          awful.tag.viewonly(tags[mouse.screen][new_tag])
        end
      end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
  globalkeys = awful.util.table.join(globalkeys,
  awful.key({ modkey }, "#" .. i + 9,
    function ()
      local screen = mouse.screen
      if tags[screen][i] then
        awful.tag.viewonly(tags[screen][i])
      end
    end),
  awful.key({ modkey, "Control" }, "#" .. i + 9,
    function ()
      local screen = mouse.screen
      if tags[screen][i] then
        awful.tag.viewtoggle(tags[screen][i])
      end
    end),
  awful.key({ modkey, "Shift" }, "#" .. i + 9,
    function ()
      if client.focus and tags[client.focus.screen][i] then
        awful.client.movetotag(tags[client.focus.screen][i])
      end
    end),
  awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
    function ()
      if client.focus and tags[client.focus.screen][i] then
        awful.client.toggletag(tags[client.focus.screen][i])
      end
    end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, 
      function (c) 
        client.focus = c
        c:raise()
        mymainmenu:hide()
      end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Google-chrome" },
      properties = { tag = tags[1][2] } },
--    { rule = { class = "Gnome-terminal" },
--      properties = { tag = tags[1][1] } },
    { rule = { class = "VirtualBox" },
      properties = { tag = tags[1][4] } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
--    c:add_signal("mouse::enter", function(c)
--        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
--            and awful.client.focus.filter(c) then
--            client.focus = c
--        end
--    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ autostart
-- Autostart
-- From: http://awesome.naquadah.org/wiki/Autostart#Directory_way
function autostart(dir)
  if not dir then
    do return nil end
  end
  local fd = io.popen("ls -1 -F " .. dir)
  if not fd then
    do return nil end
  end
  for file in fd:lines() do
    local c= string.sub(file,-1)   -- last char
    if c=='*' then  -- executables
      executable = dir .. "/" .. string.sub( file, 1, -2 ) .. ""
--      show_debug_info("Executing: " .. executable, 10)
      awful.util.spawn_with_shell(executable) -- launch in bg
--    elseif c=='@' then  -- symbolic links
--      print("Awesome Autostart: Not handling symbolic links: " .. file)
--    else
--      print ("Awesome Autostart: Skipping file " .. file .. " not executable.")
    end
  end
  io.close(fd)
end
autostart_dir = os.getenv("HOME") .. "/.config/awesome/autostart"
autostart(autostart_dir)
-- }}}

-- vim: fdm=marker

