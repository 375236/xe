#!/bin/bash
#
# Downloads ten videos from /r/TikTokCringe, concatenates every video file with blur box effect
# using h264_nvenc nvidia encoder
# 

date=$(date +%Y-%m-%d_%H:%M:%S)

mkdir -p blur rendered

# parallel download videos from /r/TikTokCringe
curl -s -H "User-agent: 'Somebody 0.2'" https://www.reddit.com/r/TikTokCringe/hot.json?limit=10 | jq -r '.data.children[].data.url_overridden_by_dest // empty' \
  | xargs -I '{}' -P 5 youtube-dl '{}'

# add blur box, aspect ratio 16/9
for f in *.mp4; do 
  ffmpeg -n -hide_banner -i $f \
  -vf 'split[original][copy];[copy]scale=ih*16/9:-1,crop=h=iw*9/16,gblur=sigma=20[blurred];[blurred][original]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2' \
  -c:v libx264 -r 30 -preset fast blur/$f;
done

# Final render
printf "file '%s'\n" blur/*.mp4 > file_list.txt
ffmpeg -f concat -i file_list.txt -c:v libx264 -r 30 -preset fast rendered/$date.m4v

# cleanup
rm -f *.mp4 blur/*.mp4
