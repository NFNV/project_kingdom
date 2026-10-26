# Project Kingdom prototype audio

This pack contains 43 playback clips and one soundtrack preview: four original
instrumental themes, sixteen footstep variations, combat and interface cues,
and five ambient loops. These are prototype arrangements and synthesized sound
design, ready for listening and further artistic refinement.

The town theme uses flute, guitar, strings and harp; woodland uses flute and
harp; night uses celesta and soft accompaniment; battle uses strings, guitar
and marimba. The themes loop for about 48–53 seconds. Hear excerpts in
[soundtrack_preview.wav](soundtrack_preview.wav).

## Source and regeneration

The note sequences and arrangements are authored in
`../../tools/compose_score.py` and saved in the four `*_score.json` files.
`../../tools/render_score.swift` renders two cycles offline with Apple's local
Core Audio GM sampler. Its system instrument bank is read from
`/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls`;
the bank itself is not copied or distributed. There are no downloaded songs.
`../../tools/build_audio.py` masters the second cycle, which retains the prior
cycle's reverb, and creates deterministic original ambience and foley with NumPy.

From the repository root on macOS with Swift, Python and NumPy installed:

```sh
python3 experiments/anime_hub_demo_v07/tools/compose_score.py
swift -module-cache-path /tmp/kingdom_swift_cache experiments/anime_hub_demo_v07/tools/render_score.swift /Users/n/Documents/project-kingdom/experiments/anime_hub_demo_v07/assets/audio
python3 experiments/anime_hub_demo_v07/tools/build_audio.py
python3 experiments/anime_hub_demo_v07/tools/audit_audio.py
```

The sampler needs access to the local macOS audio components when rendering.
The resulting `*_raw.wav` intermediates are ignored by Git and may be removed
after mastering. Finished files are 32 kHz, 16-bit PCM WAV; brief endpoint
tapers prevent discontinuities. `catalog.json` records loop flags, duration,
channels, RMS, peaks, SHA-256 hashes and provenance. `qa_report.json` checks
the saved PCM against that catalog, including non-silent channels and clipping.

## Playback

`../../tools/soundscape.gd` caches the 43 finished clips once, sets loop points,
and routes them through separate music, ambience and effects buses under a
limited master bus. Two music players crossfade over 1.6 seconds. Two ambient
beds follow the clock; two positional loops cover nearby water or the oven.
Twelve reusable positional effects players handle footsteps and combat, with
distance culling. There is no synthesis during gameplay.

Footsteps depend on distance travelled, not animation timers. Combat sounds
follow accepted actions and actual contact/skill timing. Pause freezes loops
and drops transient cues. Zone changes clear old effects and bind the listener
to the player. Volume and mute preferences are stored in
`user://kingdom_audio.cfg`, independently of game progress.

Use Esc for the four volume sliders and mute checkbox, or M to mute/unmute.
`../../audio_test_results.json` records gameplay and actual mixer tests;
`../../audio_performance.json` records native foreground frame timing with
CoreAudio enabled. These are short local measurements, not a hardware-wide
performance guarantee.
