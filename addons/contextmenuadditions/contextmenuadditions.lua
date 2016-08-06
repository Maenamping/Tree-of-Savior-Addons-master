function REPORT_BLOCK_CLEAR(targetName, block, clear, hideWarning)
	if hideWarning == 1 then
		REPORT_AUTOBOT(targetName);
		if block == 1 then
			friends.RequestBlock(targetName);
		end
		if clear == 1 then
			REMOVE_CHAT_CLUSTERS_BY_SENDER(targetName);
		end
	else
		local msgBoxString = "Report "..targetName.." and Block new messages?"
		local msgBoxScp = string.format("REPORT_BLOCK_CLEAR('%s', %d, %d, 1)", targetName, block, clear)
		if block == 0 then
			msgBoxString = "Report "..targetName.." as a bot user?"
		end
		ui.MsgBox(msgBoxString, msgBoxScp, "None");
	end
end

function CHAT_RBTN_POPUP_HOOKED(frame, chatCtrl)

	local targetName = chatCtrl:GetUserValue("TARGET_NAME");

	if session.world.IsIntegrateServer() == true then
		ui.SysMsg(ScpArgMsg("CantUseThisInIntegrateServer"));
		return;
	end

	if targetName == GETMYFAMILYNAME() then
		return;
	end

	local friendsListType = session.friends.GetFriendListTypeByFamilyName(targetName);

	local groupBoxName = chatCtrl:GetParent():GetName();
	local chatCtrlName = chatCtrl:GetName();

	local context = ui.CreateContextMenu("CONTEXT_CHAT_RBTN", targetName, 0, 0, 170, 100);
	local subContextReport = ui.CreateContextMenu("SUBCONTEXT_REPORT", "", 0, 0, 0, 0);
	local subContextRemove = ui.CreateContextMenu("SUBCONTEXT_REMOVE", "", 0, 0, 0, 0);

	local blockScp = string.format("CHAT_BLOCK_MSG('%s');", targetName);
	local blockAndReportScp = string.format("REPORT_BLOCK_CLEAR('%s', 1, 0);", targetName);
	local blockReportClearScp = string.format("REPORT_BLOCK_CLEAR('%s', 1, 1);", targetName);
	local charInfoScp = string.format("OPEN_PARTY_MEMBER_INFO('%s');", targetName);
	local removeFriendScp = string.format("FRIEND_REMOVE('%s', 'friends list');", targetName);
	local removeBySenderScp = string.format("REMOVE_CHAT_CLUSTERS_BY_SENDER('%s');", targetName);
	local removeMsgScp = string.format("REMOVE_CHAT_CLUSTER('%s', '%s');", chatCtrlName, groupBoxName);
	local reportScp = string.format("REPORT_AUTOBOT_MSGBOX('%s');", targetName);
	local reportAndClearScp = string.format("REPORT_BLOCK_CLEAR('%s', 0, 1);", targetName);
	local reqFriendScp = string.format("friends.RequestRegister('%s');", targetName);
	local reqGuildScp = string.format("GUILD_INVITE('%s');", targetName)
	local reqPartyScp = string.format("PARTY_INVITE('%s');", targetName);
	local unblockScp = string.format("FRIEND_REMOVE('%s', 'block list');", targetName);
	local whisperScp = string.format("ui.WhisperTo('%s');", targetName);

	ui.AddContextMenuItem(subContextRemove, "Clear Sender Messages", removeBySenderScp);


	ui.AddContextMenuItem(context, "Whisper", whisperScp, targetName);
	ui.AddContextMenuItem(context, "Character Info", charInfoScp, targetName);
	ui.AddContextMenuItem(context, "Party Request", reqPartyScp, targetName);

	if AM_I_LEADER(PARTY_GUILD) == 1 then
		ui.AddContextMenuItem(context, ClMsg("GUILD_INVITE"), reqGuildScp, targetName);
	end

	if FRIEND_LIST_COMPLETE == friendsListType then

		ui.AddContextMenuItem(context, "Remove Friend", removeFriendScp);
		ui.AddContextMenuItem(context, "Remove Message {img white_right_arrow 18 18}", removeMsgScp , nil, 0, 1, subContextRemove);
		ui.AddContextMenuItem(context, "Block", blockScp);

	elseif FRIEND_LIST_BLOCKED == friendsListType then
		ui.AddContextMenuItem(subContextReport, "Report Bot & Clear Messages", blockReportClearScp);
		ui.AddContextMenuItem(context, "Remove Message {img white_right_arrow 18 18}", removeMsgScp , nil, 0, 1, subContextRemove);
		ui.AddContextMenuItem(context, "Report Bot {img white_right_arrow 18 18}", 	reportScp, nil, 0, 1, subContextReport);
		ui.AddContextMenuItem(context, "Unblock", removeFriendScp);

	else
		ui.AddContextMenuItem(subContextReport, "Report Bot & Block", blockAndReportScp);
		ui.AddContextMenuItem(subContextReport, "Report Bot, Block &{nl}Clear Sender Messages", blockReportClearScp);
		ui.AddContextMenuItem(context, "Friend Request", friendReqScp);
		ui.AddContextMenuItem(context, "Remove Message {img white_right_arrow 18 18}", removeMsgScp , nil, 0, 1, subContextRemove);
		ui.AddContextMenuItem(context, "Report Bot {img white_right_arrow 18 18}", reportScp, nil, 0, 1, subContextReport);
		ui.AddContextMenuItem(context, "Block", blockScp);
	end

	subContextReport:Resize(200, subContextReport:GetHeight());
	context:Resize(175, context:GetHeight());

	ui.AddContextMenuItem(context, "Cancel", "None");
	ui.OpenContextMenu(context);

