-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

-- Read the active system theme (written by ~/dotfiles/scripts/theme-switch.sh)
-- and map it to the matching colorscheme. Falls back to gruvbox.
local function system_colorscheme()
  local map = { nord = "nord", gruvbox = "gruvbox", latte = "catppuccin-latte" }
  local home = os.getenv("HOME") or ""
  local f = io.open(home .. "/.config/sway/.current-theme", "r")
  if not f then return "gruvbox" end
  local theme = f:read("*l")
  f:close()
  if theme then theme = theme:gsub("%s+", "") end
  return map[theme or ""] or "gruvbox"
end

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme (follows the system theme via theme-switch.sh)
    colorscheme = system_colorscheme(),
    -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
    highlights = {
      init = { -- this table overrides highlights in all themes
        -- Normal = { bg = "#000000" },
      },
      astrodark = { -- a table of overrides/changes when applying the astrotheme theme
        -- Normal = { bg = "#000000" },
      },
    },
    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
