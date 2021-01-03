local player, side = unpack(...)

local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local PercentDP = stats:GetPercentDancePoints()
local percent = FormatPercentScore(PercentDP)
-- Format the Percentage string, removing the % symbol
percent = percent:gsub("%%", "")
local scoreDisplay = percent

-- TODO:/ Calculate money score if DDR mode
if SL.Global.GameMode == "DDR" then
	scoreDisplay = "poo"
	local marvs = stats:GetTapNoteScores('TapNoteScore_W1')
	local perfs = stats:GetTapNoteScores('TapNoteScore_W2')
	local greats = stats:GetTapNoteScores('TapNoteScore_W3')
	local goods = stats:GetTapNoteScores('TapNoteScore_W4')
	local boos = stats:GetTapNoteScores('TapNoteScore_W5')
	local misses = stats:GetTapNoteScores('TapNoteScore_Miss')
	local oks = stats:GetRadarActual():GetValue("RadarCategory_Holds") + stats:GetRadarActual():GetValue("RadarCategory_Rolls")
	--jumps count as 1 tap note
	--Using DDRA scoring as detailed here: https://remywiki.com/DanceDanceRevolution_SuperNOVA2_Scoring_System
	-- local notes = stats:GetRadarPossible():GetValue("RadarCategory_Notes")
	local taps_n_holds = stats:GetRadarPossible():GetValue("RadarCategory_TapsAndHolds")
	local total_holds = stats:GetRadarPossible():GetValue("RadarCategory_Holds") + stats:GetRadarPossible():GetValue("RadarCategory_Rolls")
	local step_score = 1000000/(taps_n_holds + total_holds)
	local money_score = (step_score * (marvs + oks)) + ((step_score-10)*perfs) + (((step_score*0.6)-10) * greats) + (((step_score*0.2)-10) * goods)
	if money_score % 10 ~= 0 then
		money_score = math.floor(money_score)
		-- damn this feels janky- round down any decimals to nearest integer, change last digit to 0
		money_score = tostring(money_score):sub(1,-2) .. "0"
	end
	scoreDisplay = money_score
	-- Can't accurately calculate score for shock arrows
	--  so I guess we'll just ignore them like everyone else who tried implementing DDR money score

end
return Def.ActorFrame{
	Name="PercentageContainer"..ToEnumShortString(player),
	OnCommand=function(self)
		self:y( _screen.cy-26 )
	end,

	-- dark background quad behind player percent score
	Def.Quad{
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(158.5, 60)
			self:horizalign(side==PLAYER_1 and left or right)
			self:x(150 * (side == PLAYER_1 and -1 or 1))
		end
	},
	-- Percentage score on main score breakdown pane

	LoadFont("Wendy/_wendy white")..{
		Name="Percent",
		Text=scoreDisplay,
		InitCommand=function(self)
			self:horizalign(right):zoom(0.585)
			self:x( (side == PLAYER_1 and 1.5 or 141))
		end
	}
}
