local config = require('glance.config')
local Renderer = {}
Renderer.__index = Renderer

function Renderer:new(bufnr, winnr)
  local scope = {
    lines = {},
    hl = {},
    line_nr = 0,
    current = '',
    bufnr = bufnr,
    winnr = winnr,
  }
  setmetatable(scope, self)
  return scope
end

Renderer.cur_ns = vim.api.nvim_create_namespace('list_cur_ns')

function Renderer:nl()
  table.insert(self.lines, self.current)
  self.current = ''
  self.line_nr = self.line_nr + 1
end

function Renderer:highlight()
  local cursorline = vim.api.nvim_win_get_cursor(self.winnr)[1] - 1
  vim.api.nvim_buf_clear_namespace(self.bufnr, self.cur_ns, 0, -1)
  for _, line in ipairs(self.hl) do
    if line.group == 'GlanceListMatch' then
      vim.api.nvim_buf_set_extmark(
        self.bufnr,
        config.namespace,
        line.line_nr,
        line.from,
        {
          end_col = line.to,
          end_line = line.line_nr,
          strict = false,
          hl_group = 'Search',
          priority = 1000,
        }
      )
      if line.line_nr == cursorline then
        vim.api.nvim_buf_set_extmark(
          self.bufnr,
          self.cur_ns,
          line.line_nr,
          line.from,
          {
            end_col = line.to,
            end_line = line.line_nr,
            strict = false,
            hl_group = 'CurSearch',
            priority = 10000,
          }
        )
      end
    else
      vim.api.nvim_buf_add_highlight(
        self.bufnr,
        config.namespace,
        line.group,
        line.line_nr,
        line.from,
        line.to
      )
    end
  end
end

function Renderer:append(str, group, opts)
  str = str:gsub('[\n]', ' ')

  if type(opts) == 'string' then
    opts = { append = opts }
  end

  opts = opts or {}

  if group then
    group = config.hl_ns .. group
    local from = string.len(self.current)
    local hl = {
      line_nr = self.line_nr,
      from = from,
      to = from + string.len(str),
      group = group,
    }
    table.insert(self.hl, hl)
  end

  self.current = self.current .. str

  if opts.append then
    self.current = self.current .. opts.append
  end
end

function Renderer:render()
  return vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, self.lines)
end

return Renderer
