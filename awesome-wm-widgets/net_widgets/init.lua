local module_path = (...):match ("(.+/)[^/]+$") or ""

package.loaded.net_widgets = nil

local net_widgets = {
    indicator   = require("awesome-wm-widgets.net_widgets.indicator"),
    wireless    = require("awesome-wm-widgets.net_widgets.wireless")
}

return net_widgets
