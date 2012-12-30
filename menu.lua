-- Create a laucher widget and a main menu
awesome_control = {
  { "manual", terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awesome.conffile },
  { "restart", awesome.restart },
  { "quit", awesome.quit }
}

virtualbox = {
  { "XP For Web", "virtualbox --startvm test" },
  { "XP For Work", "virtualbox --startvm WinXPForWork" },
  { "XP For Money", "virtualbox --startvm WinXPForMoney" },
  { "Manager", "virtualbox" }
}

control_center = {
  { "Control Center", "gnome-control-center" },
  { "Network", "gnome-control-center network" },
  { "Sound", "gnome-control-center sound" },
}

favorite_applications = {
  { "Amarok", "amarok"},
  { "Chrome", "google-chrome"},
  { "Shutter", "shutter" },
  { "Stardict", "stardict"},
  { "Terminal", terminal },
}

folders = {
  { "Home", "nautilus ." },
  { "Download", "nautilus Downloads" },
  { "Picture", "nautilus Pictures" },
}

system_command = {
  { "Awesome Memu", awesome_control, beautiful.awesome_icon },
  { "Logout", awesome.quit },
  -- Note: the two command bellow need to be run with sudo
  -- but I make it don't need to input password, 
  -- see /etc/sudoers.d/reboot_logout for more detail,
  -- and also see the README file in the same folder for some hint
  { "Restart", "sudo reboot" },
  { "Shutdown", "sudo poweroff" },
}

main = awful.menu({ 
  items = { 
    { "Favorite", favorite_applications },
    { "Debian", debian.menu.Debian_menu.Debian },
    { "VirtualBox", virtualbox },
    { "Control Center", control_center },
    { "Folders", folders},
    { "System", system_command },
  }
})

return main
