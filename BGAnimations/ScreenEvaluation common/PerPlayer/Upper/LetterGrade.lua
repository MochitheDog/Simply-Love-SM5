local player = ...

local playerStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local t = Def.ActorFrame{}
if SL.Global.GameMode ~= "DDR" then
	local grade = playerStats:GetGrade()

	t[#t+1] = LoadActor(THEME:GetPathG("", "_grades/"..grade..".lua"), playerStats)..{
		InitCommand=function(self)
			self:x(70 * (player==PLAYER_1 and -1 or 1))
			self:y(_screen.cy-134)
		end,
		OnCommand=function(self) self:zoom(0.4) end
	}

else
	-- DDR grades
	-- Only affects song evaluation screen, not session summary or anything
	local grade_table = {
		Grade_Tier01 = 1000000, --AAA+
		Grade_Tier02 = 990000, --AAA -- loads star?
		Grade_Tier03 = 950000, --AA+
		Grade_Tier04 = 900000, --AA
		Grade_Tier05 = 890000, --AA-
		Grade_Tier06 = 850000, --A+
		Grade_Tier07 = 800000, --A
		Grade_Tier08 = 790000, --A-
		Grade_Tier09 = 750000, --B+
		Grade_Tier10 = 700000, --B -- loads star wtf
		Grade_Tier11 = 690000, --B-
		Grade_Tier12 = 650000, --C+
		Grade_Tier13 = 600000, --C
		Grade_Tier14 = 590000, --C-
		Grade_Tier15 = 550000, --D+
		Grade_Tier16 = 500000, --D
		Grade_Tier17 = 0, --D
	}
	local score = playerStats:GetScore()
	local grade_tier = nil --Grade_TierXX
    local best = 0
    for grade, min_score in pairs(grade_table) do
        if score >= min_score and min_score >= best then
            grade_tier = grade
            best = min_score
        end
    end
    t[#t+1] = LoadActor(THEME:GetPathG("", "_grades/"..grade_tier..".lua"), playerStats)..{
		InitCommand=function(self)
			self:x(70 * (player==PLAYER_1 and -1 or 1))
			self:y(_screen.cy-134)
		end,
		OnCommand=function(self) self:zoom(0.4) end
	}
end

return t