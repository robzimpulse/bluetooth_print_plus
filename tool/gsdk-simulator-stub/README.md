# GSDK iOS Simulator stub

`ios/Frameworks/GSDK.xcframework` is generated from this directory. Do not edit
the artifact by hand — change `GSDKStubs.m` and re-run the script.

## Why this exists

GSDK is the vendor SDK behind this plugin's thermal-printer support. Two
separate problems forced it to be vendored, and then rebuilt as an xcframework.

**It cannot be downloaded.** GSDK 0.0.7's published podspec sources it from
`https://gitee.com/besthandset/gsdk.git`, and gitee now rejects anonymous HTTPS
clones:

```
remote: [session-fd4df9aa] reject by [gitee]
fatal: Authentication failed for 'https://gitee.com/besthandset/gsdk.git/'
```

Because `Pods/` is not committed, every fresh `pod install` had to clone it, and
with no credentials git fell back to an interactive prompt — installs hung on
`Username for 'https://gitee.com':`.

**It cannot be linked into a simulator build.** Every slice of the original
library — `arm64` included — is tagged `LC_VERSION_MIN_IPHONEOS`, i.e. iOS
*device*. Xcode refuses to link a device-tagged `arm64` slice into an `arm64`
simulator build. That used to be survivable by excluding `arm64` for the
simulator SDK and falling back to `x86_64`, but Xcode 26 ships only arm64-only
simulator runtimes, so there is no fallback left.

Retagging the real objects was ruled out by measurement, not by preference: all
11 objects have **zero** bytes between the end of their load commands and their
first section, so `LC_VERSION_MIN_IPHONEOS` (16 bytes) cannot grow into
`LC_BUILD_VERSION` (24 bytes) without relocating every section and rewriting
every offset in the file. `vtool` refuses outright:

```
vtool error: BLEConnecter.o (arm64) not enough space to hold load commands
```

## What the xcframework contains

| Slice | Contents |
|---|---|
| `ios-arm64` | The real GSDK, untouched. Device builds are unaffected. |
| `ios-arm64_x86_64-simulator` | A no-op stub built from `GSDKStubs.m`. |

Nothing is lost by stubbing the simulator: GSDK drives a **Bluetooth** printer,
and simulators have no Bluetooth, so that code path could never be exercised
there under any implementation. The stub logs loudly on every call so a
simulator no-op is never mistaken for working printing.

`i386` and `armv7` are dropped deliberately — both are 32-bit, and every iOS
release this plugin supports is 64-bit only. That also takes the committed
binary from 4.9 MB to roughly 1.4 MB.

## Provenance of the device slice

The device slice is the `arm64` slice of the original pod's own
`GSDK.framework`, which was byte-identical (`sha256
ce37a14a2084883dee1dc5fec07b7fbef212ffb34830ba96534d3c6c1ebd38fa`) across two
independent installs whose `Podfile.lock` both recorded podspec checksum
`65d54603da7bece31b433c0f34f8a52c4431dd08`.

The original fat framework is not kept in the working tree — git preserves it at
commit `ec5d39b` as `ios/Frameworks/GSDK.framework`.

## How the stub works

Each GSDK class gets an empty `@implementation`, which emits the
`_OBJC_CLASS_$_` symbols the linker needs and synthesises every declared
`@property`. Method bodies are installed at runtime by
`+resolveInstanceMethod:` / `+resolveClassMethod:`, which point any selector at
a single no-op.

That shortcut is only valid because **every** method GSDK declares returns
either `void` or an object pointer — verified across all 11 headers: 160 `void`,
9 `NSData *`, 4 `UIImage *`, 1 `NSString *`, 1 `id`, and no `float`, `double`,
or struct returns. A function returning `id` therefore satisfies the ABI in both
cases.

> If a future GSDK header adds a method returning a float, a double, or a
> struct, this approach stops being valid for that method — it returns its value
> in a different register — and it must be written out explicitly.

## Regenerating

```sh
cd tool/gsdk-simulator-stub
./build_xcframework.sh
```

With no argument the script reuses the device slice already inside the
xcframework, so it is idempotent. To rebuild from the original fat framework
instead, pass it explicitly:

```sh
./build_xcframework.sh path/to/original/GSDK.framework
```

Afterwards, confirm the tagging is still correct:

```sh
otool -arch arm64 -l ios/Frameworks/GSDK.xcframework/ios-arm64/GSDK.framework/GSDK | grep -A3 LC_VERSION_MIN_IPHONEOS
otool -arch arm64 -l ios/Frameworks/GSDK.xcframework/ios-arm64_x86_64-simulator/GSDK.framework/GSDK | grep -A5 LC_BUILD_VERSION
```

The device slice must show `LC_VERSION_MIN_IPHONEOS`; the simulator slice must
show `LC_BUILD_VERSION` with `platform 7`.
