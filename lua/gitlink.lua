local M = {}

local defaults = {
  remotes = 'origin',
  debug = false
}

function M.setup(opts)
  M.options = vim.tbl_extend('force', defaults, opts or {})
end

local function debug(msg)
  if M.options.debug then
     print('DEBUG: ' .. msg)
  end
end

-- split the string by the given delimiter
local function split(str, delimiter)
  local t = {}
  for s in string.gmatch(str, string.format("([^%s]+)", delimiter)) do
    table.insert(t, s)
  end
  return t
end

-- trim the string
local function trim(str)
  return str:match("^%s*(.-)%s*$")
end

-- exec system command
local function exec(str)
  return trim(vim.fn.system(str))
end

-- get the http link based on the arguments
local function get_http_link(remote, branch, file, range)
  local http_url
  local git_url = exec('git config --get remote.' .. remote .. '.url'):gsub('.git$', '')
  if not string.match(git_url, "^https://") then
    git_url = git_url:gsub(':', '/'):gsub('.*@', 'https://')
  end
  return trim(string.format('%s/blob/%s/%s%s', git_url, branch, file, range))
end

-- main function
function M.create_git_link()
  -- check if the file is inside a git repository
  local repo_root = exec('git rev-parse --show-toplevel 2>/dev/null')
  if repo_root == '' then
    vim.notify('Not inside git repository', vim.log.levels.WARN)
    return
  end
  debug('Repo root: ' .. repo_root)

  -- get the current local branch
  local branch = exec('git branch --show-current 2>/dev/null')
  if branch == '' then
    vim.notify('Not working with a branch', vim.log.levels.WARN)
    return
  end
  debug('Local branch: ' .. branch)

  local remotes = split(M.options.remotes, ',')
  debug('Remotes: ' .. vim.inspect(remotes))
  local remote = nil
  -- iterate over defined remotes and find first that contains given branch
  for _, r in ipairs(remotes) do
    local output = exec('git branch --remotes --list ' .. string.format('%s/%s', r, branch))
    debug('Output for remote: ' .. r .. ', branch: ' .. branch .. ': ' .. output)
    if output ~= "" then
      debug('Selected remote: ' .. r)
      remote = r
      break
    end
  end

  -- if no remote contains the current branch, link to the default remote's default branch
  if remote == nil then
    debug('No remote branch found')
    remote = exec('git config --get checkout.defaultremote')
    debug('Default remote: ' .. remote)
    local strings = split(exec('git symbolic-ref refs/remotes/'.. remote .. '/HEAD'), '/')
    branch = strings[#strings]
    debug('Default branch for remote: ' .. remote .. ': ' .. branch)
  end

  -- get the current file path relative to the repository root
  local file_path = vim.fn.expand('%:p'):gsub(repo_root:gsub('-', '%%-') .. '/', '')
  debug('File path relative to the repository root: ' .. file_path)
  -- get the visual range start / end linenumbers
  local start_line = vim.fn.line('v')
  local end_line = vim.fn.line('.')
  debug('Visual range: ' .. start_line .. '-' .. end_line)

  local range

  -- the visual range is directional, so the start_line may be higher than end_line, so swap them if that's the case
  if start_line == end_line then
    range = '#L' .. start_line
  elseif start_line < end_line then
    range = string.format('#L%s-L%s', start_line, end_line)
  else
    range = string.format('#L%s-L%s', end_line, start_line)
  end

  local link = get_http_link(remote, branch, file_path, range)
  -- copy the link to the clipboard
  vim.fn.setreg('+', link)
  vim.notify(link, vim.log.levels.INFO)
end

return M
-- vim: ts=2 sts=2 sw=2 et
