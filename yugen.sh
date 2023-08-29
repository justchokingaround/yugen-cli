#!/bin/sh

[ -z "$*" ] && printf '\033[1;35m=> ' && read -r user_query || user_query=$*
query=$(printf "%s" "$user_query" | tr " " "+")

choice=$(curl -s "https://yugenanime.tv/discover/?q=${query}" | sed -nE "s@.*href=\"([^\"]*)\" title=\"([^\"]*)\".*@\1\t\2@p" | fzf --with-nth 2..)
[ -z "$choice" ] && exit 1
anime_id=$(printf "%s" "$choice" | cut -f1)
anime_title=$(printf "%s" "$choice" | cut -f2)

tmp_episode_info=$(curl -s "https://yugenanime.tv${anime_id}watch/" | sed -nE "s@.*href=\"/([^\"]*)\" title=\"([^\"]*)\".*@\1\t\2@p" | fzf -1 --prompt "Choose an episode: " --with-nth 2..)
tmp_href=$(printf "%s" "$tmp_episode_info" | cut -f1)
ep_title=$(printf "%s" "$tmp_episode_info" | cut -f2)
yugen_id=$(curl -s "https://yugenanime.tv/$tmp_href" | sed -nE "s@.*id=\"main-embed\" src=\".*/e/([^/]*)/\".*@\1@p")
episode_info=$(printf "%s\t%s" "$yugen_id" "$ep_title")
[ -z "$episode_info" ] && exit 1

episode_id=$(printf "%s" "$episode_info" | cut -f1)
episode_title=$(printf "%s" "$episode_info" | cut -f2)
[ "$episode_id" = "$episode_title" ] && episode_title=""

json_data=$(curl -s 'https://yugenanime.tv/api/embed/' -X POST -H 'X-Requested-With: XMLHttpRequest' --data-raw "id=$episode_id&ac=0")
[ -z "$json_data" ] && exit 1

hls_link_1=$(printf "%s" "$json_data" | tr '{}' '\n' | sed -nE "s@.*\"hls\": \[\"([^\"]*)\".*@\1@p")
# hls_link_2=$(printf "%s" "$json_data" | tr '{}' '\n' | sed -nE "s@.*hls.*, \"([^\"]*)\".\]*@\1@p")
# gogo_link=$(printf "%s" "$json_data" | tr '{}' '\n' | sed -nE "s@.*\"src\": \"([^\"]*)\", \"type\": \"embed.*@\1@p")

[ -z "$video_link" ] && exit 1
mpv --force-media-title="$anime_title - Ep $episode_title" "$hls_link_1"
