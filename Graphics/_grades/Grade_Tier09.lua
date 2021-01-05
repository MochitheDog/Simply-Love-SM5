if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/b-plus.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/a.png")..{ OnCommand=function(self) self:zoom(0.85) end }
