local acutil = require("acutil");

function GUILDMATES_ON_INIT(addon, frame)
	acutil.setupHook(POPUP_GUILD_MEMBER_HOOKED, "POPUP_GUILD_MEMBER");
	acutil.setupHook(UPDATE_GUILDINFO_HOOKED, "UPDATE_GUILDINFO");
	acutil.setupHook(OPEN_PARTY_MEMBER_INFO_HOOKED, "OPEN_PARTY_MEMBER_INFO");
	acutil.setupHook(REQUEST_LIKE_STATE_HOOKED, "REQUEST_LIKE_STATE");
end

function POPUP_GUILD_MEMBER_HOOKED(parent, ctrl)
	local aid = parent:GetUserValue("AID");
	if aid == "None" then
		aid = ctrl:GetUserValue("AID");
	end

	local memberInfo = session.party.GetPartyMemberInfoByAID(PARTY_GUILD, aid);
	local isLeader = AM_I_LEADER(PARTY_GUILD);
	local myAid = session.loginInfo.GetAID();

	local name = memberInfo:GetName();

	local contextMenuCtrlName = string.format("{@st41}%s{/}", name);
	local context = ui.CreateContextMenu("PC_CONTEXT_MENU", name, 0, 0, 170, 100);
	if isLeader == 1 and aid ~= myAid then
		ui.AddContextMenuItem(context, ScpArgMsg("ChangeDuty"), string.format("GUILD_CHANGE_DUTY('%s')", name));
		ui.AddContextMenuItem(context, ScpArgMsg("Ban"), string.format("GUILD_BAN('%s')", name));
	end

	if isLeader == 1 then
		local list = session.party.GetPartyMemberList(PARTY_GUILD);
		if list:Count() == 1 then
			ui.AddContextMenuItem(context, ScpArgMsg("Disband"), "ui.Chat('/destroyguild')");
		end
	else
		if aid == myAid then
			ui.AddContextMenuItem(context, ScpArgMsg("GULID_OUT"), "OUT_GUILD()");
		end
	end

	ui.AddContextMenuItem(context, "Character Info", string.format("OPEN_PARTY_MEMBER_INFO('%s')", name));
	ui.AddContextMenuItem(context, ScpArgMsg("PARTY_INVITE"), string.format("PARTY_INVITE(\"%s\")", name));
	ui.AddContextMenuItem(context, ScpArgMsg("ReqAddFriend"), string.format("friends.RequestRegister('%s')", name));
	ui.AddContextMenuItem(context, ScpArgMsg("WHISPER"), string.format("ui.WhisperTo('%s')", name));
	ui.AddContextMenuItem(context, ScpArgMsg("Cancel"), "None");

	ui.OpenContextMenu(context);
end

