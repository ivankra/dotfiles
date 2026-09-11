-- Right-click context menu for mpv 0.41 (uses the built-in context_menu.lua).

-- Basic menu:
-- mp.set_property_native("menu-data", {
--     {title = "Playlist…", cmd = "script-binding select/select-playlist"},
--     {title = "Subtitles…", cmd = "script-binding select/select-sid"},
--     {title = "Audio track…", cmd = "script-binding select/select-aid"},
--     {title = "Chapters…", cmd = "script-binding select/select-chapter"},
--     {type = "submenu", title = "Speed", submenu = {
--         {title = "0.5x", cmd = "set speed 0.5"},
--         {title = "1x", cmd = "set speed 1"},
--         {title = "1.25x", cmd = "set speed 1.25"},
--         {title = "1.5x", cmd = "set speed 1.5"},
--         {title = "2x", cmd = "set speed 2"},
--     }},
-- })

local MAX_LIST_ITEMS = 20
local MAX_TITLE_CHARS = 60
local SEPARATOR = { type = "separator" }

local function get(name, default)
    local value = mp.get_property_native(name)
    if value == nil then return default end
    return value
end

local function item(title, cmd, shortcut, flags)
    local entry = { title = title, cmd = cmd, shortcut = shortcut }
    flags = flags or {}
    local state = {}
    if flags.checked then state[#state + 1] = "checked" end
    if flags.disabled then state[#state + 1] = "disabled" end
    if flags.hidden then state[#state + 1] = "hidden" end
    if #state > 0 then entry.state = state end
    return entry
end

local function submenu(title, items, flags)
    local entry = item(title, nil, nil, flags)
    entry.type = "submenu"
    entry.submenu = items
    if #items == 0 then
        entry.state = entry.state or {}
        table.insert(entry.state, "disabled")
    end
    return entry
end

local function round(x)
    return math.floor(x + 0.5)
end

local function trim_number(x)
    return (string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", ""))
end

local function approx(a, b)
    return a and b and math.abs(a - b) < 0.001
end

local function truncate(text)
    local count, result = 0, {}
    for char in text:gmatch("[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > MAX_TITLE_CHARS then
            return table.concat(result) .. "…"
        end
        result[count] = char
    end
    return text
end

local function delay_title(delay)
    if delay == 0 then return "Reset delay" end
    return string.format("Reset delay (%+d ms)", round(delay * 1000))
end

local function format_time(seconds)
    seconds = math.floor(seconds or 0)
    local h, m, s = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function window(count, current)
    local first = math.max(1, current - math.floor(MAX_LIST_ITEMS / 2))
    local last = math.min(count, first + MAX_LIST_ITEMS - 1)
    first = math.max(1, last - MAX_LIST_ITEMS + 1)
    return first, last
end

local function track_name(track)
    local name = track.title or track.lang or ("Track " .. track.id)
    if track.title and track.lang then
        name = name .. " [" .. track.lang .. "]"
    end
    local details = {}
    if track.codec then details[#details + 1] = track.codec end
    if track["demux-channel-count"] then
        details[#details + 1] = track["demux-channel-count"] .. "ch"
    end
    if track["demux-h"] then details[#details + 1] = track["demux-h"] .. "p" end
    if track.forced then details[#details + 1] = "forced" end
    if track.external then details[#details + 1] = "external" end
    if #details > 0 then
        name = name .. "  (" .. table.concat(details, ", ") .. ")"
    end
    return truncate(name)
end

local function track_items(track_type, property)
    local items = {}
    local selected = mp.get_property_number(property)
    for _, track in ipairs(get("track-list", {})) do
        if track.type == track_type and not track.albumart then
            items[#items + 1] = item(track_name(track),
                string.format("set %s %d", property, track.id), nil,
                { checked = track.id == selected })
        end
    end
    return items, selected
end

local function playlist_menu()
    local playlist = get("playlist", {})
    local items = {}
    local current = get("playlist-pos", 0) + 1
    local first, last = window(#playlist, current)

    if first > 1 then
        items[#items + 1] = item("All " .. #playlist .. " entries…",
            "script-binding select/select-playlist", "g-p")
        items[#items + 1] = SEPARATOR
    end
    for i = first, last do
        local entry = playlist[i]
        local name = entry.title or entry.filename:match("[^/\\]+$") or entry.filename
        items[#items + 1] = item(truncate(name), "playlist-play-index " .. (i - 1),
            nil, { checked = entry.current })
    end
    if last < #playlist then
        items[#items + 1] = SEPARATOR
        items[#items + 1] = item("All " .. #playlist .. " entries…",
            "script-binding select/select-playlist", "g-p")
    end
    if #playlist > 1 then
        items[#items + 1] = SEPARATOR
        items[#items + 1] = item("Previous", "playlist-prev", "<")
        items[#items + 1] = item("Next", "playlist-next", ">")
        items[#items + 1] = item("Shuffle", "playlist-shuffle")
    end
    return submenu("Playlist", items, { hidden = #playlist == 0 })
end

local function chapters_menu()
    local chapters = get("chapter-list", {})
    local items = {}
    local current = get("chapter", -1) + 1
    local first, last = window(#chapters, math.max(current, 1))

    for i = first, last do
        local chapter = chapters[i]
        local title = chapter.title
        if not title or title == "" then title = "Chapter " .. i end
        items[#items + 1] = item(truncate(title), "set chapter " .. (i - 1),
            format_time(chapter.time), { checked = i == current })
    end
    if first > 1 or last < #chapters then
        items[#items + 1] = SEPARATOR
        items[#items + 1] = item("All chapters…", "script-binding select/select-chapter", "g-c")
    end
    return submenu("Chapters", items, { hidden = #chapters == 0 })
end

local function video_menu()
    local items = track_items("video", "vid")
    local aspect = mp.get_property_number("video-aspect-override", -1)
    local rotate = mp.get_property_number("video-rotate", 0)
    local scale = mp.get_property_number("current-window-scale")
    local hwdec = mp.get_property("hwdec-current", "no")

    local function aspect_item(title, value, number)
        return item(title, "set video-aspect-override " .. value, nil,
            { checked = number and approx(aspect, number) or (not number and aspect <= 0) })
    end
    local function rotate_item(degrees)
        return item(degrees .. "°", "set video-rotate " .. degrees, nil,
            { checked = rotate == degrees })
    end
    local function scale_item(title, value, shortcut)
        return item(title, "set window-scale " .. value, shortcut,
            { checked = approx(scale, value) })
    end

    if #items > 0 then items[#items + 1] = SEPARATOR end
    for _, entry in ipairs({
        item("Fullscreen", "cycle fullscreen", "f", { checked = get("fullscreen", false) }),
        item("Always on top", "cycle ontop", "T", { checked = get("ontop", false) }),
        submenu("Window size", {
            scale_item("50%", 0.5, "Alt+0"),
            scale_item("100%", 1, "Alt+1"),
            scale_item("200%", 2, "Alt+2"),
        }),
        submenu("Aspect ratio", {
            aspect_item("Original", "no"),
            aspect_item("16:9", "16:9", 16 / 9),
            aspect_item("4:3", "4:3", 4 / 3),
            aspect_item("2.35:1", "2.35:1", 2.35),
        }),
        submenu("Rotate", { rotate_item(0), rotate_item(90), rotate_item(180), rotate_item(270) }),
        submenu("Zoom", {
            item("Zoom in", "add video-zoom 0.1", "Alt++"),
            item("Zoom out", "add video-zoom -0.1", "Alt+-"),
            item("Reset zoom and pan", "set video-zoom 0; no-osd set panscan 0; no-osd set video-pan-x 0; no-osd set video-pan-y 0", "Alt+BS"),
        }),
        item("Hardware decoding", 'cycle-values hwdec "auto" "no"', "Ctrl+h",
            { checked = hwdec ~= "no" and hwdec ~= "" }),
        item("Deinterlace", "cycle deinterlace", "d",
            { checked = mp.get_property("deinterlace") == "yes" }),
        item("Deband", "cycle deband", "b", { checked = get("deband", false) }),
        submenu("Screenshot", {
            item("With subtitles", "screenshot", "s"),
            item("Without subtitles", "screenshot video", "S"),
            item("Whole window", "screenshot window", "Ctrl+s"),
        }),
    }) do
        items[#items + 1] = entry
    end
    return submenu("Video", items)
end

local function audio_menu()
    local items = track_items("audio", "aid")
    local delay = mp.get_property_number("audio-delay", 0)

    if #items > 0 then items[#items + 1] = SEPARATOR end
    for _, entry in ipairs({
        item("Mute", "cycle mute", "m", { checked = get("mute", false) }),
        item("Volume up", "add volume 2", "0"),
        item("Volume down", "add volume -2", "9"),
        item("Delay +100 ms", "add audio-delay 0.1", "Ctrl++"),
        item("Delay −100 ms", "add audio-delay -0.1", "Ctrl+-"),
        item(delay_title(delay), "set audio-delay 0", nil, { disabled = delay == 0 }),
        item("Output device…", "script-binding select/select-audio-device", "g-d"),
    }) do
        items[#items + 1] = entry
    end
    return submenu("Audio", items)
end

local function subtitles_menu()
    local tracks, selected = track_items("sub", "sid")
    local has_subs = #tracks > 0
    local delay = mp.get_property_number("sub-delay", 0)
    local no_subs = { disabled = not has_subs }

    local items = {}
    if has_subs then
        items[1] = item("Off", "set sid no", nil, { checked = not selected })
        for _, entry in ipairs(tracks) do items[#items + 1] = entry end
        items[#items + 1] = SEPARATOR
    end
    for _, entry in ipairs({
        item("Show subtitles", "cycle sub-visibility", "v",
            { checked = get("sub-visibility", true), disabled = not has_subs }),
        item("Secondary subtitles…", "script-binding select/select-secondary-sid", "g-S", no_subs),
        item("Jump to line…", "script-binding select/select-subtitle-line", "g-l", no_subs),
        item("Delay +100 ms", "add sub-delay 0.1", "Z", no_subs),
        item("Delay −100 ms", "add sub-delay -0.1", "z", no_subs),
        item(delay_title(delay), "set sub-delay 0", nil, { disabled = delay == 0 }),
        item("Bigger", "add sub-scale 0.1", "G", no_subs),
        item("Smaller", "add sub-scale -0.1", "F", no_subs),
        item("Move up", "add sub-pos -1", "r", no_subs),
        item("Move down", "add sub-pos 1", "R", no_subs),
    }) do
        items[#items + 1] = entry
    end
    return submenu("Subtitles", items)
end

local function playback_menu()
    local speed = mp.get_property_number("speed", 1)
    local speeds = {}
    for _, value in ipairs({ 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 3 }) do
        speeds[#speeds + 1] = item(trim_number(value) .. "×", "set speed " .. value,
            value == 1 and "BS" or nil, { checked = approx(speed, value) })
    end

    local a, b = mp.get_property("ab-loop-a", "no"), mp.get_property("ab-loop-b", "no")
    local ab_title = "Set loop start (A)"
    if a ~= "no" and b == "no" then ab_title = "Set loop end (B)" end
    if a ~= "no" and b ~= "no" then ab_title = "Clear A-B loop" end

    return submenu("Playback", {
        submenu("Speed (" .. trim_number(speed) .. "×)", speeds),
        item("Loop file", 'cycle-values loop-file "inf" "no"', "L",
            { checked = mp.get_property("loop-file") == "inf" }),
        item("Loop playlist", 'cycle-values loop-playlist "inf" "no"', nil,
            { checked = mp.get_property("loop-playlist") == "inf" }),
        item(ab_title, "ab-loop", "l", { checked = a ~= "no" and b ~= "no" }),
        item("Next frame", "frame-step", "."),
        item("Previous frame", "frame-back-step", ","),
        item("Undo last seek", "revert-seek", "Shift+BS"),
    })
end

local function tools_menu()
    return submenu("Tools", {
        item("Media info and stats", "script-binding stats/display-stats-toggle", "I"),
        item("Key bindings…", "script-binding select/select-binding", "g-b"),
        item("Properties…", "script-binding select/show-properties", "g-r"),
        item("Console", "script-binding commands/open", "`"),
    })
end

local function build_menu()
    local idle = get("idle-active", false)
    local paused = get("pause", false)
    local not_playing = { disabled = idle }

    local menu = {
        playlist_menu(),
        chapters_menu(),
        video_menu(),
        audio_menu(),
        subtitles_menu(),
        playback_menu(),
        tools_menu(),
        item("Quit and remember position", "quit-watch-later", "Q", not_playing),
        item("Quit", "quit", "q"),
    }
    return menu
end

local function open()
    mp.set_property_native("menu-data", build_menu())
    mp.commandv("script-message-to", "context_menu", "open")
end

mp.add_key_binding("MBTN_RIGHT", "open", open)
mp.add_key_binding("MENU", "open-menu-key", open)
