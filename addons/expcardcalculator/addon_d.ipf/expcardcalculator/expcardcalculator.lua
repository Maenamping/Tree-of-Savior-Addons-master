local acutil = require("acutil");

local currentClassExperience = 0;

function EXPCARDCALCULATOR_ON_INIT(addon, frame)
	acutil.slashCommand("/cardcalc", EXPCARDCALCULATOR_TOGGLE_FRAME);
	acutil.slashCommand("/expcardcalculator", EXPCARDCALCULATOR_TOGGLE_FRAME);

	addon:RegisterMsg("JOB_EXP_UPDATE", "EXPCARDCALCULATOR_ON_JOB_EXP_UPDATE");
	addon:RegisterMsg("JOB_EXP_ADD", "EXPCARDCALCULATOR_ON_JOB_EXP_UPDATE");

	acutil.setupHook(SYSMENU_CHECK_HIDE_VAR_ICONS_HOOKED, "SYSMENU_CHECK_HIDE_VAR_ICONS");

	local sysmenuFrame = ui.GetFrame("sysmenu");
	SYSMENU_CHECK_HIDE_VAR_ICONS(sysmenuFrame);

	calculateClassRankAndLevel();
end

function EXPCARDCALCULATOR_TOGGLE_FRAME()
	ui.ToggleFrame("expcardcalculator");
end

function EXPCARDCALCULATOR_ON_JOB_EXP_UPDATE(frame, msg, str, exp, tableinfo)
	currentClassExperience = exp - tableinfo.startExp;
end

function string.starts(String,Start)
   return string.sub(String, 1, string.len(Start)) == Start;
end

local function createExperienceRow(index, itemName, numberOfItems, totalExperience, yPosition)
	local expCardCalculatorFrame = ui.GetFrame("expcardcalculator");

	if expCardCalculatorFrame ~= nil then
		local gbox = expCardCalculatorFrame:GetChild("experienceCardGroupBox");

		if gbox ~= nil then
			local cardList = gbox:GetChild("internalExperienceCardGroupBox");

			if cardList ~= nil then
				tolua.cast(cardList, "ui::CGroupBox");

				local cardItem = cardList:CreateOrGetControlSet("status_stat", "expCard_" .. index, -5, yPosition);
				tolua.cast(cardItem, "ui::CControlSet");

				local title = GET_CHILD(cardItem, "title", "ui::CRichText");
				title:SetText(itemName .. " (" .. numberOfItems .. ")");

				local stat = GET_CHILD(cardItem, "stat", "ui::CRichText");
				stat:SetText(GetCommaedText(totalExperience));
				title:SetUseOrifaceRect(true);
				stat:SetUseOrifaceRect(true);

				cardItem:Resize(cardItem:GetWidth(), stat:GetHeight());

				GBOX_AUTO_ALIGN(cardList, 10, 0, 0, true, false);
				expCardCalculatorFrame:Invalidate();

				yPosition = yPosition + cardItem:GetHeight();

				expCardCalculatorFrame:Invalidate();
			end
		end
	end

	return yPosition;
end

local function getClassData()
	local totalClassExperience = 0;
	local classExperienceData = {};
	local classExperienceList, count = GetClassList("Xp_Job");

	for i = 0, count - 1 do
		local jobClass = GetClassByIndexFromList(classExperienceList, i);

		totalClassExperience = totalClassExperience + jobClass.TotalXp;

		classExperienceData[jobClass.ClassName]  = {};
		classExperienceData[jobClass.ClassName]["requiredExperience"] = jobClass.TotalXp;
		classExperienceData[jobClass.ClassName]["totalClassExperience"] = totalClassExperience;
	end

	return classExperienceData, totalClassExperience;
end

local function getExperienceCardTotals()
	local totalBaseExperience = 0;
	local totalClassExperience = 0;
	local yPosition = 10;

	local expCardCalculatorFrame = ui.GetFrame("expcardcalculator");

	if expCardCalculatorFrame ~= nil then
		local gbox = expCardCalculatorFrame:GetChild("experienceCardGroupBox");

		if gbox ~= nil then
			local cardList = gbox:GetChild("internalExperienceCardGroupBox");

			if cardList ~= nil then
				tolua.cast(cardList, "ui::CGroupBox");
				cardList:DeleteAllControl();
			end
		end
	end

	local invItemList = session.GetInvItemList();

	if invItemList ~= nil then
		local index = invItemList:Head();
		local itemCount = session.GetInvItemList():Count();

		for i = 0, itemCount - 1 do
			local invItem = invItemList:Element(index);
			if invItem ~= nil then
				local itemobj = GetIES(invItem:GetObject());

				if itemobj ~= nil then
					if string.starts(itemobj.ClassName, "expCard") then
						local remainInvItemCount = GET_REMAIN_INVITEM_COUNT(invItem);

						local totalBaseCardExperience = 0;

						for i=1,remainInvItemCount do
							totalBaseCardExperience = totalBaseCardExperience + itemobj.NumberArg1;
							totalClassExperience = totalClassExperience + (itemobj.NumberArg1 * 0.77);
						end

						totalBaseExperience = totalBaseExperience + totalBaseCardExperience;

						yPosition = createExperienceRow(i, itemobj.Name, remainInvItemCount, totalBaseCardExperience, yPosition);
					end
				end
			end

			index = invItemList:Next(index);
		end
	end

	return totalBaseExperience, totalClassExperience;
end

