-- Launch laptop or desktop configuration :
local result = os.execute("acpi")
if result ~= true and result ~= 0 then
    -- No battery : laptop
    require("rc_desktop")
else
    require("rc_laptop")
end

