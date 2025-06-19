local awful = require("awful")
local naughty = require("naughty")

timers = { 2, 5,10 }
screenshot = os.getenv("HOME") .. "/Images/screenshot/$(date +%F_%T).png"

function scrot_full(path)
    if path == nil then
        new_path = screenshot
        comment = "Screenshot of entire screen"
    else 
        new_path = path
        comment = "Snapshot of entire screen"
    end
    scrot("scrot " .. new_path .. " -e 'xclip -selection c -t image/png < $f'", scrot_callback, comment)
end

function scrot_selection(path)
    if path == nil then
        new_path = screenshot
        comment = "Screenshot of selection"
    else 
        new_path = path
        comment = "Snapshot of selection"
    end
    scrot("sleep 0.5 && scrot -s " .. new_path .. " -e 'xclip -selection c -t image/png < $f'", scrot_callback, comment)
end

function scrot_window(path)
    if path == nil then
        new_path = screenshot
        comment = "Screenshot of window"
    else 
        new_path = path
        comment = "Snapshot of window"
    end
    scrot("scrot -u " .. screenshot .. " -e 'xclip -selection c -t image/png < $f'", scrot_callback, comment)
end

function scrot_delay()
    items={}
    for key, value in ipairs(timers)  do
        items[#items+1]={tostring(value) , "scrot -d ".. value.." " .. screenshot .. " -e 'xclip -selection c -t image/png < $f'","Take a screenshot of delay" }
    end
    awful.menu.new(
    {
        items = items
    }
    ):show({keygrabber= true})
    scrot_callback()
end

function scrot(cmd , callback, args)
    awful.util.spawn_with_shell(cmd)
    callback(args)
end
function scrot_callback(text)
    naughty.notify({
        text = text,
        timeout = 0.5
    })
end
