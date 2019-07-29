------------------------------------------------------------------------------
-- call this to draw a Quad with a border
-- width of quad, height of quad, and border width, in pixels

function Border(width, height, bw)
	return Def.ActorFrame {
		Def.Quad {
			InitCommand=cmd(zoomto, width-2*bw, height-2*bw;  MaskSource,true)
		},
		Def.Quad {
			InitCommand=cmd(zoomto,width,height; MaskDest)
		},
		Def.Quad {
			InitCommand=cmd(diffusealpha,0; clearzbuffer,true)
		},
	}
end

------------------------------------------------------------------------------
-- There's surely a better way to do this.  I need to research this more.
local is8bit = function(text)
	return text:len() == text:utf8len()
end

-- FIXME: overriding the engine's API like this is convenient but will likely cause things
-- to go haywire if the user switches themes.  I need to think about this.
BitmapText.wrapwidthpixels_orignal = BitmapText.wrapwidthpixels

BitmapText.wrapwidthpixels = function(bmt, w)
	local text = bmt:GetText()

	if not is8bit(text) then
		local lower = 200
		local upper = 240
		bmt:settext("")

		for i=1, text:utf8len() do
			local c = text:utf8sub(i,i)
			local b = c:byte()

			-- if adding this character causes the displayed string to be wider than allowed
			if bmt:settext( bmt:GetText()..c ):GetWidth() > w then
				-- and if that character just added was in the jp range (...maybe)
				if b < upper and b >= lower then
					-- then insert a newline between the previous character and the current
					-- character that caused us to go over
					bmt:settext( bmt:GetText():utf8sub(1,-2).."\n"..c )
				else
					-- otherwise it's trickier, as romance languages only really allow newlines
					-- to be inserted between words, not in the middle of single words
					-- we'll have to "peel back" a character at a time until we hit whitespace
					-- or something in the jp range
					local _text = bmt:GetText()

					for j=i,1,-1 do
						local _c = _text:utf8sub(j,j)
						local _b = _c:byte()

						if _c:match("%s") or (_b < upper and _b >= lower) then
							bmt:settext( _text:utf8sub(1,j) .. "\n" .. _text:utf8sub(j+1) )
							break
						end
					end
				end
			end
		end
	else
		bmt:wrapwidthpixels_orignal(w)
	end

	-- return the BitmapText actor in case the theme is chaining actor commands
	return bmt
end

BitmapText.Truncate = function(bmt, m)
	local text = bmt:GetText()
	local l = text:len()

	-- With SL's Miso and JP fonts, english characters (Miso) tend to render 2-3x less wide
	-- than JP characters. If the text includes JP characters, it is (probably) desired to
	-- truncate the string earlier to achieve the same effect.
	-- Here, we are arbitrarily "weighting" JP characters to count 4x as much as one Miso
	-- character and then scaling the point at which we truncate accordingly.
	-- This is, of course, a VERY broad over-generalization, but It Works For Now™.
	if not is8bit(text) then
		l = 0

		-- a range of bytes I'm considering to indicate JP characters,
		-- mostly derived from empirical observation and guesswork
		-- >= 240 seems to be emojis, the glyphs for which are as wide as Miso in SL, so don't include those
		-- FIXME: If you know more about how this actually works, please submit a pull request.
		local lower = 200
		local upper = 240

		for i=1, text:utf8len() do
			local b = text:utf8sub(i,i):byte()
			l = l + ((b < upper and b >= lower) and 4 or 1)
		end
		m = math.floor(m * (m/l))
	end

	-- if the length of the string is less than the specified truncate point, don't do anything
	if l <= m then return end
	-- otherwise, replace everything after the truncate point with an ellipsis
	bmt:settext( text:utf8sub(1, m) .. "…" )

	-- return the BitmapText actor in case the theme is chaining actor commands
	return bmt
end



------------------------------------------------------------------------------
-- Misc Lua functions that didn't fit anywhere else...

-- return true or nil
CurrentGameIsSupported = function()
	-- a hardcoded list of games that Simply Love supports
	local support = {
		dance	= true,
		pump = true,
		techno = true,
		para = true,
		kb7 = true
	}
	return support[GAMESTATE:GetCurrentGame():GetName()]
end


-- helper function used to detmerine which timing_window a given offset belongs to
function DetermineTimingWindow(offset)
	for i=1,5 do
		if math.abs(offset) < SL.Preferences[SL.Global.GameMode]["TimingWindowSecondsW"..i] + SL.Preferences[SL.Global.GameMode]["TimingWindowAdd"] then
			return i
		end
	end
	return 5
end


function GetCredits()
	local coins = GAMESTATE:GetCoins()
	local coinsPerCredit = PREFSMAN:GetPreference('CoinsPerCredit')
	local credits = math.floor(coins/coinsPerCredit)
	local remainder = coins % coinsPerCredit

	local r = {
		Credits=credits,
		Remainder=remainder,
		CoinsPerCredit=coinsPerCredit
	}
	return r
end

-- Used in Metrics.ini for ScreenRankingSingle and ScreenRankingDouble
function GetStepsTypeForThisGame(type)
	local game = GAMESTATE:GetCurrentGame():GetName()
	-- capitalize the first letter
	game = game:gsub("^%l", string.upper)

	return "StepsType_" .. game .. "_" .. type
end


function GetNotefieldX( player )
	local p = ToEnumShortString(player)
	local game = GAMESTATE:GetCurrentGame():GetName()

	local IsPlayingDanceSolo = (GAMESTATE:GetCurrentStyle():GetStepsType() == "StepsType_Dance_Solo")
	local NumPlayersEnabled = GAMESTATE:GetNumPlayersEnabled()
	local NumSidesJoined = GAMESTATE:GetNumSidesJoined()
	local IsUsingSoloSingles = PREFSMAN:GetPreference('Center1Player') or IsPlayingDanceSolo or (NumSidesJoined==1 and (game=="techno" or game=="kb7"))

	if IsUsingSoloSingles and NumPlayersEnabled == 1 and NumSidesJoined == 1 then return _screen.cx end
	if GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides" then return _screen.cx end

	local NumPlayersAndSides = ToEnumShortString( GAMESTATE:GetCurrentStyle():GetStyleType() )
	return THEME:GetMetric("ScreenGameplay","Player".. p .. NumPlayersAndSides .."X")
end

-- -----------------------------------------------------------------------

-- this is verbose, but it lets us manage what seem to be
-- quirks/oversights in the engine on a per-game + per-style basis

local NoteFieldWidth = {
	-- dance Just Works™.  Wow!  It's almost like this game gets the most attention and fixes.
	dance = {
		single = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) end,
		versus = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) end,
		double = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) end,
		solo = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) end,
	},
	-- the values returned by the engine for Pump are slightly too small(?), so... uh... pad it
	pump = {
		single = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) + 10 end,
		versus = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) + 10 end,
		double = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) + 10 end,
	},
	-- techno works for single8, needs to be smaller for versus8 and double8
	techno = {
		single8 = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) end,
		versus8 = function(p) return (GAMESTATE:GetCurrentStyle():GetWidth(p)/1.65) end,
		double8 = function(p) return (GAMESTATE:GetCurrentStyle():GetWidth(p)/1.65) end,
	},
	-- the values returned for para are also slightly too small, so... pad those, too
	para = {
		single = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) + 10 end,
		versus = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) + 10 end,
	},
	-- kb7 works for single, needs to be smaller for versus
	-- there is no kb7 double (would that be kb14?)
	kb7 = {
		single = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p) end,
		versus = function(p) return GAMESTATE:GetCurrentStyle():GetWidth(p)/1.65 end,
	},
}

