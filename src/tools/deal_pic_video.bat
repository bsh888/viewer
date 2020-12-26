::function  deal pictures
::author    bishenghua
::email     net.bsh@gmail.com
::date      2013/07/05
::mdate     2019/02/13

@echo off & setlocal EnableDelayedExpansion

:::修改注册表，解决“UNC 路径不受支持”问题
reg add "HKEY_CURRENT_USER\Software\Microsoft\Command Processor" /v "DisableUNCCheck" /t "REG_DWORD" /d "1" /f

set FONT_MSYH="c:\windows\fonts\msyh.ttc"

where convert > nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo Please install ImageMagick
  pause&goto:eof
)

where ffprobe > nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo Please install Ffmpeg
  pause&goto:eof
)

set sourcePicDir=sourcepics
set sourceVideoDir=sourcevideos
set imageDir=dealpics
set videoDir=dealvideos
set dealSuffixSet=-Do
set execPath="%~dp0"
set setPicSize=1080x540
set setVideoSize=1280x720

if not exist %sourcePicDir% md %sourcePicDir%
if not exist %sourceVideoDir% md %sourceVideoDir%
if not exist %imageDir% md %imageDir%
if not exist %videoDir% md %videoDir%


for /r %%f in (*.jpg, *.jpeg, *.png, *.heic, *.mp4, *.mov, *.avi) do (
  set filePath=%%f
  set fileExt=%%~xf
  if "!fileExt!" == ".mp4" (
    call:deal_videos !filePath! !fileExt!
  ) else (
    if "!fileExt!" == ".MP4" (
      call:deal_videos !filePath! !fileExt!
    ) else (
      if "!fileExt!" == ".mov" (
        call:deal_videos !filePath! !fileExt!
      ) else (
        if "!fileExt!" == ".MOV" (
          call:deal_videos !filePath! !fileExt!
        ) else (
          if "!fileExt!" == ".avi" (
            call:deal_videos !filePath! !fileExt!
          ) else (
            if "!fileExt!" == ".AVI" (
              call:deal_videos !filePath! !fileExt!
            ) else (
              call:deal_pics !filePath! !fileExt!
            )
          )
        )
      )
    )
  )
)
pause

:deal_pics
  set createDate=
  set orientation=
  set model=
  set make=
  set fileName=%1
  set filePath=%1
  set fileExt=%2
  set width=
  set height=
  set dateFileName=
  set yearMonth=
  set dealSuffix=%dealSuffixSet%

  if "!filePath:%dealSuffix%=!" == "!filePath!" (
    for /f "tokens=1,2,3 delims= " %%i in ('identify -verbose "!filePath!"') do (
        if "%%i" == "exif:DateTimeOriginal:" (
          set nyr=%%j
          set dateFileName=!nyr::=!
          set nyr=!nyr::=/!
          set r=%%k
          set yearMonth=!dateFileName:~0,6!
          set createDate=!nyr! !r:~0,5!
          set dateFileName=!dateFileName!_!r::=!
        ) else (
          if "%%i" == "date:modify:" (
            for /f %%m in ('powershell -Command "Get-Date -date %%j -format yyyyMM"') do set yearMonth=%%m
            for /f %%m in ('powershell -Command "Get-Date -date %%j -format yyyy/MM/dd-HH:mm"') do set createDate=%%m
            set createDate=!createDate:-= !
            for /f %%m in ('powershell -Command "Get-Date -date %%j -format yyyyMMdd_HHmmss"') do set dateFileName=%%m
          )
        )

        if "%%i" == "Image:" (
          set fileName=%%j
        )

        if "%%i" == "Orientation:" (
          set orientation=%%j
        )

        if "%%i" == "exif:Make:" (
          set make=%%j
          set dateFileName=!dateFileName!_!make!
        )

        if "%%i" == "exif:Model:" (
          if "%%k" == "" (
            set model=%%j
          ) else (
            set model=%%j-%%k
          )
          set dateFileName=!dateFileName!_!model!
        )

        if "%%i" == "exif:ImageWidth:" (
          set width=%%j
        )

        if "%%i" == "exif:ImageLength:" (
          set height=%%j
        )

        if "%%i" == "exif:PixelXDimension:" (
          set width=%%j
        )

        if "%%i" == "exif:PixelYDimension:" (
          set height=%%j
        )
    )

    for %%m in (!filePath!) do set fileName=%%~nxm

    if "!model!"=="GT-I9082i" (
      set size=!width!x!height!
    ) else (
      set size=!width!x!height!
    )
    set size=!setPicSize!

    set text=!make! !model! !createDate!

    if not defined createDate (
      echo fileName:'!fileName!' filePath:'!filePath!' CON NOT BE DEALED!
      goto:eof
    )

    set outDealPath=%imageDir%\!yearMonth!
    set outSourcePath=%sourcePicDir%\!yearMonth!

    if not exist !outDealPath! md !outDealPath!
    if not exist !outSourcePath! md !outSourcePath!

    set dealSuffix=%dealSuffix%.jpg

    set outFile=!outDealPath!\!dateFileName!!dealSuffix!

    set filePathPre=!filePath:~0,-5!
    if "!fileExt!" == ".HEIC" (
      mogrify -format jpg "!filePath!"
      del /f /q "!filePath!"
      set filePath="!filePathPre!.jpg"
    ) else (
      if "!fileExt!" == ".heic" (
        mogrify -format jpg "!filePath!"
        del /f /q "!filePath!"
        set filePath="!filePathPre!.jpg"
      )
    )

    if "!orientation!" == "Undefined" (
      convert !filePath! -font !FONT_MSYH! -quality 100 -resize !size! ^( -background "#0005" -fill white -pointsize 16 label:" !text! " -splice 5x5 ^) -gravity southeast -geometry +0+0 -composite +profile "*" !outFile!
    ) else (
        if "!orientation!" == "TopLeft" (
          convert !filePath! -font !FONT_MSYH! -quality 100 -resize !size! ^( -background "#0005" -fill white -pointsize 16 label:" !text! " -splice 5x5 ^) -gravity southeast -geometry +0+0 -composite +profile "*" !outFile!
        ) else (
            if "!orientation!" == "RightTop" (
              convert !filePath! -font !FONT_MSYH! -quality 100 -resize !size! ^( -background "#0005" -fill white -pointsize 16 -rotate -90 label:" !text! " -splice 5x5 ^) -rotate 90 -gravity southeast -geometry +0+0 -composite +profile "*" !outFile!
            )
        )
    )
    
    rem del /f /q !filePath!
    move "!filePath!" "%execPath%!outSourcePath!\!dateFileName!!dealSuffix!" > nul
    echo fileName:'!fileName!-^>!dateFileName!!dealSuffix!' fileDate:'!createDate!' orientation:'!orientation!' resize:'!size!' model:'!model!'
  )
