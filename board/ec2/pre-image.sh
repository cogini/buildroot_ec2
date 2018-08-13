#!/bin/sh

BOARD_DIR="$(dirname $0)"

cp -f ${BOARD_DIR}/grub.cfg ${TARGET_DIR}/boot/grub/grub.cfg

exit $?
