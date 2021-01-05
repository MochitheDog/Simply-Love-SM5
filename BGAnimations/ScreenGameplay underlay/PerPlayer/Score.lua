local player = ...
local pn = ToEnumShortString(player)

local mods = SL[pn].ActiveModifiers
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NumPlayers = #GAMESTATE:GetHumanPlayers()

-- For DDR scoring
local tmp_Score = {0,0};
local score = {0,0};
local TapNoteScores = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
local TapNoteJudgments = { W1=0, W2=0, W3=0, W4=0, W5=0, Miss=0 }
local RadarCategories = { 'Holds', 'Rolls' }
local RadarCategoryJudgments = { Holds=0, Rolls=0 }
-- -----------------------------------------------------------------------
-- first, check for conditions where we might not draw the score actor at all

if mods.HideScore then return end

if NumPlayers > 1
and mods.NPSGraphAtTop
and not IsUltraWide
then
	return
end

-- -----------------------------------------------------------------------
-- set up some preliminary variables and calculations for positioning and zooming

local styletype = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType())

local pos = {
	[PLAYER_1] = { x=(_screen.cx - clamp(_screen.w, 640, 854)/4.3),  y=56 },
	[PLAYER_2] = { x=(_screen.cx + clamp(_screen.w, 640, 854)/2.75), y=56 },
}

local dance_points, percent
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Notes" )

-- determine how many digits are needed to express the number of notes in base-10
local digits = (math.floor(math.log10(total_tapnotes)) + 1)
-- subtract 4 from the digit count; we're only really interested in how many digits past 4
-- this stepcount is so we can use it to align the score actor in the StepStats pane if needed
-- aligned-with-4-digits is the default
digits = clamp(math.max(4, digits) - 4, 0, 3)

local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)

local ar_scale = {
	sixteen_ten  = 0.825,
	sixteen_nine = 1
}
local zoom_factor = clamp(scale(GetScreenAspectRatio(), 16/10, 16/9, ar_scale.sixteen_ten, ar_scale.sixteen_nine), 0, 1.125)

-- -----------------------------------------------------------------------
local scoreText = "0.00"
if SL.Global.GameMode == "DDR" then
	scoreText = "0"
