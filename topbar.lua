module(..., package.seeall);

function build_wibox(launcher, promptboxes)
-- Create common splitter {{{
  tb_split = widget({ type = "textbox" })
  tb_split.text = " "
-- }}}

  -- Create a datetime widget {{{
  datetime = awful.widget.textclock({ align = "right"}, " %m-%d %H:%M:%S ", 1)
  function show_datetime()
    naughty.notify({
      present = naughty.config.presets.normal,
      title = "<span color='#888'>Current Datetime</span><br />",
      text = common.read_command_output('date'),
      timeout = 20,
      ontop = true,
      bg = "#222222",
      fg = "green",
    })
  end
  -- Click the widget to show current datetime
  datetime:buttons(awful.util.table.join(
    awful.button({ }, 1, show_datetime),
    awful.button({ }, 3, show_datetime)
  )) -- }}}

  -- Create a systray {{{
  systray = widget({ type = "systray" })
  -- }}}

  -- Create volume control widget {{{
  tb_volume = widget({ type = "textbox" })
  tb_volume:buttons(awful.util.table.join(
    awful.button({ }, 1, function () volume.volume_toggle(tb_volume) end),
    awful.button({ }, 3, 
      function () 
        awful.util.spawn_with_shell('gnome-control-center sound') 
      end),
    awful.button({ "Control" }, 1, function () volume.volume_up(tb_volume) end),
    awful.button({ "Control" }, 3, function () volume.volume_down(tb_volume) end)
  ))
  tb_volume.text = volume.get_volume_status()
  timer_volume = timer({timeout=60})
  timer_volume:add_signal("timeout", 
    function()
      tb_volume.text = volume.get_volume_status()
    end)
  timer_volume:start()
  -- }}}

  -- Create widgets to show memory/CPU/network statistic {{{
  tb_memory = widget({ type = "textbox" })
  vicious.register(tb_memory, vicious.widgets.mem,
    "<span color='cyan'>M:$1</span>", 3)
  tb_cpu = widget({ type = "textbox" })
  vicious.register(tb_cpu, vicious.widgets.cpu,
    function (widget, args)
      return "<span color='#11CC22'>C:"
        .. string.format("%2.0f", args[1])
        .. "</span>"
    end , 5)
  tb_network = widget({ type = "textbox" })
  function show_network(widget, args)
    if args["{eth0 carrier}"] == 1 then
      carrier = "eth0"
    elseif args["{wlan0 carrier}"] == 1 then
      carrier = "wlan0"
    end
    return "<span color='#66CC00'>U:" 
      .. string.format("%3.0f", args["{" .. carrier .. " up_kb}"])
      .. "</span> <span color='#CC6600'>D:"
      .. string.format("%3.0f", args["{" .. carrier .. " down_kb}"])
      .. "</span>"
  end
  vicious.register(tb_network, vicious.widgets.net, show_network, 2)
  -- }}}

  -- Create battery widget {{{
  tb_battery = widget({type = "textbox"})
  timer_battery = timer({timeout=61})
  function battery_info() -- Read all buttery info {{{
    local battery_ID = "BAT0"
    local path = "/sys/class/power_supply/" .. battery_ID .. "/uevent"
    local f = io.open(path)
    local power = {}
    for line in f:lines() do
      s, e = string.find(line, "=")
      if s then
        power[string.sub(line, 14, s - 1)]
          = string.sub(line, e + 1, string.len(line))
      end
    end
    io.close(f)
    local status = power["STATUS"]
    if status == nil or status == "Unknown" then
      return "Unknown"
    end
    if status == "Full" or status == "Charged" then
      return "<span color='green'>Full</span>"
    end
    local capacity = power['CHARGE_FULL']
    local now = power['CHARGE_NOW']
    if not capacity then
      if power['ENERGY_NOW'] then
        capacity = power['ENERGY_FULL']
        now = power['ENERGY_NOW']
      else
        return "<span color='red'>" .. status .. "(?)</span>"
      end
    end
    local percent = math.min(math.floor(now / capacity * 100), 100)
    local rate = power['CURRENT_NOW']
    if not rate then
      return "<span color='red'>" .. status .. "(" .. percent .. "%)</span>"
    end
    local timeleft = 0
    if status == "Discharging" then
      timeleft = now / rate
    elseif status == "Charging" then
      timeleft = (full - now) / rate
    else
      return "<span color='red'>" .. status .. "(" .. percent .. "%)</span>"
    end
    local hoursleft = math.floor(timeleft)
    local minutesleft = math.floor((timeleft - hoursleft) * 60)
    local time = string.format("%02d:%02d", hoursleft, minutesleft)
    return "<span color='cyan'>" .. status
      .. "(" .. percent .. "% " .. time .. ")</span>"
  end --}}}
  timer_battery:add_signal("timeout", 
    function()
      tb_battery.text = battery_info()
    end)
  timer_battery:start()
  tb_battery.text = battery_info()
  -- }}}

  -- Create button behavior {{{
  taglist_buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, awful.client.toggletag),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
  )
  tasklist_buttons = awful.util.table.join(
    awful.button({ }, 1, function (c)
      if c == client.focus then
        c.minimized = true
      else
        if not c:isvisible() then
          awful.tag.viewonly(c:tags()[1])
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
      end
    end)
  ) -- }}}

  -- Create a wibox for each screen and add all widgets to it {{{
  wiboxes = {}
  -- These 3 widgets are different among every screen
  layoutboxes = {}
  taglists = {}
  tasklists = {}
  for s = 1, screen.count() do
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    layoutboxes[s] = awful.widget.layoutbox(s)
    layoutboxes[s]:buttons(awful.util.table.join(
      awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
      awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    taglists[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, taglist_buttons)

    -- Create a tasklist widget
    tasklists[s] = awful.widget.tasklist(function(c)
      return awful.widget.tasklist.label.currenttags(c, s)
    end, tasklist_buttons)

    -- Create the wibox
    wiboxes[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    wiboxes[s].widgets = {
      {
        launcher,
        taglists[s],
        promptboxes[s],
        layout = awful.widget.layout.horizontal.leftright
      },
      layoutboxes[s],
      tb_volume,
      datetime,
      tb_memory,
      tb_split,
      tb_cpu,
      tb_split,
      tb_network,
      tb_split,
      tb_battery,
      tb_split,
      s == 1 and systray or nil,
      tb_split,
      tasklists[s],
      layout = awful.widget.layout.horizontal.rightleft
    }
  end -- }}}

  return wiboxes
end

-- vim: fdm=marker

