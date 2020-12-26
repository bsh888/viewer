# viewer

#### 介绍
随着移动设备拍照、录制视频越来越多，设备空间不足，需要定时备份出来，那么问题来了：存储到大硬盘里，如何能快速地、随时随地查看呢？
最好能同时在任何设备，如手机、平板、电视上都可以浏览，本应用完美的解决了这些痛点，欢迎下载使用

#### 实现思路

1.  通过 ImageMagick 处理图片，从原图中处理出缩略图，并在缩略图右下角写上设备名称及日期，缩略图、原图都按：年月/年月日_时分秒存储
2.  通过 FFmpeg 将视频第一帧提取出来，也按照缩略图的处理方式保存下来，作为快速定位到视频的索引图
3.  用 Golang 编写服务端程序，把缩略图地址存储到 Sqlite ，提供查询 Api 接口，给前端程序调用
4.  用 Vue 实现前端 H5 程序，实现缩略图预览，对于图片，点击展示原图，对于视频，点击播放原视频
5.  将家庭成员手机里的图片、视频存入一个很大的移动硬盘里，运行处理脚本，启动后端程序，借助家里的 WIFI 网络，可以在各个设备的浏览器查看

#### 效果图

##### 手机端访问效果：
<img src="https://github.com/bsh888/viewer/blob/master/assets/mobile-1.jpeg" width="410px">
<img src="https://github.com/bsh888/viewer/blob/master/assets/mobile-2.jpeg" width="410px">

##### Pad端访问效果：
<img src="https://github.com/bsh888/viewer/blob/master/assets/pad-1.jpeg" width="270px">
<img src="https://github.com/bsh888/viewer/blob/master/assets/pad-2.jpeg" width="270px">
<img src="https://github.com/bsh888/viewer/blob/master/assets/pad-3.jpeg" width="270px">

##### 程序说明：
<img src="https://github.com/bsh888/viewer/blob/master/assets/pro-dir.png" width="410px">
<img src="https://github.com/bsh888/viewer/blob/master/assets/run.png" width="410px">
<img src="https://github.com/bsh888/viewer/blob/master/assets/yingpan-dir.png" width="410px">
<img src="https://github.com/bsh888/viewer/blob/master/assets/yingpan.jpeg" width="410px">

#### 安装及使用教程

1.  本安装仅限于采用编译后的可执行程序，适用于小白用户，深度用户可以编译源码，设置修改源码安装。[可执行程序下载地址](https://pan.baidu.com/s/1VQ0d8__OCu6dc1ZkIameTg) 提取码: eufq
2.  ##### Mac 用户安装 ImageMagick-7.0.8-mac.gz、ffmpeg-4.1-mac.zip 解压缩后设置环境变量：
    ```bash
    # ImageMagick:  
    export MAGICK_HOME="/server/ImageMagick-7.0.8"  
    export PATH="$MAGICK_HOME/bin:$PATH"  
    export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib/" 

    # FFmpeg:  
    export FFMPEG_HOME="/server/ffmpeg-4.1"  
    export PATH="$FFMPEG_HOME:$PATH"
    ```
    #####  Windows 用户安装 ImageMagick-7.0.8-27-Q16-x64-dll.exe、ffmpeg-4.1-win64-static.zip FFmpeg需要设置环境变量：
    a.  点击屏幕底部菜单栏中的“计算机”图标  
    b.  在弹出的窗口中点击顶部的“计算机”标签，然后在出现的菜单中点击“系统属性”选项  
    c.  在新的页面中，点击左侧导航栏中的“高级系统设置”  
    d.  在弹出的页面中， 点击下部的“环境变量”按钮。弹出环境变量的管理页面  
    e.  在环境变量的管理页面中，在下部列表框中找到Path变量， 单击选中， 然后点击下面的“编辑”按钮  
    f.  弹出的页面有两个输入框，在“变量值”输入框的开头添加你要增加的路径，格式为;全路径，即分号加路径：
    ```bash
    C:\ffmpeg-4.1-win64-static\bin;C:\Program Files....  
    ```
3.  非 Windows 系统需要安装微软雅黑字体，只需要复制 viewer/tools/msyh.ttc 到字体目录，如 Mac 系统是：/System/Library/Fonts/msyh.ttc ，修改 viewer/tools/deal_pic_video.sh 中的 FONT_MSYH 值即可
4.  复制手机中的图片视频目录到移动端硬盘中，复制 Mac、Linux用户复制 viewer/tools/deal_pic_video.sh 文件，Windows 用户复制 viewer/tools/deal_pic_video.bat 文件，和图片视频目录平级，Mac、Linux用户执行：
```bash
./deal_pic_video.sh
```
Windows 用户双击deal_pic_video.bat 运行。最终会生成 dealpics、dealvideos、sourcepics、sourcevideos 四个目录，**注意：脚本可以重复执行，文件不会被重复处理。**
5.  将 viewer/viewer 目录复制到移动硬盘中，和 dealpics、dealvideos、sourcepics、sourcevideos 四个目录平级，
Mac、Linux用户进入 viewer/viewer/bin 目录执行：
```bash
./viewer-mac
```
Windows 用户调出 CMD 窗口，进入 viewer/viewer/bin 目录执行：
```bash
./viewer.exe
```
6.  说明：后端配置文件路径：viewer/viewer/bin/config.yaml 可以修改运行端口：port: 8081 ，其他的不建议修改；前端配置文件路径：viewer/viewer/static/config.js **需要修改一下 IP 地址 apiHost: 'http://{IP}:8081/' ，这个 IP 是第五步运行服务时输出的“访问地址:”中的IP，本例为：192.168.3.101**
7.  然后家中的所有设备，只要有浏览器应用的都可以访问，如本例：  
a.  初始化数据库表，浏览器输入：http://192.168.3.101:8081/db/table  
b.  初始化数据，浏览器输入：http://192.168.3.101:8081/db/data 
c.  在浏览器输入： http://192.168.3.101:8081/viewer/ 即可浏览移动端硬盘中所有图片及视频

#### 深度用户使用

1.  前端构建：
```bash
cd src/frontend
npm i
cd ..
make dev
```
2.  后端构建：
```bash
cd src
make mac
```
3.  浏览器访问：http://localhost:8080
4.  交叉编译：
```bash
docker pull karalabe/xgo-latest
go get github.com/karalabe/xgo
make mac
make amd
make arm
make win
```
