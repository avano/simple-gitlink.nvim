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

-- exec system command
local function exec(str)
  return vim.trim(vim.fn.system(str))
end

-- get the http link based on the arguments
local function get_http_link(remote, branch, file, range)
  local http_url
  local git_url = exec('git config --get remote.' .. remote .. '.url'):gsub('.git$', '')
  if not git_url:match('^https://') then
    git_url = git_url:gsub(':', '/'):gsub('.*@', 'https://')
  end
  return string.format('%s/blob/%s/%s%s', git_url, branch, file, range)
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

  local remotes = vim.split(M.options.remotes, ',')
  debug('Remotes: ' .. vim.inspect(remotes))
  -- select the first remote that contains the branch or nil
  local remote = vim.tbl_filter(function(r)
    return exec('git branch --remotes --list ' .. r .. '/' .. branch) ~= ''
  end, remotes)[1]

  -- if no remote contains the current branch, link to the default remote's default branch
  if not remote then
    debug('No remote branch found')
    remote = exec('git config --get checkout.defaultremote')
    debug('Default remote: ' .. remote)
    branch = exec('git symbolic-ref refs/remotes/'.. remote .. '/HEAD'):match('[^/]+$')
    debug('Default branch for remote: ' .. remote .. ': ' .. branch)
  end

  -- get the current file path relative to the repository root
  local file_path = vim.fn.expand('%:p'):gsub(vim.pesc(repo_root) .. '/', '')
  debug('File path relative to the repository root: ' .. file_path)
  -- get the visual range start / end linenumbers
  local start_line, end_line = vim.fn.line('v'), vim.fn.line('.')
  debug('Visual range: ' .. start_line .. '-' .. end_line)

  local range = start_line == end_line and '#L' .. start_line or string.format('#L%d-L%d', math.min(start_line, end_line), math.max(start_line, end_line))

  local link = get_http_link(remote, branch, file_path, range)
  -- copy the link to the clipboard
  vim.fn.setreg('+', link)
  vim.notify(link, vim.log.levels.INFO)
end

return M
-- vim: ts=2 sts=2 sw=2 et
