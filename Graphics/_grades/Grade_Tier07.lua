if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/a-plus.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/s-minus.png")..{ OnCommand=function(self) self:zoom(0.85) end }
