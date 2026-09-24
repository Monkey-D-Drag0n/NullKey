.pragma library

// Each entry is independent of the UI; adding an application or shell only
// requires adding records here (and exposing the target in the picker).
var items = [
    {environment:"Hyprland", target:"Hyprland", category:"Windows", keys:["SUPER","Q"], description:"Close the active window", action:"Close window"},
    {environment:"Hyprland", target:"Hyprland", category:"Windows", keys:["SUPER","F"], description:"Toggle floating mode", action:"Toggle floating"},
    {environment:"Hyprland", target:"Hyprland", category:"Windows", keys:["SUPER","M"], description:"Exit the compositor", action:"Exit session"},
    {environment:"Hyprland", target:"Hyprland", category:"Windows", keys:["SUPER","SHIFT","Q"], description:"Close the active window", action:"Close window"},
    {environment:"Hyprland", target:"Hyprland", category:"Workspaces", keys:["SUPER","1"], description:"Switch to workspace 1", action:"Workspace 1"},
    {environment:"Hyprland", target:"Hyprland", category:"Workspaces", keys:["SUPER","SHIFT","1"], description:"Move window to workspace 1", action:"Move to workspace 1"},
    {environment:"Hyprland", target:"Hyprland", category:"Applications", keys:["SUPER","ENTER"], description:"Open the terminal", action:"Launch terminal"},
    {environment:"Hyprland", target:"Hyprland", category:"Applications", keys:["SUPER","E"], description:"Open the file manager", action:"Launch file manager"},
    {environment:"Hyprland", target:"Hyprland", category:"Windows", keys:["SUPER","V"], description:"Toggle floating for the active window", action:"Toggle floating"},
    {environment:"Omarchy", target:"Hyprland", category:"Windows", keys:["SUPER","Q"], description:"Close the active window", action:"Close window"},
    {environment:"Omarchy", target:"Hyprland", category:"Applications", keys:["SUPER","ENTER"], description:"Open terminal", action:"Launch terminal"},
    {environment:"Brave", target:"Brave", category:"Tabs", keys:["CTRL","T"], description:"Open a new tab", action:"New tab"},
    {environment:"Brave", target:"Brave", category:"Tabs", keys:["CTRL","SHIFT","T"], description:"Reopen the last closed tab", action:"Reopen tab"},
    {environment:"Brave", target:"Brave", category:"Navigation", keys:["CTRL","L"], description:"Focus the address bar", action:"Focus address bar"},
    {environment:"Chrome", target:"Chrome", category:"Tabs", keys:["CTRL","W"], description:"Close the current tab", action:"Close tab"},
    {environment:"Safari", target:"Safari", category:"Tabs", keys:["SUPER","T"], description:"Open a new tab", action:"New tab"},
    {environment:"Safari", target:"Safari", category:"Tabs", keys:["SUPER","W"], description:"Close the current tab", action:"Close tab"},
    {environment:"Safari", target:"Safari", category:"Navigation", keys:["SUPER","L"], description:"Focus the address bar", action:"Focus address bar"},
    {environment:"VS Code", target:"VS Code", category:"Editor", keys:["CTRL","SHIFT","P"], description:"Open the command palette", action:"Command palette"},
    {environment:"VS Code", target:"VS Code", category:"Editor", keys:["CTRL","P"], description:"Quickly open a file", action:"Quick Open"},
    {environment:"LazyVim", target:"LazyVim", category:"Editor", keys:["SPACE","F","F"], description:"Find files", action:"Find files"},
    {environment:"Kitty", target:"Kitty", category:"Tabs", keys:["CTRL","SHIFT","ENTER"], description:"Open a new terminal window", action:"New window"},
    {environment:"Dolphin", target:"Dolphin", category:"Files", keys:["CTRL","N"], description:"Open a new window", action:"New window"}
]
