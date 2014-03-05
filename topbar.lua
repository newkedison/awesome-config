module(..., package.seeall);

function build_wibox(launcher, promptboxes)
-- Create common splitter {{{
  tb_split = widget({ type = "textbox" })
  tb_split.text = " "
-- }}}

  -- Create a datetime widget {{{
  datetime = awful.widget.textclock({ align = "right"}, "%m-%d %H:%M:%S ", 1)
  function show_datetime()
    s_date = common.read_command_output('date')
    s_calendar = common.read_command_output(
      "LC_TIME=en_US.UTF-8 cal -3 | sed 's/\\(_\\x08 _\\x08\\)\\([0-9]\\)/"
      .. " <span color=\"#F00\">\\2<\\/span>/'")
    naughty.notify({
      present = naughty.config.presets.normal,
      title = "<span color='#888'>Current Datetime</span><br />",
      text = s_date .. "\n" .. s_calendar,
      timeout = 60,
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
  -- Closure function for calculating cpu use percent
  function calc_cpu_usage() --{{{
    local all = 0   -- upvalue to store all cpu time
    local idle = 0  -- upvalue to store idle cpu time
    return function()
      -- $5 is the idle cpu time
      -- see: http://www.linuxhowtos.org/System/procstat.htm
      -- for more infomation about the value of /proc/stat
      local cmd = "cat /proc/stat | head -n 1 "
        .. "| awk '{print $5; print $2+$3+$4+$5+$6+$7+$8+$9+$10+$11}'"
      local f = io.popen(cmd)
      local new_idle = f:read("*line")
      local new_all = f:read("*line")
      f:close()
      local percent = 0
      if all ~= 0 then
        -- calculate used percent of cpu
        percent = math.floor(
        -- (all            - idle)              / all             * 100
          ((new_all - all) - (new_idle - idle)) / (new_all - all) * 100)
      end
      all = new_all   -- store the old value
      idle = new_idle  -- store the old value
      return percent
    end
  end --}}}
  -- Use `free` to get the used percent of memory
  function get_memory_status() --{{{
    local cmd = "free | grep '\\-\\/+' | awk '{printf \"%.0f\",$3/($3+$4)*100}'"
    local f = io.popen(cmd)
    local value = f:read("*all")
    f:close()
    return value
  end --}}}
  -- Calculate all transfer bytes of all network adapter
  function get_network_sum() --{{{
    -- use `sed` to ignore the "lo" adapter
    -- use `awk` two times to get exactly the value
    -- every network adapter print two line,
    -- first line is the total bytes received
    -- second line is the total bytes sent
    local cmd = "ifconfig | sed -e '/lo/,/bytes/d'  | grep 'bytes' "
      .. "| awk -F':' '{print $2,$3}' | awk '{print $1; print $6}'"
    local f = io.popen(cmd)
    local values = {}
    -- Save all value in a table first
    for value in f:lines() do
      table.insert(values, tonumber(value))
    end
    local sum_down = 0
    local sum_up = 0
    -- sum all the value of all network adapter
    for i = 1, #values / 2 do
      sum_down = sum_down + values[i * 2 - 1]
      sum_up = sum_up + values[i * 2]
    end
    return sum_up, sum_down
  end --}}}
  -- Closure function for calculating use rate of all network adapter
  -- seconds must equal to timeout of the timer
  function calc_network_rate(seconds) --{{{
    local up = 0
    local down = 0
    return function()
      local new_up, new_down = get_network_sum()
      local rate_up = 0
      local rate_down = 0
      if up ~= 0 or down ~= 0 then
        -- use KB as unit
        rate_up = math.floor((new_up - up) / seconds / 1024)
        rate_down = math.floor((new_down - down) / seconds / 1024)
      end
      up = new_up
      down = new_down
      return rate_up, rate_down
    end
  end --}}}
  tb_ncm = widget({type = "textbox"})
  timer_ncm = timer({timeout = 1}) -- ncm is short for network-cpu-memory
  get_network_status = calc_network_rate(1) -- get the inner function
  get_cpu_status = calc_cpu_usage() -- get the inner function
  -- Format all the value
  function get_network_cpu_memory_status() -- {{{
    local up, down = get_network_status()
    if up >= 1000 then
      str_up = string.format("%3.1f", up / 1024)
    else
      str_up = string.format("%3.0f", up)
    end
    if down >= 1000 then
      str_down = string.format("%3.1f", down / 1024)
    else
      str_down = string.format("%3.0f", down)
    end
    local cpu = get_cpu_status()
    local mem = get_memory_status()
    return "<span color='#66CC00'>U:" .. str_up
    .. " </span><span color='#11CC22'>D:" .. str_down
    .. " </span><span color='#CC6600'>C:" .. string.format("%2.0f", cpu)
    .. " </span><span color='cyan'>M:" .. string.format("%2.0f", mem)
    .. "</span>"
  end --}}}
  timer_ncm:add_signal("timeout", 
    function ()
      tb_ncm.text = get_network_cpu_memory_status()
    end)
  timer_ncm:start()
  tb_ncm.text = get_network_cpu_memory_status()
  -- }}}

  -- Create battery widget {{{
  tb_battery = widget({type = "textbox"})
  timer_battery = timer({timeout=61})
  function battery_info() -- Read all buttery info {{{
    local battery_ID = "BAT0"
    -- This file contain all the value we need
    local path = "/sys/class/power_supply/" .. battery_ID .. "/uevent"
    local f = io.open(path)
    -- Save all value from the file to a table
    local power = {}
    for line in f:lines() do
      s, e = string.find(line, "=")
      if s then
        -- Ignore the first 13 char "POWER_SUPPLY_"
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
    -- Read the battery capacity and current value
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
    -- Calc percent
    local percent = math.min(math.floor(now / capacity * 100), 100)
    local rate = power['CURRENT_NOW']
    if not rate then
      return "<span color='red'>" .. status .. "(" .. percent .. "%)</span>"
    end
    -- Calc remainning time
    local timeleft = 0
    if status == "Discharging" then
      timeleft = now / rate
    elseif status == "Charging" then
      timeleft = (capacity - now) / rate
    else
      return "<span color='red'>" .. status .. "(" .. percent .. "%)</span>"
    end
    local hoursleft = math.floor(timeleft)
    local minutesleft = math.floor((timeleft - hoursleft) * 60)
    local time = string.format("%d:%02d", hoursleft, minutesleft)
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
      tb_split,
      tb_ncm,
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

