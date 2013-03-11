
--mixer_lab = widget({ type = "textbox" })
--mixer_lab.text = "Volume :"
--mixer_bar = awful.widget.progressbar({ width = 50})
--mixer_bar:set_value(0.7)
--mixer_bar:set_background_color(theme.bg_minimize)
--mixer_bar:set_color(theme.bg_focus)
--mixer = {mixer_lab,
--    mixer_bar}

local mixer_notifier = nil

function update_mixer()
  local file,infile,a,b,v, cmd
--  cmd = "amixer get Master" --LoL
  cmd = "amixer"
  cmd = string.format(curCommand, cmd)
  file = io.popen(cmd)
  
  out = ""
  infile = file:read()
  while infile do
    _,_,vol,state = string.find(infile,'%[(%d+)%%%].* %[(%w+)%]')
    if state == 'on' then
       out = out .. '<span color="green">' .. vol .. '</span> '
    elseif state == 'off' then
       out = out .. '<span color="red">' .. vol .. '</span> '
    end
    infile = file:read()
  end
  
  file:close()
  --mixer_bar:set_value(v/100)
  --return (v/100)
  mixer_notifier = naughty.notify({ text = 'Sound: ' .. out, 
    replaces_id = mixer_notifier}).id;
end


-- SSH tunnel listings pour controle audio
curCommand = '%s'
function ssh_audio_control()
    local file, line, out, login, host, port, menu, controlPath, command
    menu = {}
    controlPath = '~/.ssh/'
    function add_bind(command, label)
        if curCommand == nil then
            curCommand = command
        end
        callback = function ()
            --naughty.notify(
            --    { text = 'Connect to ' .. label .. ' cmd='.. command} )
            curCommand = command
            --prout here
        end
        if curCommand == command then
            label = '>>'..label ..'<<<'
        end
        table.insert(menu,{label, callback})
    end
    add_bind('%s', 'Local')
    file = io.popen("ls " .. controlPath)
    line = file:read()
    while line do
        -- Adapt here to match to your configuration
        _,_,login,host,port = string.find(line,"^master%-(%w+)-([%w%-%.]+):(%d+)$")
        if host then
            command = 'ssh ' .. login .. '@' .. host .. ' -p ' .. port ..
                          ' -o ControlMaster=no -o ControlPath=' ..
                         controlPath .. line .. ' "%s"'
            add_bind(command, host)
        end
        line = file:read()
    end
    file:close()
    return menu
end
