cd ../..
./makeall clean
./makeall
cd sample/test
make clean && make && cp kernel8-rpi4.img /mnt/c/temp/circle.img
