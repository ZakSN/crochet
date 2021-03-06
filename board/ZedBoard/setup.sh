#
# Support for ZedBoard and possibly other Xilinx Zynq-7000 platforms.
#
# Based on Thomas Skibo's information from
# http://www.thomasskibo.com/zedbsd/
#

KERNCONF=ZEDBOARD
ZYNQ_UBOOT_PORT="u-boot-zedboard"
ZYNQ_UBOOT_BIN="u-boot.img"
ZYNQ_UBOOT_PATH="/usr/local/share/u-boot/${ZYNQ_UBOOT_PORT}"
ZYNQ_DT_BASENAME=zedboard
IMAGE_SIZE=$((1280 * 1024 * 1024))	# 1.2 GB default
TARGET_ARCH=armv6

zynq_check_uboot ( ) {
    uboot_port_test ${ZYNQ_UBOOT_PORT} ${ZYNQ_UBOOT_BIN}
}
strategy_add $PHASE_CHECK zynq_check_uboot

# ZedBoard requires a FAT partition to hold the boot loader bits.
zedboard_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 64m 16 -1 -
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW zedboard_partition_image

zedboard_populate_boot_partition ( ) {
    # u-boot files
    cp ${ZYNQ_UBOOT_PATH}/boot.bin .
    cp ${ZYNQ_UBOOT_PATH}/u-boot.img .
    cp ${ZYNQ_UBOOT_PATH}/uEnv.txt .

    # ubldr
    freebsd_ubldr_copy_ubldr .
}
strategy_add $PHASE_BOOT_INSTALL zedboard_populate_boot_partition

zedboard_install_dts_ufs(){
    echo "Installing DTS to UFS"
    freebsd_install_fdt $ZYNQ_DT_BASENAME.dts boot/kernel/$ZYNQ_DT_BASENAME.dts
    freebsd_install_fdt $ZYNQ_DT_BASENAME.dts boot/kernel/board.dtb
}
strategy_add $PHASE_FREEBSD_BOARD_POST_INSTALL zedboard_install_dts_ufs

# Build and install ubldr from source
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos

# ubldr help file goes on the UFS partition (after boot dir is created)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot
