--[[START EXPERIENCE DATA]]
local ExperienceData = {}
ExperienceData.__index = ExperienceData

setmetatable(ExperienceData, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function ExperienceData.new()
	local self = setmetatable({}, ExperienceData)

	self.firstUpdate = true;
	self.currentExperience = 0;
	self.requiredExperience = 0;
	self.previousCurrentExperience = 0;
	self.previousRequiredExperience = 0;
	self.currentPercent = 0;
	self.lastExperienceGain = 0;
	self.killsTilNextLevel = 0;
	self.experiencePerHour = 0;
	self.experienceGained = 0;
	self.timeTilLevel = 0;

	return self
end

function ExperienceData:reset()
	self.firstUpdate = true;
	self.currentExperience = 0;
	self.requiredExperience = 0;
	self.previousCurrentExperience = 0;
	self.previousRequiredExperience = 0;
	self.currentPercent = 0;
	self.lastExperienceGain = 0;
	self.killsTilNextLevel = 0;
	self.experiencePerHour = 0;
	self.experienceGained = 0;
	self.timeTilLevel = 0;
end
--[[END EXPERIENCE DATA]]

_G["EXPERIENCE_VIEWER"] = {};
_G["EXPERIENCE_VIEWER"]["baseExperienceData"] = _G["EXPERIENCE_VIEWER"]["baseExperienceData"] or ExperienceData();
_G["EXPERIENCE_VIEWER"]["classExperienceData"] = _G["EXPERIENCE_VIEWER"]["classExperienceData"] or ExperienceData();
_G["EXPERIENCE_VIEWER"]["startTime"] = _G["EXPERIENCE_VIEWER"]["startTime"] or os.clock();
_G["EXPERIENCE_VIEWER"]["elapsedTime"] = _G["EXPERIENCE_VIEWER"]["elapsedTime"] or os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);
_G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] = _G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] or 3600;
_G["EXPERIENCE_VIEWER"]["headerTablePositions"] = _G["EXPERIENCE_VIEWER"]["headerTablePositions"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["baseTablePositions"] = _G["EXPERIENCE_VIEWER"]["baseTablePositions"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["classTablePositions"] = _G["EXPERIENCE_VIEWER"]["classTablePositions"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["frameWidths"] = _G["EXPERIENCE_VIEWER"]["frameWidths"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["padding"] = _G["EXPERIENCE_VIEWER"]["padding"] or 5;

local acutil = require("acutil");

function EXPVIEWER_ON_INIT(addon, frame)
	EXPVIEWER_LOAD_SETTINGS();

	_G["EXPERIENCE_VIEWER"].isDragging = false;
	frame:SetEventScript(ui.LBUTTONDOWN, "EXPVIEWER_START_DRAG");
	frame:SetEventScript(ui.LBUTTONUP, "EXPVIEWER_END_DRAG");

	acutil.slashCommand("/expviewer", EXPVIEWER_TOGGLE_FRAME);

	frame:EnableHitTest(1);
	frame:SetEventScript(ui.RBUTTONDOWN, "EXPVIEWER_CONTEXT_MENU");

	addon:RegisterMsg('EXP_UPDATE', 'EXPVIEWER_EXP_UPDATE');
	addon:RegisterMsg('JOB_EXP_UPDATE', 'EXPVIEWER_JOB_EXP_UPDATE');
	addon:RegisterMsg('JOB_EXP_ADD', 'EXPVIEWER_JOB_EXP_UPDATE');
	addon:RegisterMsg("FPS_UPDATE", "EXPVIEWER_CALCULATE_TICK");

	if _G["EXPERIENCE_VIEWER"]["settings"].showExperienceViewer then
		frame:ShowWindow(1);
	else
		frame:ShowWindow(0);
	end

	MOVE_FRAME_TO_SAVED_POSITION();
	frame:SetSkinName(_G["EXPERIENCE_VIEWER"]["settings"].skin);

	UPDATE_BUTTONS(frame);

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_START_DRAG()
	_G["EXPERIENCE_VIEWER"].isDragging = true;
end

function EXPVIEWER_END_DRAG()
	EXPVIEWER_SAVE_SETTINGS();
	_G["EXPERIENCE_VIEWER"].isDragging = false;
end

function MOVE_FRAME_TO_SAVED_POSITION()
	local frame = ui.GetFrame("expviewer");

	if frame ~= nil and not _G["EXPERIENCE_VIEWER"].isDragging then
		frame:Move(0, 0);
		frame:SetOffset(_G["EXPERIENCE_VIEWER"]["settings"].xPosition, _G["EXPERIENCE_VIEWER"]["settings"].yPosition);
	end
end

function EXPVIEWER_TOGGLE_FRAME()
	ui.ToggleFrame("expviewer");
	_G["EXPERIENCE_VIEWER"]["settings"].showExperienceViewer = not _G["EXPERIENCE_VIEWER"]["settings"].showExperienceViewer;
	EXPVIEWER_SAVE_SETTINGS();
end

function EXPVIEWER_CONTEXT_MENU()
	local skinList = {
		"shadow_box",
		"test_Item_tooltip_normal",
		"systemmenu_vertical",
		"chat_window",
		"popup_rightclick",
		"persoanl_shop_basicframe",
		"tutorial_skin",
		"slot_name",
		"padslot_onskin",
		"padslot_offskin2",
		"monster_skill_bg",
		"tab2_btn",
		"fullblack_bg",
		"testjoo_buttons", --clear
		"test_skin_01_btn_cursoron",
		"test_skin_01_btn_clicked",
		"test_normal_button",
		"frame_bg",
		"textview",
		"listbox",
		"box_glass",
		"tooltip1",
		"textballoon",
		"quest_box",
		"guildquest_box",
		"balloonskin_buy",
		"barrack_creat_win",
		"pip_simple_frame"
	};

	local context = ui.CreateContextMenu("EXPVIEWER_RBTN", "Experience Viewer", 0, 0, 300, 100);

	ui.AddContextMenuItem(context, "Reset Session", "RESET()");
	ui.AddContextMenuItem(context, "Save Settings", string.format("EXPVIEWER_SAVE_SETTINGS();"));
	ui.AddContextMenuItem(context, "Hide (/expviewer)", string.format("EXPVIEWER_TOGGLE_FRAME();"));

	local subContextToggle = ui.CreateContextMenu("SUBCONTEXT_TOGGLE", "", 0, 0, 0, 0);
	ui.AddContextMenuItem(subContextToggle, "Current / Required", string.format("EXPVIEWER_TOGGLE_CURRENT();"));
	ui.AddContextMenuItem(subContextToggle, "Current %", string.format("EXPVIEWER_TOGGLE_CURRENT_PERCENT();"));
	ui.AddContextMenuItem(subContextToggle, "Last Gained", string.format("EXPVIEWER_TOGGLE_LAST_GAINED();"));
	ui.AddContextMenuItem(subContextToggle, "TNL", string.format("EXPVIEWER_TOGGLE_TNL();"));
	ui.AddContextMenuItem(subContextToggle, "Exp/Hr", string.format("EXPVIEWER_TOGGLE_EXPERIENCE_PER_HOUR();"));
	ui.AddContextMenuItem(subContextToggle, "ETA", string.format("EXPVIEWER_TOGGLE_TIME_TIL_LEVEL();"));
	ui.AddContextMenuItem(subContextToggle, "Cancel", "None");
	ui.AddContextMenuItem(context, "Toggle {img white_right_arrow 18 18}", "", nil, 0, 1, subContextToggle);

	local subContextSkin = ui.CreateContextMenu("SUBCONTEXT_SKIN", "", 0, 0, 0, 0);

	for i=1,#skinList do
		ui.AddContextMenuItem(subContextSkin, skinList[i], string.format("EXPVIEWER_CHANGE_SKIN('%s')", skinList[i]));
	end

	ui.AddContextMenuItem(context, "Skin {img white_right_arrow 18 18}", "", nil, 0, 1, subContextSkin);

	subContextSkin:Resize(300, subContextSkin:GetHeight());
	subContextToggle:Resize(300, subContextToggle:GetHeight());
	context:Resize(300, context:GetHeight());

	ui.OpenContextMenu(context);
end

function EXPVIEWER_CHANGE_SKIN(skin)
	local frame = ui.GetFrame("expviewer");
	frame:SetSkinName(skin);
	_G["EXPERIENCE_VIEWER"]["settings"].skin = skin;
	EXPVIEWER_SAVE_SETTINGS();
end

--cause I'm lazy...
function EXPVIEWER_TOGGLE_CURRENT()
	_G["EXPERIENCE_VIEWER"]["settings"].showCurrentRequiredExperience = not _G["EXPERIENCE_VIEWER"]["settings"].showCurrentRequiredExperience;
	EXPVIEWER_SAVE_SETTINGS();

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_CURRENT_PERCENT()
	_G["EXPERIENCE_VIEWER"]["settings"].showCurrentPercent = not _G["EXPERIENCE_VIEWER"]["settings"].showCurrentPercent;
	EXPVIEWER_SAVE_SETTINGS();

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_LAST_GAINED()
	_G["EXPERIENCE_VIEWER"]["settings"].showLastGainedExperience = not _G["EXPERIENCE_VIEWER"]["settings"].showLastGainedExperience;
	EXPVIEWER_SAVE_SETTINGS();

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_TNL()
	_G["EXPERIENCE_VIEWER"]["settings"].showKillsTilNextLevel = not _G["EXPERIENCE_VIEWER"]["settings"].showKillsTilNextLevel;
	EXPVIEWER_SAVE_SETTINGS();

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_EXPERIENCE_PER_HOUR()
	_G["EXPERIENCE_VIEWER"]["settings"].showExperiencePerHour = not _G["EXPERIENCE_VIEWER"]["settings"].showExperiencePerHour;
	EXPVIEWER_SAVE_SETTINGS();

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_TIME_TIL_LEVEL()
	_G["EXPERIENCE_VIEWER"]["settings"].showTimeTilLevel = not _G["EXPERIENCE_VIEWER"]["settings"].showTimeTilLevel;
	EXPVIEWER_SAVE_SETTINGS();

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_SAVE_SETTINGS()
	if _G["EXPERIENCE_VIEWER"]["settings"] == nil then
		_G["EXPERIENCE_VIEWER"]["settings"] = {
			xPosition = 0;
			yPosition = 0;
			showCurrentRequiredExperience = true;
			showCurrentPercent = true;
			showLastGainedExperience = true;
			showKillsTilNextLevel = true;
			showExperiencePerHour = true;
			showTimeTilLevel = true;
			showExperienceViewer = true;
			skin = "shadow_box";
		};
	else
		local frame = ui.GetFrame("expviewer");
		_G["EXPERIENCE_VIEWER"]["settings"].xPosition = frame:GetX();
		_G["EXPERIENCE_VIEWER"]["settings"].yPosition = frame:GetY();
	end

	acutil.saveJSON("../addons/expviewer/settings.json", _G["EXPERIENCE_VIEWER"]["settings"]);
end

function EXPVIEWER_LOAD_SETTINGS()
	local settings, error = acutil.loadJSON("../addons/expviewer/settings.json");

	if error then
		EXPVIEWER_SAVE_SETTINGS();
	else
		_G["EXPERIENCE_VIEWER"]["settings"] = settings;
	end
end

function EXPVIEWER_EXP_UPDATE(frame, msg, argStr, argNum)
	if msg == 'EXP_UPDATE' then
		_G["EXPERIENCE_VIEWER"]["elapsedTime"] = os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);

		--SET BASE CURRENT/REQUIRED EXPERIENCE
		_G["EXPERIENCE_VIEWER"]["baseExperienceData"].previousRequiredExperience = _G["EXPERIENCE_VIEWER"]["baseExperienceData"].requiredExperience;
		_G["EXPERIENCE_VIEWER"]["baseExperienceData"].currentExperience = session.GetEXP();
		_G["EXPERIENCE_VIEWER"]["baseExperienceData"].requiredExperience = session.GetMaxEXP();

		--CALCULATE EXPERIENCE
		CALCULATE_EXPERIENCE_DATA(_G["EXPERIENCE_VIEWER"]["baseExperienceData"], _G["EXPERIENCE_VIEWER"]["elapsedTime"]);

		UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	end
end

function EXPVIEWER_JOB_EXP_UPDATE(frame, msg, str, exp, tableinfo)
	_G["EXPERIENCE_VIEWER"]["elapsedTime"] = os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);

	--CALCULATE EXPERIENCE
	local currentTotalClassExperience = exp;
	local currentClassLevel = tableinfo.level;

	--SET CLASS CURRENT/REQUIRED EXPERIENCE
	_G["EXPERIENCE_VIEWER"]["classExperienceData"].previousRequiredExperience = _G["EXPERIENCE_VIEWER"]["classExperienceData"].requiredExperience;
	_G["EXPERIENCE_VIEWER"]["classExperienceData"].currentExperience = exp - tableinfo.startExp;
	_G["EXPERIENCE_VIEWER"]["classExperienceData"].requiredExperience = tableinfo.endExp - tableinfo.startExp;

	--CALCULATE EXPERIENCE
	CALCULATE_EXPERIENCE_DATA(_G["EXPERIENCE_VIEWER"]["classExperienceData"], _G["EXPERIENCE_VIEWER"]["elapsedTime"]);

	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function CALCULATE_EXPERIENCE_DATA(experienceData, elapsedTime)
	if experienceData.firstUpdate == true then
		experienceData.previousCurrentExperience = experienceData.currentExperience;
		experienceData.firstUpdate = false;
		return;
	end

	--[[PERFORM CALCULATIONS]]
	--if we leveled up...
	if experienceData.requiredExperience > experienceData.previousRequiredExperience then
		experienceData.lastExperienceGain = (experienceData.previousRequiredExperience - experienceData.previousCurrentExperience) + experienceData.currentExperience;
	else
		experienceData.lastExperienceGain = experienceData.currentExperience - experienceData.previousCurrentExperience;
	end

	experienceData.experienceGained = experienceData.experienceGained + experienceData.lastExperienceGain;
	experienceData.currentPercent = experienceData.currentExperience / experienceData.requiredExperience * 100;

	if experienceData.lastExperienceGain == 0 then
		experienceData.killsTilNextLevel = "INF";
	else
		experienceData.killsTilNextLevel = math.ceil((experienceData.requiredExperience - experienceData.currentExperience) / experienceData.lastExperienceGain);
	end

	experienceData.experiencePerHour = (experienceData.experienceGained * (_G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] / _G["EXPERIENCE_VIEWER"]["elapsedTime"]));

	local experienceRemaining = experienceData.requiredExperience - experienceData.currentExperience;
	local experiencePerSecond = experienceData.experienceGained / _G["EXPERIENCE_VIEWER"]["elapsedTime"];

	experienceData.timeTilLevel = os.date("!%X", experienceRemaining / experiencePerSecond);

	--[[END OF UPDATES, SET PREVIOUS]]
	experienceData.previousCurrentExperience = experienceData.currentExperience;
end

function EXPVIEWER_CALCULATE_TICK()
	_G["EXPERIENCE_VIEWER"]["elapsedTime"] = os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);

	EXPVIEWER_CALCULATE_EXPERIENCE_PER_HOUR(_G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	EXPVIEWER_CALCULATE_EXPERIENCE_PER_HOUR(_G["EXPERIENCE_VIEWER"]["classExperienceData"]);

	EXPVIEWER_CALCULATE_TIME_TIL_LEVEL(_G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	EXPVIEWER_CALCULATE_TIME_TIL_LEVEL(_G["EXPERIENCE_VIEWER"]["classExperienceData"]);

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_CALCULATE_EXPERIENCE_PER_HOUR(experienceData)
	experienceData.experiencePerHour = (experienceData.experienceGained * (_G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] / _G["EXPERIENCE_VIEWER"]["elapsedTime"]));
end

function EXPVIEWER_CALCULATE_TIME_TIL_LEVEL(experienceData)
	local experienceRemaining = experienceData.requiredExperience - experienceData.currentExperience;
	local experiencePerSecond = experienceData.experienceGained / _G["EXPERIENCE_VIEWER"]["elapsedTime"];

	experienceData.timeTilLevel = os.date("!%X", experienceRemaining / experiencePerSecond);
end

function UPDATE_UI(experienceTextName, experienceData)
	if ui ~= nil then
		local expFrame = ui.GetFrame("expviewer");

		if expFrame ~= nil then
			UPDATE_BUTTONS(expFrame);

			--this might be the worst code I've ever written, but who cares? it works!

			--SET EXPERIENCE TEXT
			if experienceTextName == "baseExperience" or experienceTextName == "classExperience" then
				local xPosition = 15;
				local yPosition = 14;

				for i=0,5 do
					local columnKey = "headerTablePositions";
					local richText = expFrame:GetChild("header_"..i);

					richText:Resize(0, 20);

					if i == 0 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}Current / Required",
							_G["EXPERIENCE_VIEWER"]["settings"].showCurrentRequiredExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 1  then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}%",
							_G["EXPERIENCE_VIEWER"]["settings"].showCurrentPercent,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 2 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}Gain",
							_G["EXPERIENCE_VIEWER"]["settings"].showLastGainedExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 3 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}TNL",
							_G["EXPERIENCE_VIEWER"]["settings"].showKillsTilNextLevel,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 4 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}Exp/Hr",
							_G["EXPERIENCE_VIEWER"]["settings"].showExperiencePerHour,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 5 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}ETA",
							_G["EXPERIENCE_VIEWER"]["settings"].showTimeTilLevel,
							xPosition,
							yPosition,
							columnKey
						);
					end
				end
			end

			if experienceTextName == "baseExperience" then
				local xPosition = 15;
				local yPosition = 49;

				for i=0,5 do
					local columnKey = "baseTablePositions";
					local richText = expFrame:GetChild("base_"..i);

					richText:Resize(0, 20);

					if i == 0 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.currentExperience) .." / " .. GetCommaedText(experienceData.requiredExperience),
							_G["EXPERIENCE_VIEWER"]["settings"].showCurrentRequiredExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 1  then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. string.format("%.2f", experienceData.currentPercent) .. "%",
							_G["EXPERIENCE_VIEWER"]["settings"].showCurrentPercent,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 2 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.lastExperienceGain),
							_G["EXPERIENCE_VIEWER"]["settings"].showLastGainedExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 3 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.killsTilNextLevel),
							_G["EXPERIENCE_VIEWER"]["settings"].showKillsTilNextLevel,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 4 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(string.format("%i", experienceData.experiencePerHour)),
							_G["EXPERIENCE_VIEWER"]["settings"].showExperiencePerHour,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 5 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. experienceData.timeTilLevel,
							_G["EXPERIENCE_VIEWER"]["settings"].showTimeTilLevel,
							xPosition,
							yPosition,
							columnKey
						);
					end
				end
			end

			if experienceTextName == "classExperience" then
				local xPosition = 15;
				local yPosition = 74;

				for i=0,5 do
					local columnKey = "classTablePositions";
					local richText = expFrame:GetChild("class_"..i);

					richText:Resize(0, 20);

					if i == 0 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.currentExperience) .." / " .. GetCommaedText(experienceData.requiredExperience),
							_G["EXPERIENCE_VIEWER"]["settings"].showCurrentRequiredExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 1  then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. string.format("%.2f", experienceData.currentPercent) .. "%",
							_G["EXPERIENCE_VIEWER"]["settings"].showCurrentPercent,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 2 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.lastExperienceGain),
							_G["EXPERIENCE_VIEWER"]["settings"].showLastGainedExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 3 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.killsTilNextLevel),
							_G["EXPERIENCE_VIEWER"]["settings"].showKillsTilNextLevel,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 4 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(string.format("%i", experienceData.experiencePerHour)),
							_G["EXPERIENCE_VIEWER"]["settings"].showExperiencePerHour,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 5 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. experienceData.timeTilLevel,
							_G["EXPERIENCE_VIEWER"]["settings"].showTimeTilLevel,
							xPosition,
							yPosition,
							columnKey
						);
					end
				end
			end

			local size = CALCULATE_FRAME_SIZE() + 20; --extra 20 for reset button
			expFrame:Resize(size, 108);
			MOVE_FRAME_TO_SAVED_POSITION();
		end
	end
