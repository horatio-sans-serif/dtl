#!/bin/bash

set -e

CAPTURE_MAX_DURATION="${CAPTURE_MAX_DURATION:-0}"
CAPTURE_MAX_FRAMES="${CAPTURE_MAX_FRAMES:-0}"
CAPTURE_INTERVAL="${CAPTURE_INTERVAL:-10}"
CAPTURE_DIR="${CAPTURE_DIR:-$(mktemp -d)}"
CAPTURE_CURSOR="${CAPTURE_CURSOR:-true}"
CAPTURE_DISPLAY="${CAPTURE_DISPLAY:-1}"
CAPTURE_FORMAT="${CAPTURE_FORMAT:-png}"

VIDEO_SPF="${VIDEO_SPF:-0.5}"
VIDEO_FORMAT="${VIDEO_FORMAT:-mp4}"
VIDEO_PATH="${VIDEO_PATH:-$(mktemp).$VIDEO_FORMAT}"
VIDEO_MAX_WIDTH="${VIDEO_MAX_WIDTH:-auto}"

OPEN_APP="${OPEN_APP:-QuickTime Player}"

AUTO_START="${AUTO_START:-true}"

DEBUG="${DEBUG:-false}"
[[ "$DEBUG" = true ]] && set -x

trap "rm -rf $CAPTURE_DIR" EXIT

list_displays() {
    system_profiler SPDisplaysDataType | awk '
        /Display Type:/ { display=$3 }
        /Resolution:/ {
            resolution=$2
            for(i=3;i<=NF;i++) resolution=resolution" "$i
            displays[++count]=sprintf("%d: %s (%s)", count, display, resolution)
        }
        END {
            print "Available displays:"
            for(i=1;i<=count;i++) print displays[i]
        }'
}

if [ "$1" = "--list-displays" ]; then
    list_displays
    exit 0
fi

clear

echo "DTL: Desktop Time-Lapse"
echo -e "- will capture every \033[36m$CAPTURE_INTERVAL\033[0m seconds"
echo -e "- output video will show each captured frame for \033[36m$VIDEO_SPF\033[0m seconds"
echo -e "- output video will have max width of \033[36m$VIDEO_MAX_WIDTH\033[0m pixels"
echo -e "- output video will be saved to: \033[36m$VIDEO_PATH\033[0m"
echo -e "- capturing from display: \033[36m$CAPTURE_DISPLAY\033[0m (use --list-displays to see options)"

if [ "$CAPTURE_MAX_FRAMES" -gt 0 ]; then
    echo -e "- will capture at most \033[36m$CAPTURE_MAX_FRAMES\033[0m frames"
fi

if [ "$CAPTURE_MAX_DURATION" -gt 0 ]; then
    echo -e "- will capture for at most \033[36m$CAPTURE_MAX_DURATION\033[0m seconds"
fi

if [ -z "$OPEN_WITH" ]; then
    echo -e "- will open video with: \033[36m$OPEN_APP\033[0m"
else
    echo "- will not open video in viewer after recording"
fi

if [ "$AUTO_START" != true ]; then
    echo -ne "Press \033[36menter\033[0m to start recording..."
    read
fi

echo -e "\033[31mPress CTRL-C to stop recording\033[0m"

interrupted=false
trap "interrupted=true" INT

end_time=$(($(date +%s) + CAPTURE_MAX_DURATION))

i=0

while [ $CAPTURE_MAX_DURATION -eq 0 ] || [ $(date +%s) -lt $end_time ]; do
    [ "$interrupted" = true ] && break
    [ $CAPTURE_MAX_FRAMES -gt 0 ] && [ $i -ge $CAPTURE_MAX_FRAMES ] && break

    opts="-x -r -t $CAPTURE_FORMAT"
    [[ "$CAPTURE_CURSOR" != false ]] && opts="$opts -C"
    [[ "$CAPTURE_DISPLAY" != 1 ]] && opts="$opts -d $CAPTURE_DISPLAY"

    frame_path="$CAPTURE_DIR/$(printf '%06d' $i).png"
    screencapture $opts "$frame_path" 2>/dev/null || break

    echo -ne "\r... captured frame \033[36m$i\033[0m at \033[33m$(date)\033[0m to \033[35m$frame_path\033[0m"

    i=$(( $i + 1 ))

    sleep $CAPTURE_INTERVAL || true
done

# Loop will exit here either due to CAPTURE_MAX_DURATION or interrupt

echo
echo -e "converting frames to video... \033[36m$VIDEO_PATH\033[0m"

FRAME_RATE=$(echo "scale=2; 1/$VIDEO_SPF" | bc)

mkfifo "$CAPTURE_DIR/progress"
ffmpeg_args="-loglevel error -hide_banner -progress "$CAPTURE_DIR/progress" -framerate $FRAME_RATE -i $CAPTURE_DIR/%06d.png"

case "$VIDEO_FORMAT" in
    "gif")
        ffmpeg_args="$ffmpeg_args -vf palettegen=stats_mode=full -f image2 $CAPTURE_DIR/palette.png"
        ffmpeg $ffmpeg_args
        ffmpeg_args="-loglevel error -progress "$CAPTURE_DIR/progress" -framerate $FRAME_RATE -i $CAPTURE_DIR/%06d.png -i $CAPTURE_DIR/palette.png -lavfi paletteuse"
        ;;
    "webm")
        ffmpeg_args="$ffmpeg_args -c:v libvpx-vp9 -crf 30 -b:v 0"
        ;;
    *)
        ffmpeg_args="$ffmpeg_args -c:v libx264 -pix_fmt yuv420p"
        ;;
esac

[ "$VIDEO_MAX_WIDTH" != "auto" ] && ffmpeg_args="$ffmpeg_args -vf scale=$VIDEO_MAX_WIDTH:-1"
[ "$DEBUG" = true ] && ffmpeg_args="$ffmpeg_args -v verbose"

ffmpeg $ffmpeg_args $VIDEO_PATH &

if [ "$LOG_NOTHING" != true ]; then
    awk -v total="$i" '
    BEGIN { printf "\rConverting: [" }
    /frame=/ {
        frame=$1
        sub(/frame=/, "", frame)
        pct = frame/total * 100
        printf "\rConverting: ["
        for(i=0; i<pct/2; i++) printf "#"
        for(i=pct/2; i<50; i++) printf " "
        printf "] %d%%", pct
    }
    END { printf "\rConverting: [##################################################] 100%%\n" }
    ' "$CAPTURE_DIR/progress"
fi

wait

if [ "$NO_OPEN" = false ]; then
    open -a "$OPEN_APP" $VIDEO_PATH
fi