local function calculateClassRankAndLevel()
	local classExperienceData = getClassData();

	local int startRank = 1;
	local int startLevel = 1;

	local baseExperienceFromCards, classExperienceFromCards = getExperienceCardTotals();
end

function EXP_CARD_CALCULATOR_OPEN()
	local baseExperienceFromCards, classExperienceFromCards = getExperienceCardTotals();

	local expCardCalculatorFrame = ui.GetFrame("expcardcalculator");

	local totalBaseExperience = 0;
	local yPosition = 10;

	local finalBaseLevel = 0;
	local finalBaseLevelPercent = 0;
	local pc = GetMyPCObject();

	if pc ~= nil then
		local currentLevel = pc.Lv-1;
		local currentBaseExperienceClass = GetClassByType("Xp", currentLevel);
		local currentTotalBaseExperience = session.GetEXP() + currentBaseExperienceClass.TotalXp;
		local finalBaseExperience = currentTotalBaseExperience + totalBaseExperience + baseExperienceFromCards;

		local currentLevelClass = GetClassByType("Xp", currentLevel);
		while finalBaseExperience > currentLevelClass.TotalXp do
			currentLevel = currentLevel + 1;
			currentLevelClass = GetClassByType("Xp", currentLevel);
		end

		finalBaseLevel = currentLevel;

		local previousLevelClass = GetClassByType("Xp", currentLevel-1);
		local requiredBaseExperience = currentLevelClass.TotalXp - previousLevelClass.TotalXp;
		local baseExperienceIntoLevel = finalBaseExperience - previousLevelClass.TotalXp;


		--base level text
		local baseLevelText = expCardCalculatorFrame:CreateOrGetControl("richtext", "baseCardLevel", 30, 70, 200, 50);
		if baseLevelText ~= nil then
			tolua.cast(baseLevelText, "ui::CRichText");
			baseLevelText:SetText("{@st43}Base Card Level: " .. finalBaseLevel .. "{/}");
			baseLevelText:ShowWindow(1);
		end

		local baseExperiencePercent = (baseExperienceIntoLevel / requiredBaseExperience) * 100;

		local baseExperienceGauge = GET_CHILD(expCardCalculatorFrame, "baseExperienceGauge", "ui::CGauge");
		baseExperienceGauge:SetTextTooltip("{@st42b}" .. GetCommaedText(baseExperienceIntoLevel) .. " / " .. GetCommaedText(requiredBaseExperience) .. " (" .. baseExperiencePercent .. "%){/}");
		baseExperienceGauge:SetPoint(baseExperienceIntoLevel, requiredBaseExperience);
		baseExperienceGauge:Resize(expCardCalculatorFrame:GetWidth() - 50, baseExperienceGauge:GetHeight());
		baseExperienceGauge:ShowWindow(1);

		--class level text
		local classLevelText = expCardCalculatorFrame:CreateOrGetControl("richtext", "classCardLevel", 30, 150, 200, 50);
		if classLevelText ~= nil then
			tolua.cast(classLevelText, "ui::CRichText");
			classLevelText:SetText("{@st43}Class Card Level coming next release!{/}");
			classLevelText:ShowWindow(1);
		end

		local classExperiencePercent = (102 / 1000) * 100;

		local classExperienceGauge = GET_CHILD(expCardCalculatorFrame, "classExperienceGauge", "ui::CGauge");
		classExperienceGauge:SetTextTooltip(string.format("{@st42b}%d / %d (%d%%){/}", 102, 1000, classExperiencePercent));
		classExperienceGauge:SetPoint(102, 1000);
		classExperienceGauge:Resize(expCardCalculatorFrame:GetWidth() - 50, classExperienceGauge:GetHeight());
		classExperienceGauge:ShowWindow(1);
	end
end

function EXP_CARD_CALCULATOR_CLOSE()
end

function SYSMENU_CHECK_HIDE_VAR_ICONS_HOOKED(frame)
	if false == VARICON_VISIBLE_STATE_CHANTED(frame, "necronomicon", "necronomicon")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "grimoire", "grimoire")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "guild", "guild")
	and false == VARICON_VISIBLE_STATE_CHANTED(frame, "poisonpot", "poisonpot")
	then
		return;
	end

	DESTROY_CHILD_BY_USERVALUE(frame, "IS_VAR_ICON", "YES");

	local status = frame:GetChild("status");
	local inven = frame:GetChild("inven");
	local offsetX = inven:GetX() - status:GetX();
	local startX = status:GetMargin().left - offsetX;

	startX = SYSMENU_CREATE_VARICON(frame, status, "guild", "guild", "sysmenu_guild", startX, offsetX, "Guild");
	startX = SYSMENU_CREATE_VARICON(frame, status, "necronomicon", "necronomicon", "sysmenu_card", startX, offsetX);
	startX = SYSMENU_CREATE_VARICON(frame, status, "grimoire", "grimoire", "sysmenu_neacro", startX, offsetX);
	startX = SYSMENU_CREATE_VARICON(frame, status, "poisonpot", "poisonpot", "sysmenu_wugushi", startX, offsetX);
	startX = SYSMENU_CREATE_VARICON(frame, status, "expcardcalculator", "expcardcalculator", "addonmenu_expcard", startX, offsetX, "Experience Card Calculator");

	local expcardcalculatorButton = GET_CHILD(frame, "expcardcalculator", "ui::CButton");
	if expcardcalculatorButton ~= nil then
		expcardcalculatorButton:SetTextTooltip("{@st59}Experience Card Calculator");
	end
end
