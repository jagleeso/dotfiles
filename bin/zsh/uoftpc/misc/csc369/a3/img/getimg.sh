#!/usr/bin/env bash
for f in \
    deleteddirectory.img \
    deletedfile.img \
    emptiesydisk.img \
    hardlink.img \
    largefile.img \
    onedirectory.img \
    onefile.img \
    twolevel.img; 
do
    wget http://www.cdf.toronto.edu/~csc369h/winter/assignments/a3/images/$f;
done