end

function UPDATE_CELL(i, richTextComponent, label, showField, xPosition, yPosition, columnKey)
	if showField then
		richTextComponent:SetText(label);

		_G["EXPERIENCE_VIEWER"][columnKey][i+1] = richTextComponent:GetWidth();

		richTextComponent:Resize(richTextComponent:GetWidth(), 20);
		richTextComponent:Move(0, 0);
		richTextComponent:SetOffset(xPosition, yPosition);
		richTextComponent:ShowWindow(1);

		xPosition = xPosition + CALCULATE_MAX_COLUMN_WIDTH(i)  + _G["EXPERIENCE_VIEWER"]["padding"];
	else
		_G["EXPERIENCE_VIEWER"][columnKey][i+1] = 0;
		richTextComponent:SetText("");
		richTextComponent:Move(0, 0);
		richTextComponent:SetOffset(xPosition, yPosition);
		richTextComponent:ShowWindow(0);
	end

	return xPosition;
end

function CALCULATE_MAX_COLUMN_WIDTH(tableIndex)
	return math.max(_G["EXPERIENCE_VIEWER"]["headerTablePositions"][tableIndex+1], _G["EXPERIENCE_VIEWER"]["baseTablePositions"][tableIndex+1], _G["EXPERIENCE_VIEWER"]["classTablePositions"][tableIndex+1]);
