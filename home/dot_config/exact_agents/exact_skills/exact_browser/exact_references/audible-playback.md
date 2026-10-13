# Audible playback

Read when the task is about audio: no sound, wrong volume, mute state, unmuted
autoplay, audio tracks, or audio sync. This is the exception to the sound rule
in `SKILL.md`. Keep sound off for all other work.

- Before audible playback starts, tell the user in one line, for example
  "Starting headed Firefox with sound to check the audio track."
- Check the active harness's MCP configuration for a headed entry without `--mute-audio`.
  Use that entry; a page cannot undo a process-level mute.
- Unmute in the page and in the app, for example the media element's `muted`
  and `volume` and the app's own mute control.
- Browsers block unmuted autoplay without a user gesture. Use the MCP's click
  tool on the real control to make a gesture. Test both paths when autoplay is
  in scope.
- Stop playback and close the page as soon as the check is done.
