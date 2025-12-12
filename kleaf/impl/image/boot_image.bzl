# Copyright (C) 2025 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
Rules for building a boot image.
"""

load(":common_providers.bzl", "KernelBuildInfo", "KernelSerializedEnvInfo")
load(":image/boot_images.bzl", "build_boot_or_vendor_boot")

visibility("//build/kernel/kleaf/...")

def _boot_image_impl(ctx):
    return build_boot_or_vendor_boot(
        bin_dir = ctx.bin_dir,
        kernel_build = ctx.attr.kernel_build,
        initramfs = None,
        deps = ctx.attr.deps,
        outs = ctx.attr.outs,
        mkbootimg = ctx.attr.mkbootimg[DefaultInfo].files_to_run,
        build_boot = True,
        kernel_binary = ctx.attr.kernel_binary,
        vendor_boot_name = None,
        vendor_ramdisk_binaries = None,
        vendor_ramdisk_dev_nodes = None,
        unpack_ramdisk = False,
        avb_sign_boot_img = ctx.attr.avb_sign_boot_img,
        avb_boot_partition_size = ctx.attr.avb_boot_partition_size,
        avb_boot_key = ctx.attr.avb_boot_key,
        avb_boot_algorithm = ctx.attr.avb_boot_algorithm,
        avb_boot_partition_name = ctx.attr.avb_boot_partition_name,
        ramdisk_compression = None,
        ramdisk_compression_args = None,
        dtb_image_file = None,
        vendor_bootconfig_file = None,
        header_version = ctx.attr.header_version,
        os_version = ctx.attr.os_version,
        os_patch_level = ctx.attr.os_patch_level,
    )

boot_image = rule(
    doc = """Build `boot` image.""",
    implementation = _boot_image_impl,
    attrs = {
        "kernel_build": attr.label(
            mandatory = True,
            providers = [KernelSerializedEnvInfo, KernelBuildInfo],
        ),
        "deps": attr.label_list(
            allow_files = True,
        ),
        "outs": attr.string_list(
            doc = """A list of output files that will be installed to `DIST_DIR` when
                `build_boot_images` in `build/kernel/build_utils.sh` is executed.

                Unlike `kernel_images`, you must specify the list explicitly.
            """,
            allow_empty = False,
        ),
        "mkbootimg": attr.label(
            default = "//build/kernel:mkbootimg",
            executable = True,
            cfg = "exec",
        ),
        "kernel_binary": attr.label(
            doc = """The kernel binary to use, e.g. Image.lz4.

                This can be extracted from the [`kernel_build()`](#kernel_build)
                with a [`kernel_build_output()`](#kernel_build_output) rule.""",
            allow_single_file = True,
        ),
        "header_version": attr.int(
            doc = """Boot image header version.

                If unspecified, falls back to the value of BOOT_IMAGE_HEADER_VERSION
                in build configs. If BOOT_IMAGE_HEADER_VERSION is not set, defaults
                to 3.""",
            # It is intentional that 0 is not in the list. When specified explicitly,
            # the user can only provide these values. If unset, the value is 0.
            values = [3, 4],
        ),
        "avb_sign_boot_img": attr.bool(
            doc = """If set to `True` signs the boot image using the avb_boot_key.

                The kernel prebuilt tool `avbtool` is used for signing.""",
        ),
        "avb_boot_partition_size": attr.int(
            doc = """Size of the boot partition in bytes.

                Must be set when `avb_sign_boot_img` is True.""",
        ),
        "avb_boot_key": attr.label(
            doc = """Key used for signing.

                Must be set when `avb_sign_boot_img` is True.""",
            allow_single_file = True,
        ),
        # Note: The actual values comes from:
        # https://cs.android.com/android/kernel/superproject/+/common-android-mainline:external/avb/avbtool.py
        "avb_boot_algorithm": attr.string(
            doc = """`avb_boot_key` algorithm used e.g. SHA256_RSA2048.

                Must be set when `avb_sign_boot_img` is True.""",
            values = [
                "NONE",
                "SHA256_RSA2048",
                "SHA256_RSA4096",
                "SHA256_RSA8192",
                "SHA512_RSA2048",
                "SHA512_RSA4096",
                "SHA512_RSA8192",
            ],
        ),
        "avb_boot_partition_name": attr.string(
            doc = """Name of the boot partition.

                Must be set when `avb_sign_boot_img` is True.""",
        ),
        "os_version": attr.string(
            doc = """Adds operating system version to the boot image header.""",
        ),
        "os_patch_level": attr.string(
            doc = """Adds security patch level to the boot image header.""",
        ),
    },
    subrules = [
        build_boot_or_vendor_boot,
    ],
)
