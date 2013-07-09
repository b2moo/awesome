-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

vicious = require("vicious")
-- Initialize widget
memwidget = widget({ type = "textbox" })
-- Register widget
vicious.register(memwidget, vicious.widgets.mem, "$1% ($2MB/$3MB)", 13)


-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

require("mixer")
-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = "vim"--os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

function media_control(cmd)
   cmd = string.format(curCommand,cmd)
   os.execute(cmd)
end


-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
--    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.floating
--    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

--mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
--                                    { "Debian", debian.menu.Debian_menu.Debian },
--                                    { "open terminal", terminal }
--                                  }
--                        })

--
--mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
--                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Test
mytextbox = widget({ type="textbox"})
function hook_battery ()
  local file, infile, status, p, span
  file = io.popen("acpi -V")
  infile = file:read("*all")
  file:close()

  _,_,status = string.find(infile, '^Battery 0: ([^\n]*)\n')
  _,_,p = string.find(status,'(%d+)%%')
  p = tonumber(p)

  if p > 50 then
    span = '<span color="green">'
  elseif p > 15 then
    span = '<span color="orange">'
  else
    span = '<span color="red">'
  end
  mytextbox.text =  " " .. span .. status .. "</span> "
end

-- SSH tunnel listings
local ssh_files_not = nil
function ssh_files()
    local file, line, out, login, host
    file = io.popen("ls ~/.ssh/")
    out = "Connexions distantes: "
    line = file:read()
    while line do
        -- Adapt here to match to your configuration
        _,_,login,host = string.find(line,"^master%-(%w+)-([%w%-%.]+:%d+)$")
        if host then
            out = out .. '<br><span color="green">' .. login .. '</span>@<span color="blue">'
                      .. host .. '</span>'
        end
        line = file:read()
    end
    file:close()
    ssh_files_not = naughty.notify(
        { text = out,
          replaces_id = ssh_files_not} ).id
end


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev),
                    awful.button({ }, 9, function () media_control("amixer set Master 5%+"); update_mixer() end),
                    awful.button({ }, 8, function () media_control("amixer set Master 5%-"); update_mixer() end)
                    )


mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function (c)
                                local items
                                if menu_soft then
                                    menu_soft:hide()
                                    menu_soft = nil
                                else
                                    items = { {"Fermer fenêtre",function () c:kill() end},
                                                               {"Fenêtres",function () menu_soft:hide();
                                                                        menu_soft = awful.menu.clients({width=250}) end},
                                                                  {"Awesome",myawesomemenu,beautiful.awesomeicon},
                                                                  {"Contrôle audio", ssh_audio_control() },
                                                                  {"Retour",function () menu_soft:hide(); menu_soft=nil end}
                                             }
                                    menu_soft = awful.menu({width=300,items=items})
                                    menu_soft:show()
                                end
                                end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    -- Ceci est la wibox de gauche
    mywibox[s].widgets = {
        {
            --mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mixer,
        mytextbox,
        mytextclock,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    --awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}


-- {{{ Key bindings
globalkeys = awful.util.table.join(
--    awful.key({ modkey, "Control" }, "v",   awful.tag.viewprev       ),
--    awful.key({ modkey, "Control" }, "l",  awful.tag.viewnext       ),
    awful.key({ modkey,         }, "Escape", awful.tag.history.restore),
    awful.key({ modkey }, "F12", function () awful.util.spawn("i3lock -d") end),
    awful.key({ modkey, }, "#52" ,  ssh_files),
    awful.key({    }, "XF86AudioRaiseVolume" ,  function () media_control("amixer set Master 5%+"); update_mixer() end),
    awful.key({  }, "XF86AudioLowerVolume" ,  function () media_control("amixer set Master 5%-"); update_mixer() end),
    awful.key({  }, "XF86AudioMute" ,  function () media_control("amixer set Master toggle"); update_mixer() end),
    --awful.key({  }, "#107", function () os.command("/home/dstan/bin/screenshot &"); end),
    --awful.key({  }, "XF86Display" ,  function () media_control("xset dpms force off"); end),

    --Déplacement
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Shift" }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
--    awful.key({ modkey, "Shift", "Control"   }, "v", function () awful.client.swap.byidx(  1)    end),
--    awful.key({ modkey, "Shift", "Control"   }, "l", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "v", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "l", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "b", awful.client.urgent.jumpto),
--    awful.key({ modkey,           }, "Tab",
--        function ()
--            awful.client.focus.history.previous()
--            if client.focus then
--                client.focus:raise()
--            end
--        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    --awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({  }, "XF86_Phone" ,  function () naughty.notify(
                    {title = "Écouteurs",
                    text = "branchés", timeout = 10}) end),
    awful.key({  }, "XF86_HomePage" ,  function ()
                awful.util.spawn("/home/dstan/bin/spotify_ctl pause")
                naughty.notify(
                    {title = "Écouteurs",
                    text = "débranchés (musique en pause)", timeout = 10})
                end),
    awful.key({ modkey, }, "d" ,  function () awful.tag.setmwfact(0.752929)end),
    awful.key({ modkey, "Shift"}, "d" ,  function () awful.tag.setmwfact(0.752929)end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey, "Shift"   }, "v",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey,    }, "v",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey,    }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Shift" }, "-",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Shift" }, "s",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey, }, "y", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, }, "c", function () hook_battery() end),
--    awful.key({ modkey, "Shift"   }, "b", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "p",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "a",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,           }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey,           }, "e", function (c) c:swap(awful.client.getmaster()) end),
    --awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
--    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
--    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "i",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "u",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
histTab = {}
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen, ni, n
                        ni = i
                        if tags[screen][ni] then
                            if histTab[screen] == nil then
                                histTab[screen] = {}
                            end
                            n = table.getn(histTab[screen])
                            if histTab[screen][n] == ni and n > 1 then
                                table.remove(histTab[screen])
                                ni = table.remove(histTab[screen])
                            end
                            table.insert(histTab[screen],ni)
                            awful.tag.viewonly(tags[screen][ni])
--                            dump = ''
--                            n = table.getn(histTab[screen])
--                            for k = 1,n do
--                                dump = dump .. ' ' .. histTab[screen][k]
--                            end
--                            naughty.notify({ text = dump })
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)


battery = timer({ timeout = 60 })
battery:add_signal("timeout",hook_battery)
battery:start()
hook_battery()



-- }}}


