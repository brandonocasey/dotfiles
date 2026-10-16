# tmux panes start one shell level deep. Tide draws the prompt in a
# non-interactive child shell, so raise the threshold only there.
if not status is-interactive
    set -q TMUX && set -q tide_shlvl_threshold && set -g tide_shlvl_threshold (math $tide_shlvl_threshold + 1)
    return
end

# Keep these tide items on every machine, even after `tide configure` resets them
functions -q _tide_detect_os || return

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

# LAN IP, right of the user@host context
set -q tide_ip_color || set -U tide_ip_color D787D7
set -q tide_ip_bg_color || set -U tide_ip_bg_color 1C1C1C
if not contains ip $tide_right_prompt_items
    set -l i (contains -i context $tide_right_prompt_items)
    if test -n "$i"
        set -U tide_right_prompt_items $tide_right_prompt_items[1..$i] ip $tide_right_prompt_items[(math $i + 1)..]
    else
        set -U -a tide_right_prompt_items ip
    end
end
