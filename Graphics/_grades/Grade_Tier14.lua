if SL.Global.GameMode=="DDR" then
    return LoadActor("./assets/c-minus.png")..{ OnCommand=function(self) self:zoom(0.85) end }
end

return LoadActor("./assets/c-plus.png")..{ OnCommand=function(self) self:zoom(0.85) end }
