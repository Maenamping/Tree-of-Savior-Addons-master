_G["MONSTER_TRACKER"] = {};

_G["MONSTER_TRACKER"]["settings"] = {
	--if this is enabled, the notice will still show up even if goal is reached.
	showNoticeIfComplete = true;
};

function MONSTERTRACKER_ON_INIT(addon, frame)
	addon:RegisterMsg("FPS_UPDATE", "FPS_ON_MSG_HOOKED");
end

local MonsterTrackData = {}
MonsterTrackData.__index = MonsterTrackData

setmetatable(MonsterTrackData, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function MonsterTrackData.new()
	local self = setmetatable({}, MonsterTrackData)

	self.previousKillCount = 0;
	self.killCount = 0;
	self.killsRequired = 0;
	self.needsToShow = false;
	self.isCompleted = false;
	self.isFirstPass = true;

	return self
end

function FPS_ON_MSG_HOOKED(frame, msg, argStr, argNum)
	local result = SCR_GET_ZONE_FACTION_OBJECT(session.GetMapName(), "Monster", "Normal/Material/Elite/Boss", 120000);

	for k,v in pairs(result) do
	    local mobName = v[1];
	    local totalSpawn = v[2];

		local monCls = GetClass("Monster", mobName);
		local wiki = GetWikiByName(monCls.Journal);

		local monsterTrackData = _G["MONSTER_TRACKER"][monCls.ClassID];

		if monsterTrackData == nil then
			monsterTrackData = MonsterTrackData();
		end

		monsterTrackData.killCount = GetWikiIntProp(wiki, "KillCount");
		monsterTrackData.killsRequired = GetClass('Journal_monkill_reward', monCls.Journal).Count1;

		if monsterTrackData.isFirstPass then
			monsterTrackData.previousKillCount = monsterTrackData.killCount;

			if monsterTrackData.killCount >= monsterTrackData.killsRequired then
				monsterTrackData.isCompleted = true;
			end
		end

		if monsterTrackData.killCount ~= monsterTrackData.previousKillCount then
			local killNoticeFrame = ui.GetFrame("monstertracker");
			killNoticeFrame:SetGravity(ui.RIGHT, ui.BOTTOM);

			local monsterImage = GET_CHILD(killNoticeFrame, "monsterImage");
			monsterImage:SetImage(GET_MON_ILLUST(monCls));
			monsterImage:SetGravity(ui.LEFT, ui.TOP);
			monsterImage:Resize(50, 50);
			monsterImage:Move(0, 0);
			monsterImage:SetOffset(0, 0);

			local killNoticeText = killNoticeFrame:GetChild("killNoticeText");
			tolua.cast(killNoticeText, "ui::CRichText");
			killNoticeText:SetText("{@st42}" .. GetCommaedText(monsterTrackData.killCount) .. " / " .. GetCommaedText(monsterTrackData.killsRequired) .. " " .. monCls.Name .. " killed{/}");
			killNoticeText:SetGravity(ui.LEFT, ui.TOP);
			killNoticeText:SetTextAlign("left", "top");
			killNoticeText:Move(0, 0);
			killNoticeText:SetOffset(55, 17);

			if SHOULD_SHOW_NOTICE(monsterTrackData) then
				killNoticeFrame:ShowWindow(1);
				killNoticeFrame:SetDuration(5.0);
				monsterTrackData.needsToShow = false;
			end
		end

		if monsterTrackData.killCount >= monsterTrackData.killsRequired and not monsterTrackData.isFirstPass and not monsterTrackData.isCompleted then
			ui.SysMsg("Congratulations! You've completed the monster kill requirements for " .. monCls.Name .. "! Redeem your reward at Wings of Vibora in town!");
			imcSound.PlaySoundEvent("sys_levelup");
			monsterTrackData.isCompleted = true;
		end

		monsterTrackData.previousKillCount = monsterTrackData.killCount;
		monsterTrackData.isFirstPass = false;

		_G["MONSTER_TRACKER"][monCls.ClassID] = monsterTrackData;
	end
end

function SHOULD_SHOW_NOTICE(monsterTrackData)
	return monsterTrackData.killCount <= monsterTrackData.killsRequired
		and not monsterTrackData.isFirstPass
		or (monsterTrackData.killCount > monsterTrackData.killsRequired and _G["MONSTER_TRACKER"]["settings"].showNoticeIfComplete);
end
