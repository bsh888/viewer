#!/bin/bash

: << !
function  deal pictures
author    bishenghua
email     net.bsh@gmail.com
date      2019/02/13
!

convertBin=`which convert`
if [ $? -ne 0 ]; then
    echo "Please install ImageMagick"
    exit
fi
export FONT_MSYH="/System/Library/Fonts/msyh.ttc"
export MAGICK_HOME="$(dirname $(dirname "$convertBin"))"
# export PATH="$MAGICK_HOME/bin:$PATH"
# export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib"

if [ ! -f $FONT_MSYH ]; then
    echo "Please install msyh.ttc"
    exit
fi

ffmpegBin=`which ffprobe`
if [ $? -ne 0 ]; then
    echo "Please install Ffmpeg"
    exit
fi
export FFMPEG_HOME="$(dirname "$ffmpegBin")"
export PATH="$FFMPEG_HOME:$PATH"

_IFS=$IFS
sourcePicDir=sourcepics
sourceVideoDir=sourcevideos
imageDir=dealpics
videoDir=dealvideos
dealSuffixSet=-Do
execPath=$(cd `dirname $0`; pwd)
setPicSize=1080x540
setVideoSize=1280x720

if [ ! -d "$sourcePicDir" ]; then
    mkdir $sourcePicDir
fi
if [ ! -d "$sourceVideoDir" ]; then
    mkdir $sourceVideoDir
fi
if [ ! -d "$imageDir" ]; then
    mkdir $imageDir
fi
if [ ! -d "$videoDir" ]; then
    mkdir $videoDir
fi

# function getUTCDateSecondOffset {
#     # Linux or BSD date?
#     set +e
#     date -v 0S >/dev/null 2>&1
#     retVal=$?
#     set -e

#     if [[ $retVal -eq 0 ]]; then
#         # BSD date
#         date \
#             -jf "%Y-%m-%dT%H:%M:%S %z" \
#             -v "${2}S" \
#             "${1} +0000" \
#             "+%Y%m%d%H%M.%S"

#     else
#         # Linux date
#         date --date "${1} +0000 ${2} seconds" "+%Y%m%d%H%M.%S"
#     fi
# }
# getUTCDateSecondOffset "2016-04-11T03:26:02" "-20"

function formatUTCDate {
    # Linux or BSD date?
    set +e
    date -v 0S >/dev/null 2>&1
    retVal=$?
    set -e

    if [[ $retVal -eq 0 ]]; then
        # BSD date
        date \
            -jf "%Y-%m-%dT%H:%M:%S %z" \
            "${1} +0000" \
            "${2}"

    else
        # Linux date
        date --date "${1} +0000" "${2}"
    fi
}

function formatCSTDate {
    # Linux or BSD date?
    set +e
    date -v 0S >/dev/null 2>&1
    retVal=$?
    set -e

    if [[ $retVal -eq 0 ]]; then
        # BSD date
        date \
            -jf "%Y-%m-%dT%H:%M:%S %z" \
            "${1} +0800" \
            "${2}"

    else
        # Linux date
        date --date "${1} +0800" "${2}"
    fi
}

