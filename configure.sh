#!/bin/sh
set -e

unset cflags
buildtype=native

usage () {
    echo "$1"
    cat 1>&2 <<EOF
usage: $0 [-F] [-b build-type] [mudir]
options:
 -F: use fontconfig
 -b: MuPDF's build type [default native]

 build-type = debug|release|native
 mudir      = path to MuPDF's git checkout
EOF
    exit $2
}

while getopts eFb: opt; do
    case $opt in
        F) fontconfig=true; cflags="$cflags -DUSE_FONTCONFIG";;
        b) buildtype="$OPTARG";;
        ?) usage "" 0;;
    esac
done
shift $((OPTIND - 1))

mupdf="$1"
test -e "$mupdf" || usage "Don't know where to find MuPDF's git checkout" 1

pkgs="freetype2 zlib openssl" # j(peg|big2dec)?
test $fontconfig && pkgs="$pkgs fontconfig" || true
pwd=$(pwd -P)

expr >/dev/null "$0" : "/.*" && {
    path="$0"
    builddir="$pwd"
    helpcmdl=" -f $(dirname $path)/build.ninja"
} || {
    path="$pwd/$0"
    builddir="build"
    helcmdl=""
    mkdir -p $builddir
}
builddir=$(cd $builddir >/dev/null $builddir && pwd -P)

libs="$(pkg-config --libs $pkgs) -ljpeg -ljbig2dec -lopenjpeg"

(cat <<EOF
cflags=$cflags $(pkg-config --cflags $pkgs)
lflags=$libs
srcdir=$(cd >/dev/null $(dirname $0) && pwd -P)
buildtype=$buildtype
mupdf=$mupdf
builddir=$builddir
EOF
 test $(uname -m) = "x86_64" && {
     echo 'cflags=$cflags -fPIC'
     echo "mujs=-lmujs"
 }) >.config || true

cat <<EOF
Configuration results are saved in $(pwd -P)/.config
To build - type: ninja$helpcmdl
EOF