end

function FRIEND_REMOVE(targetName, listname)
	local friendsListType = session.friends.GetFriendListTypeByFamilyName(targetName);
	local cnt = session.friends.GetFriendCount(friendsListType);

	for i = 0 , cnt - 1 do
		local f = session.friends.GetFriendByIndex(friendsListType, i);
		if targetName == f:GetInfo():GetFamilyName() then
			local msgBoxString = string.format("Do you want to remove %s from your %s?", targetName, listname);
			local unblockScp = string.format("friends.RequestDelete('%s')", f:GetInfo():GetACCID());
			ui.MsgBox(msgBoxString, unblockScp, "None");
			return;
		end
	end
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

function SHOW_PC_CONTEXT_MENU_HOOKED(handle)

	local pcObj = world.GetActor(handle);
	local targetName = pcObj:GetPCApc():GetFamilyName();

	if world.IsPVPMap() == true then
		return;
	end

	if pcObj == nil then
		return;
	end

	if pcObj:IsMyPC() == 0 and info.IsPC(handle) == 1 then

		local friendsListType = session.friends.GetFriendListTypeByFamilyName(targetName);

		local context = ui.CreateContextMenu("PC_CONTEXT_MENU", targetName, 0, 0, 170, 100);
		local subContextReport = ui.CreateContextMenu("SUBCONTEXT_REPORT", "", 0, 0, 0, 0);

		local blockScp = string.format("CHAT_BLOCK_MSG('%s');", targetName);
		local blockAndReportScp = string.format("REPORT_BLOCK_CLEAR('%s', 1, 0);", targetName);
		local charInfoScp = string.format("PROPERTY_COMPARE(%d);", handle)
		local removeFriendScp = string.format("FRIEND_REMOVE('%s', 'friends list');", targetName);
		local reportScp = string.format("REPORT_AUTOBOT_MSGBOX('%s');", targetName);
		local reqDuelScp = string.format("REQUEST_FIGHT(\"%d\");", handle);
		local reqFriendScp = string.format("friends.RequestRegister('%s');", targetName);
		local reqGuildScp = string.format("GUILD_INVITE('%s');", targetName)
		local reqPartyScp = string.format("PARTY_INVITE('%s');", targetName);
		local toggleLikeScp = string.format("SEND_PC_INFO(%d);", handle);
		local tradeScp = string.format("exchange.RequestChange(%d)", handle)
		local unblockScp = string.format("FRIEND_REMOVE('%s', 'block list');", targetName);
		local visitLodgeScp = string.format("barrackNormal.Visit(%d);", handle);
		local whisperScp = string.format("ui.WhisperTo('%s');", targetName);

		ui.AddContextMenuItem(context, "Trade", tradeScp);

		if session.world.IsIntegrateServer() == false then

			ui.AddContextMenuItem(context, "Whisper", whisperScp);
		end
		
		ui.AddContextMenuItem(context, "Character Info", charInfoScp);
		
		if session.world.IsIntegrateServer() == false then
			ui.AddContextMenuItem(context, "Party Request", reqPartyScp);

			if FRIEND_LIST_COMPLETE == friendsListType then
				ui.AddContextMenuItem(context, "Remove Friend", removeFriendScp);
			else
				ui.AddContextMenuItem(context, "Friend Request", reqFriendScp);
			end

			if AM_I_LEADER(PARTY_GUILD) == 1 then
				ui.AddContextMenuItem(context, ClMsg("GUILD_INVITE"), reqGuildScp);
			end

			ui.AddContextMenuItem(context, "Visit Lodge", visitLodgeScp);

		end

		ui.AddContextMenuItem(context, "Friendly Duel Request", reqDuelScp);

		if FRIEND_LIST_BLOCKED == friendsListType then
			ui.AddContextMenuItem(context, "Report Bot", reportScp);
			ui.AddContextMenuItem(context, "Unblock", unblockScp);
		else
			ui.AddContextMenuItem(subContextReport, "Report Bot & Block", blockAndReportScp);
			ui.AddContextMenuItem(context, "Report Bot {img white_right_arrow 18 18}", reportScp, nil, 0, 1, subContextReport);
			ui.AddContextMenuItem(context, "Block", blockScp);
		end

		if session.world.IsIntegrateServer() == false then
			if session.likeit.AmILikeYou(targetName) == true then
				ui.AddContextMenuItem(context, "Cancel Like", toggleLikeScp);
			else
				ui.AddContextMenuItem(context, "Like!", toggleLikeScp);
			end
		end

		ui.AddContextMenuItem(context, "Cancel", "None");
		ui.OpenContextMenu(context);
		context:Resize(200, context:GetHeight());
		return context;

	end
