#!/bin/sh

BOARD_DIR="$(dirname $0)"

# cp -f ${BOARD_DIR}/grub.cfg ${TARGET_DIR}/boot/grub/grub.cfg
# Copy grub 1st stage to binaries, required for genimage
cp -f ${HOST_DIR}/lib/grub/i386-pc/boot.img ${BINARIES_DIR}

exit $?
