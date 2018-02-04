# Xeon v3/v4 All Core Turbo Unlocking Howto

## Step 1. Flash BIOS without microcode update

Microcode update loaded by BIOS would lock turbo bins and needs to be disabled
for the mod to work. Perhaps the easiest way to remove it from BIOS is to
cripple the header with the list of available microcodes in BIOS ROM file.
Find your CPUID in the BIOS ROM, e.g. for 0x0306F2 (Xeon v3 / Haswell-E) search
for F2 06 03 00 with a hex editor. There should be two closely located matches.
Change both 03 to 05 to preserve microcode region's checksum.

While you're at it, consider purging ME firmware from the BIOS ROM with
[me_cleaner](https://github.com/corna/me_cleaner):

```
$ ./me_cleaner.py -S -O output.bin input.bin
```

Flashing BIOS: if motherboard has a removable BIOS chip, universal and safest
way to flash it would be to use an external SPI programmer, e.g. the cheap
CH341. Ideally get a spare chip just in case for flashing your experimental
BIOS, e.g. Winbond W25Q128FVIQ (16MB). Total cost $3-5.

Possible issues:

  * If CPU hangs under load without microcode, consider disabling or
    enabling C3 and C6 sleep states in BIOS.
  * BCLK overclocking and other settings might stop working without ME
    on some boards.

Tools:

  * [UEFITool](https://github.com/LongSoft/UEFITool) -
    deencapsule CAP BIOS files
  * [me_cleaner](https://github.com/corna/me_cleaner)
  * flashrom from debian repositories - for flashing with SPI programmer
  * Hex editor, e.g. oktete from debian repositories.

## Step 2. Turbo drivers

Many binaries are floating around that unlock the turbo bins, typically in
the form of .efi drivers. A couple of open sourced ones:

  * https://peine-braun.net/public_files/XEON_V3_BIOS_MODS/EFI-Drivers/
  * https://github.com/freecableguy/v3x4

General installation procedure:

  * OS must be installed in UEFI mode.
  * Install EFI shell unless it's already supplied by the BIOS.
    [Sample binary](https://github.com/tianocore/edk2/blob/master/ShellBinPkg/UefiShell/X64/Shell.efi?raw=true),
    copy to EFI partition and register:
    `efibootmgr -c -v -L shell -l '\EFI\shell.efi' -d <EFI device> -p <EFI partition no>`
  * Copy .efi files of turbo drivers to EFI partition
  * To try out a driver for a single boot, boot into EFI shell, run e.g.
    `load fs0:\EFI\turbo.efi`, `exit` and boot into OS.
  * Once happy, to enable it to be always run at boot:
    `bcfg driver add 0 fs0:\EFI\turbo.efi "turbo"`.
  * Removing a driver: `bcfg driver dump`, then `bcfg driver rm <index>`.
    Or disconnect EFI drive if can't even boot into EFI shell.

Most of the drivers enable some CPU undervolting, higher undervolting generally
would allow higher all core clocks to be achieved at the expense of a possible
instability. This highly depends on silicon.

Some come with a built-in microcode update. Unless you want a specific
version of it (there's a higher overclocking potential with some earlier
versions), it's not really needed - microcode can be loaded just fine
afterwards by the OS.

## Step 3. Microcode update

Optional, but recommended: install `intel-microcode` package (for debian)
to load a microcode update when OS starts.

## References

* [Anandtech thread](https://forums.anandtech.com/threads/what-controls-turbo-core-in-xeons.2496647/)