end

function CALCULATE_FRAME_SIZE()
	local frameWidth = 0;

	for i = 1,6 do
		local max = math.max(_G["EXPERIENCE_VIEWER"]["headerTablePositions"][i], _G["EXPERIENCE_VIEWER"]["baseTablePositions"][i], _G["EXPERIENCE_VIEWER"]["classTablePositions"][i]);
		frameWidth = frameWidth + max + _G["EXPERIENCE_VIEWER"]["padding"];
	end

	frameWidth = frameWidth + (_G["EXPERIENCE_VIEWER"]["padding"] * 2);

	return frameWidth;
end

function UPDATE_BUTTONS(expFrame)
	--MOVE RESET BUTTON TO TOPRIGHT CORNER
	local resetButton = expFrame:GetChild("resetButton");
	if resetButton ~= nil then
		resetButton:Move(0, 0);
		resetButton:SetOffset(expFrame:GetWidth() - 35, 5);
		resetButton:SetText("{@sti7}{s16}R");
		resetButton:Resize(30, 30);
	end

	--MOVE START BUTTON TO TOPLEFT CORNER
	local startButton = expFrame:GetChild("startButton");
	if startButton ~= nil then
		startButton:Move(0, 0);
		startButton:SetOffset(5, 5);
		startButton:SetText("{@sti7}{s16}S");
		startButton:Resize(30, 30);
		startButton:ShowWindow(0);
	end
end

function RESET()
	ui.SysMsg("Resetting experience session!");

	_G["EXPERIENCE_VIEWER"]["startTime"] = os.clock();
	_G["EXPERIENCE_VIEWER"]["elapsedTime"] = 0;
	_G["EXPERIENCE_VIEWER"]["baseExperienceData"]:reset();
	_G["EXPERIENCE_VIEWER"]["classExperienceData"]:reset();

	EXPVIEWER_SAVE_SETTINGS();
end
