function ARMORY_SUBMIT_DATA()
	local json = require("json");
	local jsonArmoryData = json.encode(ARMORY_GET_DATA());

	ARMORY_POST_DATA(jsonArmoryData);

	CHAT_SYSTEM("Armory data submitted!");
end

function ARMORY_SAVE_DATA()
	local acutil = require("acutil");

	acutil.saveJSON("C:/armory.json", ARMORY_GET_DATA());

	CHAT_SYSTEM("Armory data saved!");
end

function ARMORY_GET_DATA()
	local armoryData = {};

	local handle = session.GetMyHandle();

	armoryData["name"] = info.GetName(handle) .. " " .. info.GetFamilyName(handle);
	armoryData["level"] = GETMYPCLEVEL();
	armoryData["stats"] = ARMORY_GET_STATS();
	armoryData["equipment"] = ARMORY_GET_EQUIPS();
	armoryData["jobs"] = ARMORY_GET_CLASSES();

	return armoryData;
end

function ARMORY_GET_STATS()
	local stats = {};

	local pc = GetMyPCObject();

	for i=0, STAT_COUNT-1 do
		local typeStr = GetStatTypeStr(i);
		stats[typeStr] = pc[typeStr];
	end

	local stat = info.GetStat(session.GetMyHandle());

	stats["hp"] = stat.maxHP;
	stats["sp"] = stat.maxSP;
	stats["stamina"] = stat.stamina;

	return stats;
end

function ARMORY_GET_EQUIPS()
	local equipment = {};

	local equipItemList = session.GetEquipItemList();

	for i=0, equipItemList:Count()-1 do
		local equipItem = equipItemList:Element(i);
		local spotName = item.GetEquipSpotName(equipItem.equipSpot);

		if spotName ~= nil then
			if equipItem.type ~= item.GetNoneItem(equipItem.equipSpot) then
				local equipItemObj = GetIES(equipItem:GetObject());
				local socketCnt = GET_SOCKET_CNT(equipItemObj);
				local maxcnt = equipItemObj.MaxSocket;
				local reinforce_2 = TryGetProp(equipItemObj, "Reinforce_2");

				local equip = {};
				equip["slot"] = spotName;
				equip["icon"] = equipItemObj.Icon;
				equip["className"] = equipItemObj.ClassName;
				equip["name"] = dictionary.ReplaceDicIDInCompStr(equipItemObj.Name);
				equip["reinforce"] = equipItemObj.Reinforce_2;

				table.insert(equipment, equip);
			end
		end
	end

	return equipment;
end

function ARMORY_GET_CLASSES()
	local classes = {};

	local index = 0;

	local clslist, cnt = GetClassList("Job");

	while true do
		local jobID = session.GetHaveJobIdByIndex(index);

		if jobID == -1 then
			break;
		end

		local cls = GetClassByTypeFromList(clslist, jobID);
		if cls == nil then
			break;
		end

		local classLevel = session.GetJobGrade(jobID);

		local starText = "";

		for i = 1,3 do
			if i <= classLevel then
				starText = starText .. ("{img star_in_arrow 20 20}");
			else
				starText = starText .. ("{img star_out_arrow 20 20}");
			end
		end

		local class = {};

		class["name"] = dictionary.ReplaceDicIDInCompStr(cls.Name);
		class["className"] = cls.ClassName;
		class["icon"] = cls.Icon;
		class["circle"] = classLevel;
		class["skills"] = ARMORY_GET_SKILLS(cls.ClassID);

		table.insert(classes, class);

		index = index + 1;

	end

	return classes;
end

function ARMORY_GET_SKILLS(jobID)
	local skills = {};

	local clslist, cnt  = GetClassList("Job");
	local cls = GetClassByTypeFromList(clslist, jobID);
	local jobName = cls.ClassName;
	local pc = GetMyPCObject();
	local clslist, cnt  = GetClassList("SkillTree");
	local index = 1;

	while true do
		local name = jobName .. "_" ..index;
		local cls = GetClassByNameFromList(clslist, name);
		if cls == nil then
			break;
		end

		if 0 < GET_SKILLTREE_MAXLV(pc, jobName, cls) then
			local skl = session.GetSkillByName(cls.SkillName)
			if skl ~= nil then
				local obj = GetIES(skl:GetObject());

				local skill = {};

				skill["name"] = dictionary.ReplaceDicIDInCompStr(obj.Name);
				skill["className"] = cls.ClassName;
				skill["icon"] = obj.Icon;
				skill["level"] = obj.Level;

				table.insert(skills, skill);
			end
		end

		index = index + 1;
	end

	return skills;
end

function ARMORY_POST_DATA(armoryData)
	local socket = require("socket");

	if socket ~= nil then
		local host = "127.0.0.1";
		local port = 8080;
		local connection = socket.connect(host, port);

		if connection ~= nil then
			connection:send("POST /api/character/submit HTTP/1.1\n");
			connection:send("Content-Type: application/json\n");
			connection:send("Host: " .. host .. "\n");
			connection:send("Content-Length: " .. string.len(armoryData) .. "\n\n");
			connection:send(armoryData);

			local line = connection:receive('*line');
			CHAT_SYSTEM("Status: " .. line);
			connection:close();
		end
	end
end

ARMORY_SUBMIT_DATA();
