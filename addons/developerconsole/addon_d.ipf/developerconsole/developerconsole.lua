local acutil = require("acutil");

function DEVELOPERCONSOLE_ON_INIT(addon, frame)
	acutil.slashCommand("/dev", DEVELOPERCONSOLE_TOGGLE_FRAME);
	acutil.slashCommand("/console", DEVELOPERCONSOLE_TOGGLE_FRAME);
	acutil.slashCommand("/devconsole", DEVELOPERCONSOLE_TOGGLE_FRAME);
	acutil.slashCommand("/developerconsole", DEVELOPERCONSOLE_TOGGLE_FRAME);

	acutil.setupHook(DEVELOPERCONSOLE_PRINT_TEXT, "print");

	CLEAR_CONSOLE();
end

function DEVELOPERCONSOLE_TOGGLE_FRAME()
	ui.ToggleFrame("developerconsole");
end

function DEVELOPERCONSOLE_OPEN()
	local frame = ui.GetFrame("developerconsole");
	local textViewLog = frame:GetChild("textview_log");
	textViewLog:ShowWindow(1);

	local devconsole = ui.GetFrame("developerconsole");
	devconsole:ShowTitleBar(0);
	--devconsole:ShowTitleBarFrame(1);
	devconsole:ShowWindow(0);
	devconsole:SetSkinName("chat_window");
	devconsole:ShowWindow(1);
	--devconsole:Resize(800, 500);

	local input = devconsole:GetChild("input");
	if input ~= nil then
		input:Move(0, 0);
		input:SetOffset(10, 450);
		--input:ShowWindow(1);
		--input:Resize(675, 40);
		--input:SetGravity(ui.LEFT, ui.CENTER);
	end

	local executeButton = devconsole:GetChild("execute");
	if executeButton ~= nil then
		--executeButton:Resize(100, 40);
		executeButton:SetOffset(690, 450);
		executeButton:SetText("Execute");
	end

	local debugUIButton = devconsole:GetChild("debugUI");
	if debugUIButton ~= nil then
		--debugUIButton:Resize(100, 40);
		debugUIButton:SetOffset(690, 405);
		debugUIButton:SetText("Debug UI");
	end

	local clearButton = devconsole:GetChild("clearConsole");
	if clearButton ~= nil then
		clearButton:Resize(100, 40);
		clearButton:SetOffset(690, 360);
		clearButton:SetText("Clear");
	end

	local textlog = devconsole:GetChild("textview_log");
	if textlog ~= nil then
		--textlog:Resize(675, 435);
		textlog:SetOffset(10, 10);
	end

	devconsole:Invalidate();

	--ui.SysMsg("input: " .. input:GetX() .. " " .. input:GetY() .. " " .. input:GetWidth() .. " " .. input:GetHeight());
	--ui.SysMsg("execute: " .. executeButton:GetX() .. " " .. executeButton:GetY() .. " " .. executeButton:GetWidth() .. " " .. executeButton:GetHeight());
	--ui.SysMsg("debugUI: " .. debugUIButton:GetX() .. " " .. debugUIButton:GetY() .. " " .. debugUIButton:GetWidth() .. " " .. debugUIButton:GetHeight());
	--ui.SysMsg("textlog: " .. textlog:GetX() .. " " .. textlog:GetY() .. " " .. textlog:GetWidth() .. " " .. textlog:GetHeight());
end

function DEVELOPERCONSOLE_CLOSE()
end

function TOGGLE_UI_DEBUG()
	debug.ToggleUIDebug();
end

function CLEAR_CONSOLE()
	local frame = ui.GetFrame("developerconsole");

	if frame ~= nil then
		local textlog = frame:GetChild("textview_log");

		if textlog ~= nil then
			tolua.cast(textlog, "ui::CTextView");
			textlog:Clear();
			textlog:AddText("Developer Console", "white_16_ol");
			textlog:AddText("Enter command and press execute!", "white_16_ol");
		end
	end
end

function DEVELOPERCONSOLE_PRINT_TEXT(text)
	if text == nil or text == "" then
		return;
	end

	local frame = ui.GetFrame("developerconsole");
	local textlog = frame:GetChild("textview_log");

	if textlog ~= nil then
		tolua.cast(textlog, "ui::CTextView");
		textlog:AddText(text, "white_16_ol");
	end
end

function DEVELOPERCONSOLE_ENTER_KEY(frame, control, argStr, argNum)
	local textlog = frame:GetChild("textview_log");

	if textlog ~= nil then
		tolua.cast(textlog, "ui::CTextView");

		local editbox = frame:GetChild("input");

		if editbox ~= nil then
			tolua.cast(editbox, "ui::CEditControl");
			local commandText = editbox:GetText();

			if commandText ~= nil and commandText ~= "" then
				local s = "[Execute] " .. commandText;
				textlog:AddText(s, "white_16_ol");
				local f = assert(loadstring(commandText));
				local status, error = pcall(f);

				if not status then
					textlog:AddText(tostring(error), "white_16_ol");
				end
			end
		end
	end
end