end
return LoadFont("Wendy/_wendy monospace numbers")..{
	Text=scoreText,
	Name=pn.."Score",
	InitCommand=function(self)
		self:valign(1):horizalign(right)
		if SL.Global.GameMode ~= "DDR" then
			self:zoom(0.5)
		else
			self:zoom(0.4)
		end
	end,

	-- FIXME: this is out of control and points to the need for a generalized approach
	--        to positioning and scaling actors based on AspectRatio (4:3, 16:10, 16:9, 21:9),
	--        Step Stats (drawing or not),
	--        NPSGraphAtTop (drawing or not),
	--        Center1Player (see GetNotefieldX() in ./Scripts/SL-Helpers.lua)
	--        and which players are joined

	BeginCommand=function(self)
		-- assume "normal" score positioning first, but there are many reasons it will need to be moved
		if SL.Global.GameMode ~= "DDR" then
			self:xy( pos[player].x, pos[player].y )
		else
			self:xy( pos[player].x+20, pos[player].y )
		end

		if mods.NPSGraphAtTop and styletype ~= "OnePlayerTwoSides" then
			-- if NPSGraphAtTop and Step Statistics and not double,
			-- move the score down into the stepstats pane under
			-- the jugdgment breakdown
			if mods.DataVisualizations=="Step Statistics" then
				local step_stats = self:GetParent():GetChild("StepStatsPane"..pn)

				-- Step Statistics might be true in the SL table from a previous game session
				-- but current conditions might be such that it won't actually appear.
				-- Ensure the StepStats ActorFrame is present before trying to traverse it.
				if step_stats then
					local judgmentnumbers = step_stats:GetChild("BannerAndData"):GetChild("JudgmentNumbers"):GetChild("")[1]

					-- -----------------------------------------------------------------------
					-- FIXME: "padding" is a lazy fix for multiple nested ActorFrames having zoom applied and
					--         me not feeling like recursively crawling the AF tree to factor in each zoom
					local padding

					if NoteFieldIsCentered then
						if IsUltraWide then
							padding = 37
						else
							padding = SL_WideScale(-11.5,27)
						end

					else
						if IsUltraWide then
							if NumPlayers > 1 then
								padding = -2
							else
								padding = 37
							end
						else
							padding = 37
						end
					end

					-- -----------------------------------------------------------------------

					if IsUsingWideScreen() and not (IsUltraWide and NumPlayers > 1) then
						-- pad with an additional ~14px for each digit past 4 the stepcount goes
						-- this keeps the score right-aligned with the right edge of the judgment
						-- counts in the StepStats pane
						padding = padding + (digits * 14)

						if NoteFieldIsCentered then
							padding = clamp(padding, 0, WideScale(-12,43))
							self:zoom( self:GetZoom() * zoom_factor )
						end
					end

					self:x(step_stats:GetX() + judgmentnumbers:GetX() + padding)
					if  IsUltraWide and NumPlayers > 1 then
						self:y(_screen.cy - 2)
					else
						self:y( _screen.cy + 42 )
					end
				end

			-- if NPSGraphAtTop but not Step Statistics
			else
				-- if not Center1Player, move the score right or left
				-- within the normal gameplay header to where the
				-- other player's score would be if this were versus
				if not NoteFieldIsCentered then
					self:x( pos[ OtherPlayer[player] ].x )
					self:y( pos[ OtherPlayer[player] ].y )
				end
				-- if NoteFieldIsCentered, no need to move the score
			end
		end
	end,
	JudgmentMessageCommand=function(self, params)	
		if SL.Global.GameMode ~= "DDR" then
			self:queuecommand("RedrawScore")
		else
			local radar = GAMESTATE:GetCurrentSteps(params.Player):GetRadarValues(params.Player);
			-- Basically copy-paste as how stepstatistics gets its numbers but repurposed for calculating money score
			--  It's done this way because I tried pss:GetTapNoteScores but for some reason those don't start updating until the 
			--  second note, resulting in incorrect score being displayed
			for index, window in ipairs(TapNoteScores) do
				if params.Player ~= player then return end
				if params.HoldNoteScore then break end

				if params.TapNoteScore and ToEnumShortString(params.TapNoteScore) == window then
					TapNoteJudgments[window] = TapNoteJudgments[window] + 1

				end
			end
			local holds = 0

			for index, RCType in ipairs(RadarCategories) do
				if params.Player ~= player then return end
				if not params.TapNoteScore then break end

				if RCType=="Holds" and params.TapNote and params.TapNote:GetTapNoteSubType() == "TapNoteSubType_Hold" then
					if params.HoldNoteScore == "HoldNoteScore_Held" then
						RadarCategoryJudgments.Holds = RadarCategoryJudgments.Holds + 1
					end

				elseif RCType=="Rolls" and params.TapNote and params.TapNote:GetTapNoteSubType() == "TapNoteSubType_Roll" then
					if params.HoldNoteScore == "HoldNoteScore_Held" then
					 	RadarCategoryJudgments.Rolls = RadarCategoryJudgments.Rolls + 1
					end
				end 
				-- Get possible holds/rolls
				local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
				if StepsOrTrail then
					local rv = StepsOrTrail:GetRadarValues(player)
					local possible_holds = rv:GetValue( RCType )
					-- non-static courses (for example, "Most Played 1-4") will return -1 here
					if possible_holds < 0 then possible_holds = 0 end
					holds = holds + possible_holds
				end
			end
			local marv = TapNoteJudgments.W1
			local perf = TapNoteJudgments.W2
			local greats = TapNoteJudgments.W3
			local goods = TapNoteJudgments.W4
			local helds = RadarCategoryJudgments.Holds + RadarCategoryJudgments.Rolls

			local maxsteps = radar:GetValue('RadarCategory_TapsAndHolds')+holds
			local sc = 1000000/maxsteps
			local money_score = ((sc * (marv + helds)) + ((sc - 10) * perf) + (((.6*sc) - 10) * greats) + (((.2*sc) - 10) * goods) )

			money_score = math.floor(money_score)
			-- I guess SetScore() GetScore() must handle making the last digit 0
			pss:SetScore(money_score)
			self:settext(pss:GetScore())
		end
	end,
	RedrawScoreCommand=function(self)
		dance_points = pss:GetPercentDancePoints()
		percent = FormatPercentScore( dance_points ):sub(1,-2)
		self:settext(percent)
	end
}
