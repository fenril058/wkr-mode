#!/bin/sh
file="$@"
# echo $file
winpath=`/usr/bin/wslpath -w -a "$file"`
HOST=`hostname`
win_python="uv.exe run --with pywin32"
win_python_script='C:\Users\outlook.py'

if
    $win_python $win_python_script "$winpath"
then
    echo "succeed! attatch $winpath"
else
    echo "fail! something wrong."
fi