function UPDATE_GUILDINFO_HOOKED(frame)
	local pcparty = session.party.GetPartyInfo(PARTY_GUILD);
	if pcparty == nil then
		frame:ShowWindow(0);
		return;
	end

	local information = GET_CHILD(frame, "information");
	local properties = GET_CHILD(frame, "properties");

	local isLeader = AM_I_LEADER(PARTY_GUILD);
	local leaderAID = pcparty.info:GetLeaderAID();
	local partyObj = GetIES(pcparty:GetObject());

	local partyname_edit = GET_CHILD_RECURSIVELY(frame, 'partyname_edit')
	local partynote = GET_CHILD_RECURSIVELY(frame, 'partynote')
	local notice_edit = GET_CHILD_RECURSIVELY(frame, 'notice_edit')
	partyname_edit:SetText(pcparty.info.name);
	partynote:SetText(pcparty.info:GetProfile());
	notice_edit:SetText(pcparty.info:GetNotice());

	partyname_edit:EnableHitTest(isLeader);
	partynote:EnableHitTest(isLeader);

	local savememo = GET_CHILD_RECURSIVELY(frame, 'savememo')
	savememo:ShowWindow(isLeader);

	local list = session.party.GetPartyMemberList(PARTY_GUILD);
	local count = list:Count();

	local gbox_member = information:GetChild("gbox_member");
	local gbox_list = gbox_member:GetChild("gbox_list");
	gbox_list:RemoveAllChild();

	local showOnlyConnected = config.GetXMLConfig("Guild_ShowOnlyConnected");

	local connectionCount = 0;
	for i = 0 , count - 1 do
		local partyMemberInfo = list:Element(i);

		if showOnlyConnected == 0 or partyMemberInfo:GetMapID() > 0 then

			local ctrlSet = gbox_list:CreateControlSet("guild_memberinfo", partyMemberInfo:GetAID(), ui.LEFT, ui.TOP, 0, 0, 0, 0);
			ctrlSet:SetUserValue("AID", partyMemberInfo:GetAID());
			local txt_teamname = ctrlSet:GetChild("txt_teamname");
			local txt_duty = ctrlSet:GetChild("txt_duty");
			local txt_location = ctrlSet:GetChild("txt_location");
			txt_teamname:SetTextByKey("value", partyMemberInfo:GetName() .. " (" .. partyMemberInfo:GetLevel() .. ")");
			txt_teamname:SetTextTooltip(partyMemberInfo:GetIconInfo():GetGivenName() .. " " .. partyMemberInfo:GetName() .. "{nl}Level: " .. partyMemberInfo:GetLevel());

			local grade = partyMemberInfo.grade;
			if leaderAID == partyMemberInfo:GetAID() then
				local dutyName = "{ol}{#FFFF00}" .. ScpArgMsg("GuildMaster") .. "{/}{/}";
				dutyName = dutyName .. " " .. pcparty:GetDutyName(grade);
				txt_duty:SetTextByKey("value", dutyName);
			else
				local dutyName = pcparty:GetDutyName(grade);
				txt_duty:SetTextByKey("value", dutyName);
			end

			local pic_online = GET_CHILD(ctrlSet, "pic_online");
			local locationText = "";
			if partyMemberInfo:GetMapID() > 0 then
				local mapCls = GetClassByType("Map", partyMemberInfo:GetMapID());
				if mapCls ~= nil then
					locationText = string.format("[%s%d] %s", ScpArgMsg("Channel"), partyMemberInfo:GetChannel() + 1, mapCls.Name);
					connectionCount = connectionCount + 1;
				end

				pic_online:SetImage("guild_online");
			else
				pic_online:SetImage("guild_offline");
			end

			txt_location:SetTextByKey("value", locationText);
			txt_location:SetTextTooltip(locationText);

			SET_EVENT_SCRIPT_RECURSIVELY(ctrlSet, ui.RBUTTONDOWN, "POPUP_GUILD_MEMBER");
		end
	end

	GBOX_AUTO_ALIGN(gbox_list, 0, 0, 0, true, false);

	local text_memberinfo = gbox_member:GetChild("text_memberinfo");

	local memberStateText = ScpArgMsg("GuildMember{Cur}/{Max}People,OnLine{On}People", "Cur", count, "Max", GUILD_BASIC_MAX_MEMBER + partyObj.AbilLevel_MemberExtend, "On", connectionCount);
	text_memberinfo:SetTextByKey("value", memberStateText);

	local chk_showonlyconnected = GET_CHILD(gbox_member, "chk_showonlyconnected");
	chk_showonlyconnected:SetCheck(showOnlyConnected);

	local chk_agit_enter_onlyguild = GET_CHILD(properties, "chk_agit_enter_onlyguild");
	chk_agit_enter_onlyguild:SetCheck(partyObj.GuildOnlyAgit);

	local existEnemy = GUILD_UPDATE_ENEMY_PARTY(frame, pcparty);
	if existEnemy == 1 then
		frame:RunUpdateScript("UPDATE_REMAIN_GUILD_ENEMY_TIME",20,0,0,1);
	else
		frame:StopUpdateScript("UPDATE_REMAIN_GUILD_ENEMY_TIME");
	end

	GUILD_UPDATE_TOWERINFO(frame, pcparty, partyObj);

	UPDATE_GUILD_EVENT_INFO(frame, pcparty, partyObj);
end

function OPEN_PARTY_MEMBER_INFO_HOOKED(targetName)
	pcCompareFirstPass = true;
	party.ReqMemberDetailInfo(targetName);
end

function REQUEST_LIKE_STATE_HOOKED(familyName)
	if pcCompareFirstPass == true then
		pcCompareFirstPass = false;
		return;
	end

	_G['REQUEST_LIKE_STATE_OLD'](familyName);
end
