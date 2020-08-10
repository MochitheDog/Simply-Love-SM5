local player = Var "Player"
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers

-- DDR Variables
local LowerJudge=0;
local Pulse = THEME:GetMetric("Combo", "PulseCommand");
local PulseLabel = THEME:GetMetric("Combo", "PulseLabelCommand");

local NumberMinZoom = THEME:GetMetric("Combo", "NumberMinZoom");
local NumberMaxZoom = THEME:GetMetric("Combo", "NumberMaxZoom");
local NumberMaxZoomAt = THEME:GetMetric("Combo", "NumberMaxZoomAt");

local LabelMinZoom = THEME:GetMetric("Combo", "LabelMinZoom");
local LabelMaxZoom = THEME:GetMetric("Combo", "LabelMaxZoom");

local ZoomFactor = THEME:GetMetric("Combo", "ZoomFactor");
-- end DDR Variables

local available_fonts = GetComboFonts()
local combo_font = (FindInTable(mods.ComboFont, available_fonts) ~= nil and mods.ComboFont) or available_fonts[1] or nil

if mods.HideCombo or combo_font == nil then
	return Def.Actor{ InitCommand=function(self) self:visible(false) end }
end

-- combo colors used in Casual and ITG
local colors = {}
colors.FullComboW1 = {color("#C8FFFF"), color("#6BF0FF")} -- blue combo
colors.FullComboW2 = {color("#FDFFC9"), color("#FDDB85")} -- gold combo
colors.FullComboW3 = {color("#C9FFC9"), color("#94FEC1")} -- green combo
colors.FullComboW4 = {color("#FFFFFF"), color("#FFFFFF")} -- white combo

-- combo colors used in FA+
if SL.Global.GameMode == "FA+" then
	colors.FullComboW1 = {color("#C8FFFF"), color("#6BF0FF")} -- blue combo
	colors.FullComboW2 = {color("#C8FFFF"), color("#6BF0FF")} -- blue combo
	colors.FullComboW3 = {color("#FDFFC9"), color("#FDDB85")} -- gold combo
	colors.FullComboW4 = {color("#C9FFC9"), color("#94FEC1")} -- green combo
end

local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt")

local af = Def.ActorFrame{
	InitCommand=function(self)
		self:draworder(101)
	end,

	ComboCommand=function(self, params)
		local CurrentCombo = params.Misses or params.Combo

		-- if the combo has reached (or surpassed) the threshold to be shown, display the AF, otherwise hide it
		self:visible( CurrentCombo ~= nil and CurrentCombo >= ShowComboAt )
	end,
}

