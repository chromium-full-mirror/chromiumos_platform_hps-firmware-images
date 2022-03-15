#!/usr/bin/env bash

set -euo pipefail
# set -x

MILESTONE="$1"
VERSION="$2"

ROOT_DIR=$(git rev-parse --show-toplevel)

mkdir -p "$ROOT_DIR/firmware-signed/$MILESTONE-$VERSION"
cd "$ROOT_DIR/firmware-signed/$MILESTONE-$VERSION"

GSUTIL_ROOT="gs://chromeos-releases/canary-channel/brya/$VERSION"
gsutil.py cp \
    "$GSUTIL_ROOT/chromeos_${VERSION}_brya_hps_firmware_canary-channel_hps-accessory-mp.bin" \
    mcu_stage1.bin
gsutil.py cp \
    "$GSUTIL_ROOT/ChromeOS-hps_firmware-$MILESTONE-$VERSION-brya.tar.bz2" \
    .

tar --strip-components=1 -xvf \
    "ChromeOS-hps_firmware-$MILESTONE-$VERSION-brya.tar.bz2" \
    hps/fpga_bitstream.bin hps/fpga_application.bin

cp mcu_stage1.bin fpga_bitstream.bin fpga_application.bin ..
cd ..

git add mcu_stage1.bin fpga_bitstream.bin fpga_application.bin
git commit -m "Update signed binaries from $MILESTONE-$VERSION

BUG=b:204378599
TEST=None
"

echo "Reminder to test these files:"
echo "scp mcu_stage1.bin fpga_bitstream.bin fpga_application.bin dut:/usr/lib/firmware/hps/"
echo "ssh dut stop hpsd \; start hpsd"
echo "ssh dut tail -f /var/log/messages \| grep hps"
