# The machine's LAN IPv4 address, found the same way as the Claude status line
function _tide_item_ip
    set -l host
    if command -q ipconfig
        set -l iface (route -n get default 2>/dev/null | string replace -rf '.*interface: ' '')
        test -n "$iface" && set host (ipconfig getifaddr $iface 2>/dev/null)
        # A VPN's utun default route often has no IPv4 address; use the first
        # Ethernet or Wi-Fi interface that has one.
        if test -z "$host"
            for iface in (ifconfig -l 2>/dev/null | string split ' ' | string match 'en*')
                set host (ipconfig getifaddr $iface 2>/dev/null) && test -n "$host" && break
            end
        end
    end
    test -z "$host" && set host (ip -4 route get 1.1.1.1 2>/dev/null | string match -rg 'src (\S+)')
    test -n "$host" && _tide_print_item ip $host
end