end

function REMOVE_CHAT_CLUSTERS_BY_SENDER(targetName)
	local chatFrame = ui.GetFrame("chatframe");
	if chatFrame == nil then
		return;
	end
	local count = chatFrame:GetChildCount();
	for  i = 0, count-1 do
		local groupBox  = chatFrame:GetChildByIndex(i);
		local childName = groupBox:GetName();
		if string.sub(childName, 1, 5) == "chatg" then
			if groupBox:GetClassName() == "groupbox" then
				groupBox = tolua.cast(groupBox, "ui::CGroupBox");
				local ctrlSetCount = groupBox:GetChildCount();
				for j = 0 , ctrlSetCount - 1 do
					local chatCtrl = groupBox:GetChildByIndex(j);
					if removedClusterNames[chatCtrl:GetName()] ~= true then
						local nameText = GET_CHILD(chatCtrl, "name", "ui::CRichText");
						if nameText ~= nil then
							if nameText:GetText() == '{@st61}'..targetName..'{/}' then
								removedClusterNames[chatCtrl:GetName()] = true;
								chatCtrl:Resize(0, 0);
								chatCtrl:ShowWindow(0);
							end
						end
					end
				end
				GBOX_AUTO_ALIGN(groupBox, 0, 0, 0, true, false);
				groupBox:UpdateData();
			end
		end
	end
	chatFrame:Invalidate();
end

function REMOVE_CHAT_CLUSTER(clusterName, groupBoxName)
	removedClusterNames[clusterName] = true;
	local chatFrame = ui.GetFrame("chatframe");
	if chatFrame == nil then
		return;
	end
	local groupBox = GET_CHILD(chatFrame, groupBoxName, "ui::CGroupBox");
	local chatCtrl = GET_CHILD(groupBox, clusterName);

	chatCtrl:Resize(0, 0);
	chatCtrl:ShowWindow(0);
	GBOX_AUTO_ALIGN(groupBox, 0, 0, 0, true, false);
	groupBox:UpdateData();

	chatFrame:Invalidate();
end

function RESIZE_CHAT_CTRL_HOOKED(chatCtrl, label, txt, timeBox)
	if removedClusterNames[chatCtrl:GetName()] == true then
		local groupBox = chatCtrl:GetParent();
		chatCtrl:Resize(0, 0);
		chatCtrl:ShowWindow(0);
		GBOX_AUTO_ALIGN(groupBox, 0, 0, 0, true, false);
		groupBox:UpdateData();
		return;
	end
	_G['RESIZE_CHAT_CTRL_OLD'](chatCtrl, label, txt, timeBox);
end

if not removedClusterNames then
	removedClusterNames = {};
end

SETUP_HOOK(RESIZE_CHAT_CTRL_HOOKED, "RESIZE_CHAT_CTRL");
SETUP_HOOK(SHOW_PC_CONTEXT_MENU_HOOKED, "SHOW_PC_CONTEXT_MENU");
SETUP_HOOK(CHAT_RBTN_POPUP_HOOKED, "CHAT_RBTN_POPUP");
SETUP_HOOK(OPEN_PARTY_MEMBER_INFO_HOOKED, "OPEN_PARTY_MEMBER_INFO");
SETUP_HOOK(REQUEST_LIKE_STATE_HOOKED, "REQUEST_LIKE_STATE");

ui.SysMsg("Context menu additions loaded!");
