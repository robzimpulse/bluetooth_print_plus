# Fix non-modular header import in iOS `ConnecterManager.h`

## Problem

`ios/bluetooth_print_plus.podspec` builds this plugin as a Clang module
(`DEFINES_MODULE => 'YES'`) and exposes `Classes/**/*.h` as public headers.
One public header, `ios/Classes/ConnecterManager.h`, imports headers from a
different pod (`GSDK`) using quoted/textual includes:

```objc
#import "BLEConnecter.h"
#import "EthernetConnecter.h"
#import "Connecter.h"
```

This is a non-modular-include violation: a public header of the
`bluetooth_print_plus` module reaches into the `GSDK` module via a raw
`#import "..."` instead of a module-qualified `#import <GSDK/...>`. It
compiles fine under implicit module resolution, but fails under Xcode's
explicit module precompilation (used by `xcodebuild archive` on newer
Xcode/SDKs) with a `PrecompileModule` error, causing `** ARCHIVE FAILED **`.

The plugin's other public header, `ios/Classes/BluetoothPrintPlusPlugin.h`,
already imports GSDK correctly:

```objc
#import <GSDK/BLEConnecter.h>
```

## Scope confirmation

Grepped every `.h` and `.m` file under `ios/Classes/`:

- Exactly one file, `ios/Classes/ConnecterManager.h`, has quoted imports of
  GSDK headers inside a **public header** (3 lines: `BLEConnecter.h`,
  `EthernetConnecter.h`, `Connecter.h`).
- Several `.m` files (e.g. `BluetoothPrintPlusPlugin.m`) also quote-import
  GSDK headers (`EscCommand.h`, `TscCommand.h`), but `.m` files are not
  matched by the podspec's `public_header_files = 'Classes/**/*.h'` glob, so
  they are not part of the module's public interface and do not trigger the
  non-modular-include-in-framework-module error.

No other files need changes.

## Fix

In `ios/Classes/ConnecterManager.h`, change the three imports to
module-qualified form, matching the working pattern in
`BluetoothPrintPlusPlugin.h`:

```objc
#import <GSDK/BLEConnecter.h>
#import <GSDK/EthernetConnecter.h>
#import <GSDK/Connecter.h>
```

## Git workflow

- `fix/esc-qr-code` (the branch the task description originally named) was
  already merged into `main` via PR #2 (merge commit `655797a`) and deleted.
  `main` is a superset of that branch's history, including the commit
  downstream (`simontok_flutter`) is currently pinned to (`bbcdaa0`).
- Branch off current `main` tip as **`fix/ios-modular-import`** (new name,
  to avoid confusion with the already-used-and-deleted `fix/esc-qr-code`).
- One commit containing just the 3-line header fix.
- Push the branch and open a PR against `main` via `gh pr create`.
- Report the resulting commit SHA so `simontok_flutter`'s
  `pubspec.yaml`/`pubspec.lock` can be re-pinned to it. Re-pinning that repo
  and merging this PR are both out of scope for this task.

## Verification

1. **Static** (already done): grep confirms exactly 3 affected lines in
   exactly 1 file; the edit mirrors the already-correct sibling header.
2. **Dynamic**: run `pod install` in `example/ios`, then attempt
   `xcodebuild archive` (or an equivalent build invocation that forces
   explicit module precompilation) against the current (unfixed) code
   first, to try to reproduce the `PrecompileModule` failure, then again
   after applying the fix to confirm it's resolved.
   - If GSDK cannot be fetched (private spec repo / no network egress in
     this sandbox) or the repro fails for reasons unrelated to the header
     fix (code signing, missing archive destination, etc.), this will be
     reported honestly as a limitation rather than claimed as a passing
     verification. The static confirmation stands on its own as evidence
     for this specific, narrowly-scoped fix regardless.

## Out of scope

- Re-pinning `simontok_flutter`'s `pubspec.yaml`/`pubspec.lock`.
- Merging the PR into `main`.
