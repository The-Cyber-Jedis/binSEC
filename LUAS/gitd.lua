os.loadAPI("git.lua")
local interval=300

while true do
  print("["..(os.date("%H:%M:%S")).."] Checking for updates...")
  local updates=git.check()
  if updates and #updates>0 then
    print("Syncing "..#updates.." files")
    for _,f in ipairs(updates)do
      git.pull(f)
    end
    git.broadcast(updates)
  end
  sleep(interval)
end
