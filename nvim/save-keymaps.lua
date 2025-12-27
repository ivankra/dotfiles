-- Dumps keymaps into a file.
-- :luafile save-keymaps.lua
-- :SaveKeymaps keymaps.txt

local function get_all_keymaps()
  local modes = { "n", "i", "v", "x", "s", "o", "t", "c" }
  local all_maps = {}

  for _, mode in ipairs(modes) do
    local maps = vim.api.nvim_get_keymap(mode)
    for _, map in ipairs(maps) do
      table.insert(all_maps, string.format(
        "[%s] %s -> %s%s",
        mode,
        map.lhs,
        map.rhs,
        map.desc and (" (" .. map.desc .. ")") or ""
      ))
    end
  end

  return all_maps
end

vim.api.nvim_create_user_command("SaveKeymaps", function(opts)
  local path = opts.args
  local maps = get_all_keymaps()

  local f = io.open(path, "w")
  if not f then
    print("Failed to open file: " .. path)
    return
  end

  for _, line in ipairs(maps) do
    f:write(line .. "\n")
  end
  f:close()

  print("Keymaps saved to " .. path)
end, { nargs = 1 })
