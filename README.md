# simple-gitlink.nvim
A simple link to the Git UI from nvim

## Motivation
In my workflow, I primarily use `origin` and `upstream` remotes in Git, where `origin` points to my fork and `upstream` to the upstream repository. Sometimes, I want to quickly generate a link to the Git web UI without manually specifying a remote.

Most other plugins either default to the first remote they find, require you to manually specify a remote every time, or fail with an error if the branch doesn’t exist on the remote. This can be inconvenient when you have local work in progress but want to link to code that already exists on the remote.
This plugin provides a more efficient solution: you supply a list of remotes, and the plugin will automatically choose the first remote that contains a branch matching the name of your current branch. 
If no such remote exists, the default remote (as defined by `git config --get checkout.defaultremote`) is selected, and its default branch is used to generate the Git link.

## Usage

To use this plugin with the `lazy.nvim` plugin manager, add the following configuration to your `lazy.nvim` setup:

```lua
return {
  'avano/simple-gitlink.nvim',
  main = 'gitlink',
  opts = {
      remotes = 'upstream,origin'
  },
  -- lazy load the plugin on the <leader>gl key binding in normal and visual mode
  keys = {
    { "<leader>gl", function() require('gitlink').create_git_link() end, mode = { 'n', 'x' }, desc = 'Git: Copy link' }
  }
}
```