function deal_pics() {
    fileExt=$3
    fileName=$2
    filePath=$1"/"$fileName
    createDate=
    orientation=
    model=
    make=
    width=
    height=
    dateFileName=
    yearMonth=
    dealSuffix=$dealSuffixSet

    if [[ $fileName =~ "$dealSuffix" ]]; then
        continue
    fi

    while read line; do
        # echo $line
        if [[ $line =~ "exif:DateTimeOriginal:" ]]; then
            IFS=' ' exif=(${line})
            dateFileName=${exif[1]//:/}
            yearMonth=${dateFileName:0:6}
            createDate="${exif[1]//://} ${exif[2]:0:5}"
            dateFileName=${dateFileName}_${exif[2]//:/}
            IFS=$_IFS
        elif [[ $line =~ "date:modify:" ]]; then
            IFS=' ' exif=(${line})
            dateFileName=${exif[1]%+*}
            yearMonth=$(formatCSTDate "$dateFileName" "+%Y%m")
            createDate=$(formatCSTDate "$dateFileName" "+%Y/%m/%d %H:%M")
            dateFileName=$(formatCSTDate "$dateFileName" "+%Y%m%d_%H%M%S")
            IFS=$_IFS
        fi

        if [[ $line =~ "Image:" ]]; then
            IFS=' ' exif=(${line})
            fileName=${exif[1]}
            IFS=$_IFS
        fi

        if [[ $line =~ "Orientation:" && ${line/exif://} == $line ]]; then
            IFS=' ' exif=(${line})
            orientation=${exif[1]}
            IFS=$_IFS
        fi

        if [[ $line =~ "exif:Make:" ]]; then
            IFS=' ' exif=(${line})
            make=${exif[1]}
            dateFileName=${dateFileName}_${make}
            IFS=$_IFS
        fi

        if [[ $line =~ "exif:Model:" ]]; then
            IFS=' ' exif=(${line})
            if [[ ${exif[2]} == "" ]]; then
                model=${exif[1]}
            else
                model="${exif[1]}-${exif[2]}"
            fi
            dateFileName=${dateFileName}_${model}
            IFS=$_IFS
        fi

        if [[ $line =~ "exif:ImageWidth:" ]]; then
            IFS=' ' exif=(${line})
            width=${exif[1]}
            IFS=$_IFS
        fi

        if [[ $line =~ "exif:ImageLength:" ]]; then
            IFS=' ' exif=(${line})
            height=${exif[1]}
            IFS=$_IFS
        fi

        if [[ $line =~ "exif:PixelXDimension:" ]]; then
            IFS=' ' exif=(${line})
            width=${exif[1]}
            IFS=$_IFS
        fi

        if [[ $line =~ "exif:PixelYDimension:" ]]; then
            IFS=' ' exif=(${line})
            height=${exif[1]}
            IFS=$_IFS
        fi


    done << EOF
    "`identify -verbose $filePath`"
EOF

    if [[ $model == "GT-I9082i" ]]; then
        size=$widthx$height
    else
        size=$widthx$height
    fi
    size=$setPicSize

    text="$make $model $createDate"

    fileName=${fileName##*/}

    if [[ $createDate == "" ]]; then
        echo "fileName:'$fileName' filePath:'$filePath' CON NOT BE DEALED!"
    else
        outDealPath=$imageDir/$yearMonth
        outSourcePath=$sourcePicDir/$yearMonth

        if [ ! -d "$outDealPath" ]; then
            mkdir $outDealPath
        fi
        if [ ! -d "$outSourcePath" ]; then
            mkdir $outSourcePath
        fi

        dealSuffix=${dealSuffix}.jpg

        outFile=$outDealPath/$dateFileName$dealSuffix

        if [[ $fileExt == "heic" || $fileExt == "HEIC" ]]; then
            filePathPre=${filePath%.*}
            mogrify -format jpg "$filePath"
            rm -rf "$filePath"
            filePath="${filePathPre}.jpg"
        fi

        if [[ $orientation == "Undefined" ]]; then
            convert $filePath -font $FONT_MSYH -quality 100 -resize $size \( -background "#0005" -fill white -pointsize 16 label:" $text " -splice 5x5 \) -gravity southeast -geometry +0+0 -composite +profile "*" $outFile
        else
            if [[ $orientation == "TopLeft" ]]; then
                convert $filePath -font $FONT_MSYH -quality 100 -resize $size \( -background "#0005" -fill white -pointsize 16 label:" $text " -splice 5x5 \) -gravity southeast -geometry +0+0 -composite +profile "*" $outFile
            else
                if [[ $orientation == "RightTop" ]]; then
                    convert $filePath -font $FONT_MSYH -quality 100 -resize $size \( -background "#0005" -fill white -pointsize 16 -rotate -90 label:" $text " -splice 5x5 \) -rotate 90 -gravity southeast -geometry +0+0 -composite +profile "*" $outFile
                fi
            fi
        fi
        
        # rm -rf $filePath
        mv "$filePath" "$execPath/$outSourcePath/$dateFileName$dealSuffix"
        echo "fileName:'$fileName->$dateFileName$dealSuffix' fileDate:'$createDate' orientation:'$orientation' resize:'$size' model:'$model'"
    fi
}

function deal_videos() {
    fileExt=$3
    fileName=$2
    filePath=$1"/"$fileName
    createDate=
    dateFileName=
    yearMonth=
    dealSuffix=$dealSuffixSet
    videoSize=

    if [[ $fileName =~ "$dealSuffix" ]]; then
        continue
    fi

    info=$(ffprobe -v quiet -show_format $filePath 2>&1)
    if [[ $? -ne 0 ]]; then
        echo $info "(可能是DYLD_LIBRARY_PATH环境变量的问题 $filePath)"
        continue
    fi
    while read line; do
        if [[ $line =~ "size" ]]; then
            IFS='=' exif=(${line})
            videoSize=${exif[1]}
            IFS=$_IFS
        fi
        if [[ $line =~ "TAG:creation_time" ]]; then
            IFS='=' exif=(${line})
            createDate=${exif[1]}
            IFS=$_IFS
        elif [[ $line =~ "creationDate" ]]; then
            createDate=`echo "$line" | grep creationDate | awk -F '":"' '{print $2}' | awk -F '","' '{print $1}'`
        fi
    done << EOF
    "$info"
EOF

    fileName=${fileName##*/}

    if [[ $createDate == "" ]]; then
        echo "fileName:'$fileName' filePath:'$filePath' CON NOT BE DEALED!"
    else
        createDate=${createDate%.*}
        yearMonth=$(formatUTCDate "$createDate" "+%Y%m")
        outDealPath=$videoDir/$yearMonth
        outSourcePath=$sourceVideoDir/$yearMonth
        dateFileName=$(formatUTCDate "$createDate" "+%Y%m%d_%H%M%S")
        createDate=$(formatUTCDate "$createDate" "+%Y/%m/%d %H:%M")
        size=$setVideoSize #(1080P=1920x1080 720p=1280x720 480p=720x480 360p=480x360 240p=320x240)
        scale="'scale=iw*0.6:ih*0.6'"

        _dealSuffix=$dealSuffix
        dealSuffix=${_dealSuffix}.mp4
        dealSuffixJpg=${_dealSuffix}.jpg

        outFile=$outDealPath/$dateFileName$dealSuffix
        outFileJpg=$outDealPath/$dateFileName$dealSuffixJpg

        if [ ! -d "$outDealPath" ]; then
            mkdir $outDealPath
        fi
        if [ ! -d "$outSourcePath" ]; then
            mkdir $outSourcePath
        fi

        # 提取视频图片，处理成小图，作为浏览的索引图
        firstPic=first-${fileName}${dealSuffixSet}.jpg
        ffmpeg -y -v error -stats -i $filePath -r 1 -vframes 1 -q:v 2 -f image2 $firstPic
        if [[ $? -eq 0 ]]; then
            orientation=
            while read line; do
                # echo $line
                if [[ $line =~ "Orientation:" && ${line/exif://} == $line ]]; then
                    IFS=' ' exif=(${line})
                    orientation=${exif[1]}
                    IFS=$_IFS
                fi
            done << EOF
            "`identify -verbose $firstPic`"
EOF
            videoSize=SIZE:$(awk 'BEGIN{printf "%.1f",('$videoSize/1024/1024')}')M
            text="$videoSize $createDate"
            if [[ $orientation == "Undefined" ]]; then
                convert $firstPic -font $FONT_MSYH -quality 100 -resize $size \( -background "#0005" -fill white -pointsize 16 label:" $text " -splice 5x5 \) -gravity southeast -geometry +0+0 -composite +profile "*" $outFileJpg
            else
                if [[ $orientation == "TopLeft" ]]; then
                    convert $firstPic -font $FONT_MSYH -quality 100 -resize $size \( -background "#0005" -fill white -pointsize 16 label:" $text " -splice 5x5 \) -gravity southeast -geometry +0+0 -composite +profile "*" $outFileJpg
                else
                    if [[ $orientation == "RightTop" ]]; then
                        convert $firstPic -font $FONT_MSYH -quality 100 -resize $size \( -background "#0005" -fill white -pointsize 16 -rotate -90 label:" $text " -splice 5x5 \) -rotate 90 -gravity southeast -geometry +0+0 -composite +profile "*" $outFileJpg
                    fi
                fi
            fi
            rm -rf $firstPic
        fi

        # ffmpeg -y -v error -stats -i $filePath -s $size $outFile
        # 因为压缩小视频太消耗资源，暂时不处理
        # ffmpeg -y -v error -stats -i $filePath -vf "'$scale'" $outFile
        # if [[ $? -eq 0 ]]; then
            mv "$filePath" "$execPath/$outSourcePath/$dateFileName$dealSuffix"
            # echo "fileName:'$fileName->$dateFileName$dealSuffix' dealTo:'720p=$size'"
            echo "fileName:'$fileName->$dateFileName$dealSuffix' dealTo:$scale"
        # fi
    fi
}

function read_dir() {
    for fileNameSrc in `ls $1`; do
        if [ -d $1"/"$fileNameSrc ]; then
            read_dir $1"/"$fileNameSrc
        else
            fileExt=${fileNameSrc##*.}
            if [[ "$fileExt" == "jpg" || "$fileExt" == "JPG" || "$fileExt" == "jpeg" || "$fileExt" == "JPEG" || "$fileExt" == "png" || "$fileExt" == "PNG" || "$fileExt" == "heic" || "$fileExt" == "HEIC" ]]; then
                deal_pics $1 $fileNameSrc $fileExt
            fi
            if [[ "$fileExt" == "mp4" || "$fileExt" == "MP4" || "$fileExt" == "mov" || "$fileExt" == "MOV" || "$fileExt" == "avi" || "$fileExt" == "AVI" ]]; then
                deal_videos $1 $fileNameSrc $fileExt
            fi
        fi
    done
}   

# loop dir
read_dir .
