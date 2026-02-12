local m=peripheral.find("monitor")
m.setTextScale(0.5)
term.redirect(m)
local repo="username/repo"
local branch="main"
local h=http.get("https://api.github.com/repos/"..repo.."/contents/IMGS?ref="..branch)
local imgs=textutils.unserialiseJSON(h.readAll())
h.close()
local files={}
for _,v in ipairs(imgs)do
  if v.name:match("%.nfp$")then
    local r=http.get(v.download_url)
    local p="/tmp/"..v.name
    local f=fs.open(p,"w")
    f.write(r.readAll())
    f.close()
    r.close()
    table.insert(files,p)
  end
end
local w,h=term.getSize()
while true do
  for _,p in ipairs(files)do
    term.clear()
    local img=paintutils.loadImage(p)
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