goto:eof

:deal_videos
  set filePath=%1
  set createDate=
  set dateFileName=
  set yearMonth=
  set dealSuffix=%dealSuffixSet%
  set videoSize=

  if "!filePath:%dealSuffix%=!" == "!filePath!" (
    for /f "tokens=1,2,3 delims==" %%i in ('ffprobe -v quiet -show_format "!filePath!"') do (
      if "%%i" == "size" (
        set videoSize=%%j
      )
      if "%%i" == "TAG:creation_time" (
        rem for /f "tokens=1 delims=." %%a in ("%%j") do set createDate=%%a
        set createDate=%%j
      )
    )

    for %%m in (!filePath!) do set fileName=%%~nxm

    if not defined createDate (
      echo fileName:'!fileName!' filePath:'!filePath!' CON NOT BE DEALED!
      goto:eof
    )

    rem yyyy-MM-dd HH:mm:ss
    for /f %%i in ('powershell -Command "Get-Date -date !createDate! -format yyyyMM"') do set yearMonth=%%i
    set outDealPath=%videoDir%\!yearMonth!
    set outSourcePath=%sourceVideoDir%\!yearMonth!
    for /f %%i in ('powershell -Command "Get-Date -date !createDate! -format yyyyMMdd_HHmmss"') do set dateFileName=%%i
    for /f "tokens=1,2 delims==" %%i in ('powershell -Command "Get-Date -date !createDate! -format 'yyyy/MM/dd HH:mm'"') do set createDate=%%i %%j
    set createDate=!createDate:~0,-1!
    rem (1080P=1920x1080 720p=1280x720 480p=720x480 360p=480x360 240p=320x240)
    set size=setVideoSize
    set scale=scale=iw*0.6:ih*0.6

    set _dealSuffix=%dealSuffix%
    set dealSuffix=!_dealSuffix!.mp4
    set dealSuffixJpg=!_dealSuffix!.jpg

    set outFile=!outDealPath!\!dateFileName!!dealSuffix!
    set outFileJpg=!outDealPath!\!dateFileName!!dealSuffixJpg!

    if not exist !outDealPath! md !outDealPath!
    if not exist !outSourcePath! md !outSourcePath!

    rem 提取视频图片，处理成小图，作为浏览的索引图
    set firstPic=first-!fileName!!dealSuffixSet!.jpg
    ffmpeg -y -v error -stats -i !filePath! -r 1 -vframes 1 -q:v 2 -f image2 !firstPic!
    if %ERRORLEVEL% equ 0 (
      set orientation=
      for /f "tokens=1,2,3 delims= " %%i in ('identify -verbose "!firstPic!"') do (
        if "%%i" == "Orientation:" (
          set orientation=%%j
        )
      )
      set videoSize=!videoSize!/1024/1024
      set videoSize=SIZE:!videoSize!M
      set text=!videoSize! !createDate!
      if "!orientation!" == "Undefined" (
        convert !firstPic! -font !FONT_MSYH! -quality 100 -resize !size! ^( -background "#0005" -fill white -pointsize 16 label:" !text! " -splice 5x5 ^) -gravity southeast -geometry +0+0 -composite +profile "*" !outFileJpg!
      ) else (
          if "!orientation!" == "TopLeft" (
            convert !firstPic! -font !FONT_MSYH! -quality 100 -resize !size! ^( -background "#0005" -fill white -pointsize 16 label:" !text! " -splice 5x5 ^) -gravity southeast -geometry +0+0 -composite +profile "*" !outFileJpg!
          ) else (
              if "!orientation!" == "RightTop" (
                convert !firstPic! -font !FONT_MSYH! -quality 100 -resize !size! ^( -background "#0005" -fill white -pointsize 16 -rotate -90 label:" !text! " -splice 5x5 ^) -rotate 90 -gravity southeast -geometry +0+0 -composite +profile "*" !outFileJpg!
              )
          )
      )
      del /f /q "!firstPic!"
    )

    rem ffmpeg -y -v error -stats -i !filePath! -s !size! !outFile!
    rem 因为压缩小视频太消耗资源，暂时不处理
    rem ffmpeg -y -v error -stats -i !filePath! -vf !scale! !outFile!
    rem if %ERRORLEVEL% equ 0 (
      move "!filePath!" "%execPath%\!outSourcePath!\!dateFileName!!dealSuffix!" > nul
      rem echo fileName:'!fileName!-^>!dateFileName!!dealSuffix!' dealTo:'720p=!size!'
      echo fileName:'!fileName!-^>!dateFileName!!dealSuffix!' dealTo:'!scale!'
    rem )
  )
goto:eof

:: del /f /s /q %%f