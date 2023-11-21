local Buffer = require("neogit.lib.buffer")
local ui = require("neogit.buffers.log_view.ui")
local config = require("neogit.config")
local popups = require("neogit.popups")
local notification = require("neogit.lib.notification")

local CommitViewBuffer = require("neogit.buffers.commit_view")

---@class LogViewBuffer
---@field commits CommitLogEntry[]
---@field internal_args table
local M = {}
M.__index = M

---Opens a popup for selecting a commit
---@param commits CommitLogEntry[]|nil
---@param internal_args table|nil
---@return LogViewBuffer
function M.new(commits, internal_args)
  local instance = {
    commits = commits,
    internal_args = internal_args,
    buffer = nil,
  }

  setmetatable(instance, M)

  return instance
end

function M:close()
  self.buffer:close()
  self.buffer = nil
end

function M:open()
  local _, item = require("neogit.status").get_current_section_item()
  self.buffer = Buffer.create {
    name = "NeogitLogView",
    filetype = "NeogitLogView",
    kind = config.values.log_view.kind,
    context_highlight = false,
    mappings = {
      v = {
        [popups.mapping_for("CherryPickPopup")] = popups.open("cherry_pick", function(p)
          p { commits = self.buffer.ui:get_commits_in_selection() }
        end),
        [popups.mapping_for("BranchPopup")] = popups.open("branch", function(p)
          p { commits = self.buffer.ui:get_commits_in_selection() }
        end),
        [popups.mapping_for("CommitPopup")] = popups.open("commit", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("PushPopup")] = popups.open("push", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RebasePopup")] = popups.open("rebase", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RevertPopup")] = popups.open("revert", function(p)
          p { commits = self.buffer.ui:get_commits_in_selection() }
        end),
        [popups.mapping_for("ResetPopup")] = popups.open("reset", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("TagPopup")] = popups.open("tag", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        ["d"] = function()
          if not config.check_integration("diffview") then
            notification.error("Diffview integration must be enabled for log diff")
            return
          end

          local dv = require("neogit.integrations.diffview")
          dv.open("log", self.buffer.ui:get_commits_in_selection())
        end,
      },
      n = {
        [popups.mapping_for("CherryPickPopup")] = popups.open("cherry_pick", function(p)
          p { commits = { self.buffer.ui:get_commit_under_cursor() } }
        end),
        [popups.mapping_for("BranchPopup")] = popups.open("branch", function(p)
          p { commits = { self.buffer.ui:get_commit_under_cursor() } }
        end),
        [popups.mapping_for("CommitPopup")] = popups.open("commit", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("PushPopup")] = popups.open("push", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RebasePopup")] = popups.open("rebase", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RevertPopup")] = popups.open("revert", function(p)
          p { commits = { self.buffer.ui:get_commit_under_cursor() } }
        end),
        [popups.mapping_for("ResetPopup")] = popups.open("reset", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("TagPopup")] = popups.open("tag", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        ["q"] = function()
          self:close()
        end,
        ["<esc>"] = function()
          self:close()
        end,
        ["<enter>"] = function()
          CommitViewBuffer.new(self.buffer.ui:get_commit_under_cursor()):open()
        end,
        ["<c-k>"] = function()
          vim.cmd("normal! zc")

          vim.cmd("normal! k")
          while vim.fn.foldlevel(".") == 0 do
            vim.cmd("normal! k")
          end

          vim.cmd("normal! zo")
          vim.cmd("normal! zz")
        end,
        ["<c-j>"] = function()
          vim.cmd("normal! zc")

          vim.cmd("normal! j")
          while vim.fn.foldlevel(".") == 0 do
            vim.cmd("normal! j")
          end

          vim.cmd("normal! zo")
          vim.cmd("normal! zz")
        end,
        ["<tab>"] = function()
          pcall(vim.cmd, "normal! za")
        end,
        ["d"] = function()
          if not config.check_integration("diffview") then
            notification.error("Diffview integration must be enabled for log diff")
            return
          end

          local dv = require("neogit.integrations.diffview")
          dv.open("log", self.buffer.ui:get_commit_under_cursor())
        end,
      },
    },
    after = function(buffer, win)
      if win and item and item.commit then
        local found = buffer.ui:find_component(function(c)
          return c.options.oid == item.commit.oid
        end)

        if found then
          vim.api.nvim_win_set_cursor(win, { found.position.row_start, 0 })
        end
      end

      vim.cmd([[setlocal nowrap]])
    end,
    render = function()
      return ui.View(self.commits, self.internal_args)
    end,
  }
end

return M
