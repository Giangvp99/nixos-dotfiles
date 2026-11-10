------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

local hostname_file = io.open("/etc/hostname", "r")

if hostname_file then
	local hostname = hostname_file:read("*l")
	hostname_file:close()

	if hostname == "j4n9-proxmox" then
		hl.monitor({
			output = "Virtual-1",
			mode = "1920x1080@60",
			position = "auto",
			scale = 1.2,
		})
	end
end
