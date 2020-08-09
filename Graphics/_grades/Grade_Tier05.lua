if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/aa.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/s-plus.png")..{ OnCommand=function(self) self:zoom(0.85) end }