#!/bin/bash

#####################################################
## utilities for wallpaper generation on instantOS ##
#####################################################

RAW="https://raw.githubusercontent.com/instantOS/instantLOGO/master"

setupres() {
    if [ -e ~/instantos/monitor/max.txt ] && grep -q '....' ~/instantos/monitor/max.txt; then
        export RESOLUTION=$(head -1 ~/instantos/monitor/max.txt)
    else
        export RESOLUTION="1920x1080"
    fi
}

setupres
# resize an image using imagemagick
imgresize() {
    IMGRES=$(identify "$1" | grep -o '[0-9][0-9]*x[0-9][0-9]*' | sort -u | head -1)
    if [ $IMGRES = "$2" ]; then
        echo "image already resized"
        if [ -n "$3" ]; then
            if ! [ -e "$3" ]; then
                cp $1 $3
            fi
        fi
        return 0
    fi
    mv "$1" "${1%.*}.1.png"
    convert "${1%.*}.1.png" -alpha on -background none -gravity center -resize $2^ -gravity center -extent $2 ${3:-$1}
    rm "${1%.*}.1.png"
}

instantoverlay() {
    [ -e overlay.png ] ||
        wget -q "$RAW/wallpaper/overlay.png"
}

# bing daily photo
bingwallpaper() {
    wget -qO photo.jpg $(curl -s https://bing.biturl.top/ | grep -Eo 'www.bing.com/[^"]*(jpg|png)')
}

googlewallpaper() {
    if curl google.com &>/dev/null; then
        url='https://storage.googleapis.com/chromeos-wallpaper-public'

        fetch() {
            IFS='<' read -a array <<<"$(wget -O - -q "$url")"
            for field in "${array[@]}"; do
                if [[ "$field" == *_resolution.jpg ]]; then
                    IFS='>' read -a key <<<"$field"
                    printf "%s\n" "${key[1]}"
                fi
            done
        }

        wget -qO photo.jpg "$url/$(fetch | shuf -n 1)"
    fi
}

wallhaven() {
    WALLURL=$(curl -Ls 'https://wallhaven.cc/search?q=id%3A711&categories=111&purity=100&sorting=random&order=desc' |
        grep -o 'https://wallhaven.cc/w/[^"]*' | shuf | head -1)

    wget -qO photo.jpg $(curl -s $WALLURL | grep -o 'https://w.wallhaven.cc/full/.*/.*.jpg' | head -1)

}

wallist() {
    wget -qO photo.jpg $(curl -s 'https://raw.githubusercontent.com/instantOS/instantWALLPAPER/master/list.txt' | shuf | head -1)
}

viviwall() {
    LINK=$(curl -s https://github.com/instantOS/wallpapers/tree/master/wallpapers | grep -o 'wall[0-9]*\.jpg' | sort -u | shuf | head -1)
    wget -qO photo.jpg "$LINK"
}

# default mono colored logo wallpaper
defaultwall() {
    instantoverlay
    imgresize overlay.png $RESOLUTION
    convert overlay.png -fill "$(instantforeground)" -colorize 100 color.png
    convert color.png -background "$(instantbackground)" -alpha remove -alpha off "$(getinstanttheme)".png
    rm color.png

}

# put the logo onto a wallpaper
compwallpaper() {

    instantoverlay
    echo "RESOLUTION $RESOLUTION"
    imgresize ${1:-photo.jpg} $RESOLUTION wall.png
    imgresize overlay.png $RESOLUTION

    convert wall.png -channel RGB -negate invert.png
    convert overlay.png invert.png -compose Multiply -composite out.png
    composite out.png wall.png instantwallpaper.png
    rm wall.png
    rm invert.png
    rm out.png
}
