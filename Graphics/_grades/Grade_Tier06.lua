if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/aa-minus.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/s.png")..{ OnCommand=function(self) self:zoom(0.85) end }
