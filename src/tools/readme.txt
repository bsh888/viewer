安装ImageMagick
tsocks wget https://imagemagick.org/download/ImageMagick.tar.gz
tsocks brew install ghostscript
./configure --with-modules --enable-shared --with-perl --enable-static --with-freetype=yes --with-modules --with-openjp2 --with-openexr --with-webp=yes --with-heic=yes --enable-openmp --with-gs-font-dir=/usr/local/Cellar/ghostscript/9.50/share/ghostscript/fonts --with-ghostscript --with-xml=/usr/local/opt/libxml2
ac_cv_prog_c_openmp=-Xpreprocessor\ -fopenmp
ac_cv_prog_cxx_openmp=-Xpreprocessor\ -fopenmp
LDFLAGS=-lomp
export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"
make
make install

安装微软雅黑字体：
mac: sudo cp -rp msyh.ttc /System/Library/Fonts