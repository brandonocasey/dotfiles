---
name: device-test
description: "Hands-on testing on a real device (AirPlay, iPhone, TV) where the user must act; checklist page returns results."
---

Use when a check needs a person or hardware the agent cannot drive: AirPlay
targets, a real iPhone, TVs, Control Center. Try `real-safari` or the
`browser` skill first; this is the fallback. The user is the sensor, so spend
their attention once: preflight, then one page, then read results.

## Preflight (do all before handing over)

1. Name the device under test and the machine hosting the page. Ask when
   unknown; never assume iPhone or Mac. Put the name in the page.
2. Same LAN: run `ipconfig getifaddr en0` (`hostname -I` on Linux) and give
   the device that URL, not localhost. The server prints a guess; swap in the en0 address if it is a VPN one. A QR code helps for phones.
3. Check the page loads from the device's network before asking: `curl` the
   LAN URL. A firewall prompt or VPN can block it.
4. iPhone driven by the agent: Safari > Settings > Developer > Remote
   Automation must be on, and the phone unlocked and trusted. Stop and ask if
   it drops mid-run; do not retry in a loop.
5. HTTPS: clipboard, camera, mic, DRM (EME `requestMediaKeySystemAccess`), and service workers
   need a secure context; LAN http fails there. Use a tunnel, local certificate, or localhost, and say so before the user
   starts. Whether Safari's AirPlay picker works on http is unverified; test it.
6. Check that the build under test is the one served (version string or
   hash), and that the target device is on and discoverable (AirPlay: same
   Wi-Fi, not already connected to something else).

## Scenarios

Write `scenarios.json` in the task scratch dir:
`{"title","device","scenarios":[{"id","title","steps":[]}]}`.

- Number every scenario; one sentence title, at most 3 short steps.
- Put shared setup and teardown in the page, not in every scenario. For
  AirPlay, step 1 and the last step reset to the local device.
- Cover the expected result in the title ("Audio plays on <device>").
- No event logs or debug UI the user must read.

## Run and read results

```sh
python3 ~/.config/agents/skills/device-test/scripts/serve.py scenarios.json --out results.jsonl
```

Run it in the background; it prints the LAN URL (with a random token in the path; requests without it get 403)
and picks a free port. Give the user the URL, then wait. Read new lines of `results.jsonl`
(`{id,status,notes,ts,device,ua}`; status is pass, fail, or skip). Do not ask
for results in chat. If the user types prose instead, record it against the
scenario and continue.

Reprint the scenario list when the user asks for it or after any change. After
a fix, rerun only failed scenarios plus one that passed, with a fresh
`--out` file. Stop the server when done, per
[task-resources.md](../host-preflight/references/task-resources.md).

## Report

Per scenario: id, status, notes, device, build. State what stayed untested.
