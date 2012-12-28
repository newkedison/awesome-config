module(..., package.seeall);

require("common")

function get_volume_status(color)
  local status = common.read_command_output("amixer sget Master")
  local volume = string.match(status, "(%d?%d?%d)%%")
  status = string.match(status, "%[(o[^%]]*)%]")
  if string.find(status, "on", 1, true) then
    if color ~= nil and color ~= "" then
      volume = "<span color='" .. color .. "'>[" .. volume .. "%]</span>"
    else
      volume = "<span color='#00AA00'>[" .. volume .. "%]</span>"
    end
  else
    if color ~= nil and color ~= "" then
      volume = "<span color='" .. color .. "'>[Mute]</span>"
    else
      volume = "<span color='#CC00CC'>[Mute]</span>"
    end
  end
  return volume
end

function volume_change(value)
  common.run_command("amixer sset Master " .. value)
end

function volume_up(widget)
  volume_change("5%+")
  if widget ~= nil then
    widget.text = get_volume_status()
  end
end

function volume_down(widget)
  volume_change("5%-")
  if widget ~= nil then
    widget.text = get_volume_status()
  end
end

function volume_toggle(widget)
  local mute_status = common.read_command_output("amixer get Master | egrep 'Playback.*?\\[o' | egrep -o '\\[o.+\\]'")
  if string.find(mute_status, "on") then
    common.run_command("amixer set Master mute")
  else
    common.run_command("amixer set Master unmute && amixer set Headphone unmute && amixer set Speaker unmute")
  end
  if widget ~= nil then
    widget.text = get_volume_status()
  end
end
