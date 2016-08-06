function ZOOMY_ON_INIT(addon, frame)
	frame:ShowWindow(1);
	frame:RunUpdateScript("ZOOMY_UPDATE", 0, 0, 0, 1);
end

local ZOOM_AMOUNT = 30;
local MINIMUM_ZOOM = 50;
local MAXIMUM_ZOOM = 1500;

local currentZoom = 100;

function ZOOMY_IN()
	currentZoom = currentZoom - ZOOM_AMOUNT;

	ZOOMY_CLAMP();

	camera.CustomZoom(currentZoom);
end

function ZOOMY_OUT()
	currentZoom = currentZoom + ZOOM_AMOUNT;

	ZOOMY_CLAMP();

	camera.CustomZoom(currentZoom);
end

function ZOOMY_CLAMP()
	if currentZoom < MINIMUM_ZOOM then
		currentZoom = MINIMUM_ZOOM;
	elseif currentZoom > MAXIMUM_ZOOM then
		currentZoom = MAXIMUM_ZOOM;
	end
end

function ZOOMY_UPDATE(frame)
	if keyboard.IsKeyPressed("LALT") == 1 then
		if keyboard.IsKeyPressed("MINUS") == 1 then
			ZOOMY_OUT();
		elseif keyboard.IsKeyPressed("EQUALS") == 1 then
			ZOOMY_IN();
		end
	end

	return 1;
end
