if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/f.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/d.png")..{ 	OnCommand=function(self) self:zoom(0.85) end }