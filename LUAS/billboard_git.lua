os.loadAPI("git.lua")
local m=peripheral.find("monitor")
m.setTextScale(0.5)
term.redirect(m)
local w,h=term.getSize()

local function update()
  git.config("username/repo","main","/billboard")
  local u=git.check("IMGS")
  if u and #u>0 then
    for _,f in ipairs(u)do git.pull(f)end
    return true
  end
end

update()

while true do
  for _,f in pairs(fs.list("/billboard/IMGS"))do
    if f:match("%.nfp$")then
      term.clear()
      local img=paintutils.loadImage("/billboard/IMGS/"..f)
      if img then
        local iw,ih=#img[1],#img
        local x=math.max(1,math.floor((w-iw)/2)+1)
        local y=math.max(1,math.floor((h-ih)/2)+1)
        if iw<=w and ih<=h then
          paintutils.drawImage(img,x,y)
        end
      end
      sleep(3)
    end
  end
  sleep(1)
  if math.random(1,10)==1 then
    if update()then
      term.clear()
      term.setCursorPos(1,1)
      print("Updated images!")
      sleep(2)
    end
  end
end