function GetNotefieldWidth(player)
	if not player then return false end

	local game = GAMESTATE:GetCurrentGame():GetName()
	local style = GAMESTATE:GetCurrentStyle():GetName()
	return NoteFieldWidth[game][style](player)
end

-- -----------------------------------------------------------------------
-- noteskin_name is a string that matches some available NoteSkin for the current game
-- column is an (optional) string for the column you want returned, like "Left" or "DownRight"
--
-- if no errors are encountered, a full NoteSkin actor is returned
-- otherwise, a generic Def.Actor is returned
-- in both these cases, the Name of the returned actor will be ("NoteSkin_"..noteskin_name)

GetNoteSkinActor = function(noteskin_name, column)

	-- prepare a dummy Actor using the name of NoteSkin in case errors are
	-- encountered so that a valid (inert, not-drawing) actor still gets returned
	local dummy = Def.Actor{
		Name="NoteSkin_"..(noteskin_name or ""),
		InitCommand=function(self) self:visible(false) end
	}

	-- perform first check: does the NoteSkin exist for the current game?
	if not NOTESKIN:DoesNoteSkinExist(noteskin_name) then return dummy end

	local game_name = GAMESTATE:GetCurrentGame():GetName()
	local fallback_column = { dance="Up", pump="UpRight", techno="Up", kb7="Key1" }

	-- prefer the value for column if one was passed in, otherwise use a fallback value
	column = column or fallback_column[game_name] or "Up"

	-- most NoteSkins are free of errors, but we cannot assume they all are
	-- one error in one NoteSkin is enough to halt ScreenPlayerOptions overlay
	-- so, use pcall() to catch errors.  The first argument is the function we
	-- want to check for runtime errors, and the remaining arguments would we what
	-- we would have passed to that function.
	--
	-- Using pcall() like this returns [multiple] values.  A boolean indicating that the
	-- function is error-free (true) or that errors were caught (false), and then whatever
	-- calling that function would have normally returned
	local okay, noteskin_actor = pcall(NOTESKIN.LoadActorForNoteSkin, NOTESKIN, column, "Tap Note", noteskin_name)

	-- if no errors were caught and we have a NoteSkin actor from NOTESKIN:LoadActorForNoteSkin()
	if okay and noteskin_actor then

		-- If we've made it this far, the screen will function without halting, but there
		-- may still be Lua errors in the NoteSkin's InitCommand that might cause the actor
		-- to display strangely (because Lua halted and sizing/positioning/etc. never happened).
		--
		-- There is some version of an "smx" NoteSkin that got passed around the community
		-- that attempts to use a nil constant "FIXUP" in its InitCommand that exhibits this.
		-- So, pcall() again, now specifically on the noteskin_actor's InitCommand if it has one.
		if noteskin_actor.InitCommand then
			okay = pcall(noteskin_actor.InitCommand)
		end

		if okay then
			return noteskin_actor..{
				Name="NoteSkin_"..noteskin_name,
				InitCommand=function(self) self:visible(false) end
			}
		end
	end

	-- if the user has ShowThemeErrors enabled, let them know about the Lua errors via SystemMessage
	if PREFSMAN:GetPreference("ShowThemeErrors") then
		SM( THEME:GetString("ScreenPlayerOptions", "NoteSkinErrors"):format(noteskin_name) )
	end

	return dummy
end

