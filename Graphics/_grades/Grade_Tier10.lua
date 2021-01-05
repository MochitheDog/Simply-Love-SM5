if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/b.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/a-minus.png")..{ OnCommand=function(self) self:zoom(0.85) end }