local cfg={repo="user/repo",branch="main",dir="/git"}
local api="https://api.github.com/repos/"
local raw="https://raw.githubusercontent.com/"

local function load()
  if fs.exists("/git.cfg")then
    local f=fs.open("/git.cfg","r")
    cfg=textutils.unserialise(f.readAll())
    f.close()
  end
end

local function save()
  local f=fs.open("/git.cfg","w")
  f.write(textutils.serialise(cfg))
  f.close()
end

local function get(url)
  local h=http.get(url)
  if h then
    local d=h.readAll()
    h.close()
    return d
  end
end

local function tree(path,prefix)
  path=path or""
  prefix=prefix or""
  local url=api..cfg.repo.."/contents/"..path.."?ref="..cfg.branch
  local data=get(url)
  if not data then return end
  local items=textutils.unserialiseJSON(data)
  for i,v in ipairs(items)do
    local last=i==#items
    local branch=last and"└── "or"├── "
    local next=last and"    "or"│   "
    if v.type=="dir"then
      print(prefix..branch..v.name.."/")
      tree(v.path,prefix..next)
    else
      print(prefix..branch..v.name)
    end
  end
end

local function pull(path,dest)
  dest=dest or cfg.dir.."/"..fs.getName(path)
  local url=raw..cfg.repo.."/"..cfg.branch.."/"..path
  local data=get(url)
  if data then
    fs.makeDir(fs.getDir(dest))
    local f=fs.open(dest,"w")
    f.write(data)
    f.close()
    print("Pulled: "..path.." -> "..dest)
    return true
  end
  print("Failed: "..path)
end

local function view(path)
  local url=raw..cfg.repo.."/"..cfg.branch.."/"..path
  local data=get(url)
  if data then
    print(data)
  else
    print("Not found: "..path)
  end
end

local function hash(file)
  if not fs.exists(file)then return nil end
  local f=fs.open(file,"r")
  local d=f.readAll()
  f.close()
  local h=0
  for i=1,#d do
    h=((h*31)+string.byte(d,i))%2147483647
  end
  return h
end

local function check(path)
  path=path or""
  local url=api..cfg.repo.."/contents/"..path.."?ref="..cfg.branch
  local data=get(url)
  if not data then return end
  local items=textutils.unserialiseJSON(data)
  local updates={}
  for _,v in ipairs(items)do
    if v.type=="file"then
      local local_path=cfg.dir.."/"..v.path
      local local_hash=hash(local_path)
      local remote_hash=tonumber(v.sha:sub(1,8),16)
      if not local_hash or local_hash~=remote_hash then
        table.insert(updates,v.path)
        print("[UPDATE] "..v.path)
      end
    elseif v.type=="dir"then
      local sub=check(v.path)
      if sub then
        for _,s in ipairs(sub)do
          table.insert(updates,s)
        end
      end
    end
  end
  return updates
end

local function sync()
  local updates=check()
  if updates and #updates>0 then
    print("Found "..#updates.." updates")
    for _,p in ipairs(updates)do
      pull(p)
    end
    return updates
  end
  print("Up to date")
end

local function broadcast(files)
  if not peripheral.find("modem")then return end
  rednet.open(peripheral.getName(peripheral.find("modem")))
  rednet.broadcast({type="git_update",files=files,repo=cfg.repo},"git")
  print("Broadcast update to network")
end

local function listen()
  if not peripheral.find("modem")then return end
  rednet.open(peripheral.getName(peripheral.find("modem")))
  print("Listening for updates...")
  while true do
    local id,msg=rednet.receive("git",5)
    if msg and msg.type=="git_update"then
      print("Update from #"..id)
      for _,f in ipairs(msg.files)do
        pull(f)
      end
    end
  end
end

local function clone(path)
  path=path or""
  local url=api..cfg.repo.."/contents/"..path.."?ref="..cfg.branch
  local data=get(url)
  if not data then return end
  local items=textutils.unserialiseJSON(data)
  for _,v in ipairs(items)do
    if v.type=="file"then
      pull(v.path)
    elseif v.type=="dir"then
      clone(v.path)
    end
  end
end

local args={...}
local cmd=args[1]

load()

if cmd=="config"then
  cfg.repo=args[2]or cfg.repo
  cfg.branch=args[3]or cfg.branch
  cfg.dir=args[4]or cfg.dir
  save()
  print("Config: "..cfg.repo.." @ "..cfg.branch.." -> "..cfg.dir)
elseif cmd=="tree"then
  tree(args[2])
elseif cmd=="pull"then
  pull(args[2],args[3])
elseif cmd=="view"then
  view(args[2])
elseif cmd=="check"then
  check(args[2])
elseif cmd=="sync"then
  local updates=sync()
  if updates then broadcast(updates)end
elseif cmd=="clone"then
  clone(args[2])
elseif cmd=="listen"then
  listen()
else
  print("Git for CC:Tweaked")
  print("Usage:")
  print("  git config <repo> [branch] [dir]")
  print("  git tree [path]")
  print("  git pull <path> [dest]")
  print("  git view <path>")
  print("  git check [path]")
  print("  git sync")
  print("  git clone [path]")
  print("  git listen")
  print("")
  print("Current: "..cfg.repo.." @ "..cfg.branch)
end