-- -----------------------------------------------------------------------
-- Define what is necessary to maintain and/or increment your combo, per Gametype.
-- For example, in dance Gametype, TapNoteScore_W3 (window #3) is commonly "Great"
-- so in dance, a "Great" will not only maintain a player's combo, it will also increment it.
--
-- We reference this function in Metrics.ini under the [Gameplay] section.
function GetComboThreshold( MaintainOrContinue )
	local CurrentGame = GAMESTATE:GetCurrentGame():GetName()

	local ComboThresholdTable = {
		dance	=	{ Maintain = "TapNoteScore_W3", Continue = "TapNoteScore_W3" },
		pump	=	{ Maintain = "TapNoteScore_W4", Continue = "TapNoteScore_W4" },
		techno	=	{ Maintain = "TapNoteScore_W3", Continue = "TapNoteScore_W3" },
		kb7		=	{ Maintain = "TapNoteScore_W4", Continue = "TapNoteScore_W4" },
		-- these values are chosen to match Deluxe's PARASTAR
		para	=	{ Maintain = "TapNoteScore_W5", Continue = "TapNoteScore_W3" },

		-- I don't know what these values are supposed to actually be...
		popn	=	{ Maintain = "TapNoteScore_W3", Continue = "TapNoteScore_W3" },
		beat	=	{ Maintain = "TapNoteScore_W3", Continue = "TapNoteScore_W3" },
		kickbox	=	{ Maintain = "TapNoteScore_W3", Continue = "TapNoteScore_W3" },

		-- lights is not a playable game mode, but it is, oddly, a selectable one within the operator menu
		-- include dummy values here to prevent Lua errors in case players accidentally switch to lights
		lights =	{ Maintain = "TapNoteScore_W3", Continue = "TapNoteScore_W3" },
	}


	if CurrentGame ~= "para" then
		if SL.Global.GameMode == "StomperZ" or SL.Global.GameMode=="FA+" then
			ComboThresholdTable.dance.Maintain = "TapNoteScore_W4"
			ComboThresholdTable.dance.Continue = "TapNoteScore_W4"
		end
	end

	return ComboThresholdTable[CurrentGame][MaintainOrContinue]
end

-- -----------------------------------------------------------------------

function SetGameModePreferences()
	-- apply the preferences associated with this GameMode
	for key,val in pairs(SL.Preferences[SL.Global.GameMode]) do
		PREFSMAN:SetPreference(key, val)
	end

	-- If we're switching to Casual mode,
	-- we want to reduce the number of judgments,
	-- so turn Decents and WayOffs off now.
	if SL.Global.GameMode == "Casual" then
		SL.Global.ActiveModifiers.WorstTimingWindow = 3

	-- Otherwise, we want all TimingWindows enabled by default.
	else
 		SL.Global.ActiveModifiers.WorstTimingWindow = 5
	end

	-- loop through human players and apply whatever mods need to be set now
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		-- Now that we've set the SL table for WorstTimingWindow appropriately,
		-- use it to apply WorstTimingWindow as a mod.
		local OptRow = CustomOptionRow( "WorstTimingWindow" )
		OptRow:LoadSelections( OptRow.Choices, player )

		-- using PREFSMAN to set the preference for MinTNSToHideNotes apparently isn't
		-- enough when switching gamemodes because MinTNSToHideNotes is also a PlayerOption.
		-- so, set the PlayerOption version of it now, too, to ensure that arrows disappear
		-- at the appropriate judgments during gameplay for this gamemode.
		GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred"):MinTNSToHideNotes(SL.Preferences[SL.Global.GameMode].MinTNSToHideNotes)
	end

	-- these are the prefixes that are prepended to each custom Stats.xml, resulting in
	-- Stats.xml, ECFA-Stats.xml, StomperZ-Stats.xml, Casual-Stats.xml
	-- "FA+" mode is prefixed with "ECFA-" because the mode was previously known as "ECFA Mode"
	-- and I don't want to deal with renaming relatively critical files from the theme.
	-- Thus, scores from FA+ mode will continue to go into ECFA-Stats.xml.
	local prefix = {
		ITG = "",
		["FA+"] = "ECFA-",
		StomperZ = "StomperZ-",
		Casual = "Casual-"
	}

	if PROFILEMAN:GetStatsPrefix() ~= prefix[SL.Global.GameMode] then
		PROFILEMAN:SetStatsPrefix(prefix[SL.Global.GameMode])
	end
end

-- -----------------------------------------------------------------------
-- the available OptionRows for an options screen can change depending on certain conditions
-- these functions start with all possible OptionRows and remove rows as needed
-- whatever string is finally returned is passed off to the pertinent LineNames= in Metrics.ini

function GetOperatorMenuLineNames()
	local lines = "System,KeyConfig,TestInput,Visual,GraphicsSound,Arcade,Input,Theme,MenuTimer,CustomSongs,Advanced,Profiles,Acknowledgments,ClearCredits,Reload"

	-- the TestInput screen only supports dance, pump, and techno; remove it when in other games
	local CurrentGame = GAMESTATE:GetCurrentGame():GetName()
	if not (CurrentGame=="dance" or CurrentGame=="pump" or CurrentGame=="techno") then
		lines = lines:gsub("TestInput,", "")
	end

	-- hide the OptionRow for ClearCredits if we're not in CoinMode_Pay; it doesn't make sense to show for at-home players
	-- note that (EventMode + CoinMode_Pay) will actually place you in CoinMode_Home
	if GAMESTATE:GetCoinMode() ~= "CoinMode_Pay" then
		lines = lines:gsub("ClearCredits,", "")
	end

	-- CustomSongs preferences don't exist in 5.0.x, which many players may still be using
	-- thus, if the preference for CustomSongsEnable isn't found in this version of SM, don't let players
	-- get into the CustomSongs submenu in the OperatorMenu by removing that OptionRow
	if not PREFSMAN:PreferenceExists("CustomSongsEnable") then
		lines = lines:gsub("CustomSongs,", "")
	end
	return lines
end


function GetSimplyLoveOptionsLineNames()
	local lines = "CasualMaxMeter,AutoStyle,DefaultGameMode,CustomFailSet,CreditStacking,MusicWheelStyle,MusicWheelSpeed,SelectProfile,SelectColor,EvalSummary,NameEntry,GameOver,HideStockNoteSksins,DanceSolo,Nice,VisualTheme,RainbowMode"
	if Sprite.LoadFromCached ~= nil then
		lines = lines .. ",UseImageCache"
	end
	return lines
end


function GetPlayerOptions2LineNames()
	local mods = "Turn,Scroll,Hide,ReceptorArrowsPosition,LifeMeterType,DataVisualizations,TargetScore,ActionOnMissedTarget,GameplayExtras,MeasureCounter,MeasureCounterOptions,WorstTimingWindow,ScreenAfterPlayerOptions2"

	-- remove ReceptorArrowsPosition if GameMode isn't StomperZ
	if SL.Global.GameMode ~= "StomperZ" then
		mods = mods:gsub("ReceptorArrowsPosition", "")
	end

	-- remove WorstTimingWindow and LifeMeterType if GameMode is StomperZ
	if SL.Global.GameMode == "StomperZ" then
		mods = mods:gsub("WorstTimingWindow,", ""):gsub("LifeMeterType", "")
	end

	-- ActionOnMissedTarget can automatically fail or restart Gameplay when a target score
	-- becomes impossible to achieve; it really only makes sense in EventMode (i.e., not public arcades)
	-- a second check is performed in ./ScreenGameplay underlay/PerPlayer/TargetScore/default.lua
	-- to ensure it isn't accidentally brought into non-EventMode via player profile
	if not PREFSMAN:GetPreference("EventMode") then
		mods = mods:gsub("ActionOnMissedTarget,", "")
	end

	return mods
end

function GetPlayerOptions3LineNames()
	local mods = "7,8,9,10,11,12,13,Attacks,Vocalization,Characters,ScreenAfterPlayerOptions3"

	-- remove Vocalization if no voice packs were found in the filesystem
	if #FILEMAN:GetDirListing(THEME:GetCurrentThemeDirectory().."/Other/Vocalize/", true, false) < 1 then
		mods = mods:gsub("Vocalization," ,"")
	end

	-- remove Characters if no dancing character directories were found
	if #CHARMAN:GetAllCharacters() < 1 then
		mods = mods:gsub("Characters,", "")
	end

	return mods
end
-- -----------------------------------------------------------------------
-- given a player, return a table of stepartist text for the current song or course
-- so that various screens (SSM, Eval) can cycle through these values and players
-- can see each for brief duration

GetStepsCredit = function(player)
	local t = {}

	if GAMESTATE:IsCourseMode() then
		local course = GAMESTATE:GetCurrentCourse()
		-- scripter
		if course:GetScripter() ~= "" then t[#t+1] = course:GetScripter() end
		-- description
		if course:GetDescription() ~= "" then t[#t+1] = course:GetDescription() end
	else
		local steps = GAMESTATE:GetCurrentSteps(player)
		-- credit
		if steps:GetAuthorCredit() ~= "" then t[#t+1] = steps:GetAuthorCredit() end
		-- description
		if steps:GetDescription() ~= "" then t[#t+1] = steps:GetDescription() end
		-- chart name
		if steps:GetChartName() ~= "" then t[#t+1] = steps:GetChartName() end
	end

	return t
end

-- -----------------------------------------------------------------------
BrighterOptionRows = function()
	if ThemePrefs.Get("RainbowMode") then return true end
	if PREFSMAN:GetPreference("EasterEggs") and MonthOfYear()==11 then return true end -- holiday cheer
	return false
end

-- -----------------------------------------------------------------------
-- account for the possibility that emojis shouldn't be diffused to Color.Black

DiffuseEmojis = function(bmt, text)
	-- loop through each char in the string, checking for emojis; if any are found
	-- don't diffuse that char to be any specific color by selectively diffusing it to be {1,1,1,1}
	for i=1, text:utf8len() do
		if text:utf8sub(i,i):byte() >= 240 then
			bmt:AddAttribute(i-1, { Length=1, Diffuse={1,1,1,1} } )
		end
	end
end

-- -----------------------------------------------------------------------
-- read the theme version from ThemeInfo.ini to display on ScreenTitleMenu underlay
-- this allows players to more easily identify what version of the theme they are currently using

GetThemeVersion = function()
	local file = IniFile.ReadFile( THEME:GetCurrentThemeDirectory() .. "ThemeInfo.ini" )
	if file then
		if file.ThemeInfo and file.ThemeInfo.Version then
			return file.ThemeInfo.Version
		end
	end
	return false
end

-- -----------------------------------------------------------------------
-- functions that attempt to handle the mess that is custom judgment graphic detection/loading

local function FilenameIsMultiFrameSprite(filename)
	-- look for the "[frames wide] x [frames tall]"
	-- and some sort of all-letters file extension
	-- Lua doesn't support an end-of-string regex marker...
	return string.match(filename, " %d+x%d+") and string.match(filename, "%.[A-Za-z]+")
end

function StripSpriteHints(filename)
	-- handle common cases here, gory details in /src/RageBitmapTexture.cpp
	return filename:gsub(" %d+x%d+", ""):gsub(" %(doubleres%)", ""):gsub(".png", "")
end

function GetJudgmentGraphics(mode)
	if mode == 'Casual' then mode = 'ITG' end
	local path = THEME:GetPathG('', '_judgments/' .. mode)
	local files = FILEMAN:GetDirListing(path .. '/')
	local judgment_graphics = {}

	for k,filename in ipairs(files) do

		-- Filter out files that aren't judgment graphics
		-- e.g. hidden system files like .DS_Store
		if FilenameIsMultiFrameSprite(filename) then

			-- use regexp to get only the name of the graphic, stripping out the extension
			local name = StripSpriteHints(filename)

			-- Fill the table, special-casing Love so that it comes first.
			if name == "Love" then
				table.insert(judgment_graphics, 1, filename)
			else
				judgment_graphics[#judgment_graphics+1] = filename
			end
		end
	end

	-- "None" -> no graphic in Player judgment.lua
	judgment_graphics[#judgment_graphics+1] = "None"

	return judgment_graphics
end