if not mods.HideComboExplosions then
	-- load the combo milestones actors into the Player combo; they will
	-- listen for the appropriate Milestone command from the engine
	af[#af+1] = LoadActor( THEME:GetPathG("Combo","100Milestone") )..{ Name="OneHundredMilestone" }
	af[#af+1] = LoadActor( THEME:GetPathG("Combo","1000Milestone") )..{ Name="OneThousandMilestone" }
end

-- Combo fonts should be monospaced so that each digit's alignment remains
-- consistent (i.e., not visually distracting) as the combo continually grows

local combo_bmt = LoadFont("_Combo Fonts/" .. combo_font .."/" .. combo_font)..{
	Name="Number",
	OnCommand=function(self)
		self:shadowlength(1):vertalign(middle):zoom(0.75)
	end,
	JudgmentMessageCommand=function(self, params)
		if params.Player ~= player then return end;
		if params.TapNoteScore=='TapNoteScore_W1' and LowerJudge<1 then
			LowerJudge=1;
		elseif params.TapNoteScore=='TapNoteScore_W2' and LowerJudge<2 then
			LowerJudge=2;
		elseif params.TapNoteScore=='TapNoteScore_W3' and LowerJudge<3 then
			LowerJudge=3;
		elseif params.TapNoteScore=='TapNoteScore_W4' and LowerJudge<4 then
			LowerJudge=4;
		elseif params.TapNoteScore=='TapNoteScore_CheckpointMiss' 
			or params.TapNoteScore=='TapNoteScore_W5' 
			or params.TapNoteScore=='TapNoteScore_Miss' then
			LowerJudge=0;
		end
	end,
	ComboCommand=function(self, params)
		self:settext( params.Combo or params.Misses or "" )
		local iCombo = params.Combo;

		if SL.Global.GameMode == "DDR" then
			params.Zoom = scale( iCombo, 0, NumberMaxZoomAt, NumberMinZoom*ZoomFactor, NumberMaxZoom*ZoomFactor );
			params.Zoom = clamp( params.Zoom, NumberMinZoom*ZoomFactor, NumberMaxZoom*ZoomFactor );
			--params.LabelZoom = scale( iCombo, 0, 100, 0.8, 0.9 );
			--params.LabelZoom = clamp( params.LabelZoom, LabelMinZoom, 0.9);

			-- fancy (yet maybe also very distracting) animation
			--local Number_X = -20;
			--local Label_X = -13;
			--local Label_Y = -42;
	
			--if iCombo < 10 then
				--Number_X = 20;
				--Label_X = -13;
				--Label_Y = -44;
			--end
	
			--if iCombo > 9 then
				--Number_X = 8;
				--Label_X = -4;
				--Label_Y = -42;
			--end

			if iCombo > 99 then
				params.Zoom = scale( iCombo, 0, NumberMaxZoomAt, 1*ZoomFactor, 1*ZoomFactor);
				params.Zoom = clamp( params.Zoom, 1*ZoomFactor, 1*ZoomFactor);
				--Number_X = -27;
				--Label_X = 27;
				--Label_Y = -36;
			end
	
			if iCombo > 999 then
				params.Zoom = scale( iCombo, 0, NumberMaxZoomAt, 0.825*ZoomFactor, 0.825)*ZoomFactor;
				params.Zoom = clamp( params.Zoom, 0.825*ZoomFactor, 0.825*ZoomFactor);
				--Number_X = 34;
				--Label_X = 34;
				--Label_Y = -43;
			end
	
			if iCombo > 9999 then
				params.Zoom = scale( iCombo, 0, NumberMaxZoomAt, 0.66*ZoomFactor, 0.66*ZoomFactor);
				params.Zoom = clamp( params.Zoom, 0.66*ZoomFactor, 0.66*ZoomFactor);
				--Number_X = -40;
				--Label_X = 40;
				--Label_Y = -47;
			end
	
			if iCombo > 99999 then
				params.Zoom = scale( iCombo, 0, NumberMaxZoomAt, 0.55, 0.55);
				params.Zoom = clamp( params.Zoom, 0.55, 0.55);
				--Number_X = -45;
				--Label_X = 45;
				--Label_Y = -49;
			end

			--self:x(Number_X)
			--label:x(Label_X)
			--label:y(Label_Y)

			-- Animate
			self:y(-30)
			Pulse(self, params)
			--PulseLabelCommand(label, param)

			-- DDRFIXME: Only works for one player I hypothesize??? The patterns laid out by other similar implementations
			-- take the values of both first player and second player in a single array...
			-- Marvelous combo
			if LowerJudge==1 then
				self:diffuse(color("#fffce0"))
				self:glowshift();

			-- Perfect combo
			elseif LowerJudge==2 then
				self:diffuse(color("#fff47a"))
				self:glowshift();

			-- Great combo
			elseif LowerJudge==3 then
				self:diffuse(color("#82ff80"))
				self:glowshift();

			-- Good combo
			elseif LowerJudge==4 then
				self:diffuse(color("#21cce8"))
				self:glowshift();
			end

			--self:zoom(1.2):linear(0.05):zoom(1)
			self:settext( params.Combo .. " combo" or params.Misses or "" )
		else
			self:diffuseshift():effectperiod(0.8):playcommand("Color", params)
		end
	end,
	ColorCommand=function(self, params)
		-- Though this if/else chain may seem strange (why not reduce it to a single table for quick lookup?)
		-- the FullCombo params passed in from the engine are also strange, so this accommodates.
		--
		-- the params table will always contain a "Combo" value if the player is comboing notes successfully
		-- or a "Misses" value if the player is not hitting any notes and earning consecutive misses.
		--
		-- Once we are 20% through the song (this value is specifed in Metrics.ini in the [Player] section
		-- using PercentUntilColorCombo), the engine will start to include FullCombo parameters.
		--
		-- If the player has only earned W1 judgments so far, the params table will look like:
		-- { Combo=1001, FullComboW1=true, FullComboW2=true, FullComboW3=true, FullComboW4=true }
		--
		-- if the player has earned some combination of W1 and W2 judgments, the params table will look like:
		-- { Combo=1005, FullComboW2=true, FullComboW3=true, FullComboW4=true }
		--
		-- And so on. While the information is technically true (a FullComboW2 does imply a FullComboW3), the
		-- explicit presence of all those parameters makes checking truthiness here in the theme a little
		-- awkward.  We need to explicitly check for W1 first, then W2, then W3, and so on...

		if params.FullComboW1 then
			self:effectcolor1(colors.FullComboW1[1]):effectcolor2(colors.FullComboW1[2])

		elseif params.FullComboW2 then
			self:effectcolor1(colors.FullComboW2[1]):effectcolor2(colors.FullComboW2[2])

		elseif params.FullComboW3 then
			self:effectcolor1(colors.FullComboW3[1]):effectcolor2(colors.FullComboW3[2])

		elseif params.FullComboW4 then
			self:effectcolor1(colors.FullComboW4[1]):effectcolor2(colors.FullComboW4[2])

		elseif params.Combo then
			self:stopeffect():diffuse( Color.White ) -- not a full combo; no effect, always just #ffffff

		elseif params.Misses then
			self:stopeffect():diffuse( Color.Red ) -- Miss Combo; no effect, always just #ff0000
		end
	end
}

-- -----------------------------------------------------------------------
-- EasterEggs

if combo_font == "Source Code" then
	combo_bmt.ComboCommand=function(self, params)
		-- "Hexadecimal is a virus of incredible power and unpredictable insanity from Lost Angles."
		-- https://reboot.fandom.com/wiki/Hexadecimal
		self:settext( string.format("%X", tostring(params.Combo or params.Misses or 0)):lower() )
		self:diffuseshift():effectperiod(0.8):playcommand("Color", params)
	end
end

if combo_font == "Wendy (Cursed)" then
	combo_bmt.ColorCommand=function(self, params)
		if params.FullComboW3 then
			self:rainbowscroll(true)

		elseif params.Combo then
			-- combo broke at least once; stop the rainbow effect and diffuse white
			self:zoom(0.75):horizalign(center):rainbowscroll(false):stopeffect():diffuse( Color.White )

		elseif params.Misses then
			self:stopeffect():rainbowscroll(false):diffuse( Color.Red ) -- Miss Combo
			self:zoom(self:GetZoom() * 1.001)
			-- horizalign of center until the miss combo is wider than this player's notefield
			-- then, align so that it doesn't encroach into the other player's half of the screen
			if (#GAMESTATE:GetHumanPlayers() > 1) and ((self:GetWidth()*self:GetZoom()) > GetNotefieldWidth()) then
				self:horizalign(player == PLAYER_1 and right or left):x( (self:GetWidth()) * (player == PLAYER_1 and 1 or -1)  )
			end
		end
	end
end
-- -----------------------------------------------------------------------

af[#af+1] = combo_bmt

return af