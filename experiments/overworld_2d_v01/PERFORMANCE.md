# Expanded-region performance

The latest post-polish native smoke test rendered at 1920×1080 on Apple M1 / Metal, Godot 4.7.2, with a 60 FPS cap. None of its three samples maintained the required 95% window focus, so **1080p60 remains unverified**. These measurements are diagnostic, not a claim of foreground performance.

| Case | FPS | p95 ms | Worst ms | Window focused |
|---|---:|---:|---:|---:|
| mosswood | 56.1 | 21.55 | 127.61 | 32.0% |
| meadow_flat | 54.2 | 24.59 | 57.49 | 1.8% |
| regional_map | 60.0 | 17.38 | 17.68 | 0.0% |

The pass reduced city outline draw cost, thinned and faded distant flat-mode scenery, enabled filtered mipmapped landscape textures, indexed collision spatially and hid the world while the opaque region map is open. Flat-mode visible scenery dropped from 608 to 220 objects in comparable samples; collision retains all 1,494 objects.

The pre-optimization report and the broader run before the final drawing polish are retained in `performance_region_before_optimization.json` and `performance_region_unfocused_before_polish.json`. They include mixed or lost window focus and do not validate the final source. The earlier eight-case report was for the smaller, previous region.

For a clean repeat, keep the game window focused throughout `profile_overworld.gd`. `-- --stage=mosswood` tests one case; `-- --final-smoke` tests these three. The default run covers all thirteen cases, including physical travel, eight-way turns, orbit and the new landscapes. Image readback occurs after each measurement. No foreground-success claim should be made from a sample marked `valid_foreground_sample: false`.
