# Keep these tide items on every machine, even after `tide configure` resets them
status is-interactive && functions -q _tide_detect_os || return

test -n "$tide_os_icon" || _tide_detect_os | read -U tide_os_icon
contains os $tide_left_prompt_items || set -U tide_left_prompt_items os $tide_left_prompt_items

if not contains shlvl $tide_right_prompt_items
    set -l i (contains -i jobs $tide_right_prompt_items)
    if test -n "$i"
        set -U tide_right_prompt_items $tide_right_prompt_items[1..$i] shlvl $tide_right_prompt_items[(math $i + 1)..]
    else
        set -U -a tide_right_prompt_items shlvl
    end
end

# tmux panes start at shell level 2, so show only deeper nesting there
set -q TMUX && set -gx tide_shlvl_threshold 2
