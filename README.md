# display-time-lapse (dtl)

`dtl` is a CLI tool to record your macOS display at regular intervals and convert the frames into a video.

```bash
./dtl.sh
```

| Option                   | Description                                                    | Default Value         |
| ------------------------ | -------------------------------------------------------------- | --------------------- |
| **CAPTURE_INTERVAL**     | Interval between frames in seconds.                            | `10`                  |
| **CAPTURE_DISPLAY**      | Which display to capture (use --list-displays to see options). | `1` _(primary)_       |
| **CAPTURE_CURSOR**       | Flag to capture the cursor.                                    | `true`                |
| **CAPTURE_DIR**          | Directory for captured display frame images.                   | _Temporary directory_ |
| **CAPTURE_FORMAT**       | Image format for screen captures.                              | `png`                 |
| **CAPTURE_MAX_DURATION** | Maximum recording time in seconds.                             | `0` _(no limit)_      |
| **CAPTURE_MAX_FRAMES**   | Maximum number of frames to capture.                           | `0` _(no limit)_      |
| **DEBUG**                | Activates shell debug mode if `true`.                          | `false`               |
| **OPEN_WITH**            | Name of app with which to open final video.                    | `"QuickTime Player"`  |
| **VIDEO_MAX_WIDTH**      | Target width of the output video in pixels.                    | `auto`                |
| **VIDEO_PATH**           | File path for the output video.                                | _Temporary .mp4 file_ |
| **VIDEO_FORMAT**         | Output format (mp4, gif, webm).                                | `mp4`                 |
| **VIDEO_SPF**            | Seconds per frame for the final video.                         | `0.5`                 |
| **AUTO_START**           | Automatically start recording when the script is run.          | `true`                |

---

Example:

```bash
./dtl.sh --list-displays

CAPTURE_INTERVAL=5 VIDEO_SPF=1 VIDEO_PATH="~/Desktop/dtl-$(date +%Y-%m-%d_%H-%M-%S).mp4" ./dtl.sh
```

---

FFMPEG is required. Install it with `brew install ffmpeg`.
