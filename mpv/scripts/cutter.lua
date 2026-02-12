-- cutter.lua: [ marks IN, ] marks OUT and exports with ffmpeg
local utils = require 'mp.utils'

local in_t = nil

local function msg(s) mp.osd_message(s, 2) end

local function cur_time()
    return mp.get_property_number("time-pos")
end

local function path_basename(p)
    -- crude basename without directories
    return (p:gsub(".*[/\\]", ""))
end

local function strip_ext(fn)
    return (fn:gsub("%.[^%.]+$", ""))
end

local function export_segment(out_t)
    local inpos = in_t
    if not inpos or not out_t then
        msg("Need IN and OUT")
        return
    end
    if out_t <= inpos then
        msg("OUT must be after IN")
        return
    end

    local src = mp.get_property("path")
    if not src or src == "" then
        msg("No source path")
        return
    end

    -- If mpv is playing a URL/pipe, stream-copy may not work; this assumes a file path.
    local filename = path_basename(src)
    local stem = strip_ext(filename)

    -- Put output next to the input file if possible; otherwise current dir.
    local dir = mp.get_property("working-directory") or "."
    local out = string.format("%s/%s_%0.3f-%0.3f.mkv", dir, stem, inpos, out_t)

    -- Prefer keyframe-accurate-ish stream copy: -ss before -i is fast but can be off;
    -- use -ss after -i for accurate cut (but slower). Here: accurate.
    local args = {
        "ffmpeg",
        "-hide_banner", "-loglevel", "error",
        "-i", src,
        "-ss", string.format("%.6f", inpos),
        "-to", string.format("%.6f", out_t),
        "-c", "copy",
        out
    }

    msg("Exporting…")
    local res = utils.subprocess({ args = args, cancellable = false })
    if res.status == 0 then
        msg("Wrote: " .. out)
    else
        msg("ffmpeg failed")
    end
end

mp.register_script_message("mark_in", function()
    in_t = cur_time()
    msg(string.format("IN: %.3f", in_t))
end)

mp.register_script_message("mark_out_and_export", function()
    local out_t = cur_time()
    msg(string.format("OUT: %.3f", out_t))
    export_segment(out_t)
end)
