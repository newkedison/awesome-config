module(..., package.seeall);
function read_command_output(cmd)
  local fd = io.popen(cmd)
  local out = fd:read("*all")
  fd:close()
  return out
end

function run_command(cmd)
  os.execute(cmd)
end
