-- Create a laucher widget and a main menu
local awesome_control = {
  { "manual", terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awesome.conffile },
  { "restart", awesome.restart },
  { "quit", awesome.quit }
}

local virtualbox = {
  { "XP For Web", "virtualbox --startvm test" },
  { "XP For Work", "virtualbox --startvm WinXPForWork" },
  { "XP For Money", "virtualbox --startvm WinXPForMoney" },
  { "Manager", "virtualbox" }
}

local control_center = {
  { "Control Center", "gnome-control-center" },
  { "Network", "gnome-control-center network" },
  { "Connections", "nm-connection-editor" },
  { "Monitor", "gnome-system-monitor" },
  { "Sound", "gnome-control-center sound" },
}

local favorite_applications = {
  { "Amarok", "amarok"},
  { "Chrome", "google-chrome"},
  { "Samba", "sudo system-config-samba" },
  { "Shutter", "shutter" },
  { "Stardict", "stardict"},
  { "Terminal", terminal },
}

local folders = {
  { "Home", "pcmanfm ." },
  { "Download", "pcmanfm Downloads" },
  { "Picture", "pcmanfm Pictures" },
}

local system_command = {
  { "Awesome Memu", awesome_control, beautiful.awesome_icon },
  { "Control Center", control_center },
  { "Logout", awesome.quit },
  -- Note: the two command bellow need to be run with sudo
  -- but I make it don't need to input password, 
  -- see /etc/sudoers.d/nopassword for more detail,
  -- and also see the README file in the same folder for some hint
  -- This method is read from:http://crunchbang.org/forums/viewtopic.php?pid=149596#p149596
  { "Restart", "sudo reboot" },
  { "Shutdown", "sudo poweroff" },
}

local main = awful.menu({ 
  items = { 
    { "Favorite", favorite_applications },
    { "Debian", debian.menu.Debian_menu.Debian },
    { "VirtualBox", virtualbox },
    { "Folders", folders},
    { "System", system_command },
  }
})

return main
