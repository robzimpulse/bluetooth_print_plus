# iOS Modular Import Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the non-modular `#import "..."` of GSDK headers in the public
header `ios/Classes/ConnecterManager.h`, which breaks `xcodebuild archive`
under explicit module precompilation, and land the fix on a new branch with
a PR.

**Architecture:** Single 3-line textual change to one header file
(module-qualify three `#import` statements), verified first by reproducing
the archive failure pre-fix, then by confirming it's resolved post-fix.

**Tech Stack:** Objective-C / CocoaPods podspec, Xcode 26.3, Flutter 3.32.8,
`xcodebuild`, `pod` (CocoaPods 1.15.2 per `example/ios/Podfile.lock`).

## Global Constraints

- Scope is exactly one file: `ios/Classes/ConnecterManager.h`. Do not touch
  any other file's imports, even though some `.m` files also quote-import
  GSDK headers (confirmed harmless — see spec).
- Branch name: `fix/ios-modular-import`, created off current `main` tip.
- One commit containing only the header fix.
- Push the branch and open a PR against `main` (do not merge it).
- Do not modify `simontok_flutter` or attempt to re-pin its `pubspec.lock`
  — out of scope.
- Report the final commit SHA at the end.
- Spec: `docs/superpowers/specs/2026-07-09-ios-modular-import-fix-design.md`

---

### Task 1: Reproduce the archive failure pre-fix

**Files:**
- None modified. This task only runs commands to establish a baseline.

**Interfaces:**
- Consumes: nothing.
- Produces: a recorded pre-fix build log showing whether the
  `PrecompileModule`/non-modular-include error reproduces in this
  environment. Task 3 compares its post-fix log against this one.

- [ ] **Step 1: Generate `Generated.xcconfig` for the example app**

`example/ios/Flutter/Generated.xcconfig` does not exist yet (confirmed: only
`AppFrameworkInfo.plist`, `Debug.xcconfig`, `Release.xcconfig` are present).
The Podfile requires it.

Run:
```bash
cd /Users/roby/FlutterProject/bluetooth_print_plus/example && flutter pub get
```
Expected: exits 0, prints `Got dependencies!` (or similar), and
`example/ios/Flutter/Generated.xcconfig` now exists.

Verify:
```bash
ls example/ios/Flutter/Generated.xcconfig
```
Expected: file listed, no "No such file" error.

- [ ] **Step 2: Install pods (fetches GSDK from CocoaPods trunk over network)**

Run:
```bash
cd /Users/roby/FlutterProject/bluetooth_print_plus/example/ios && pod install
```
Expected: exits 0, ends with a line like `Pod installation complete!`. This
creates `example/ios/Pods/` and `example/ios/Runner.xcworkspace` (workspace
already existed; pods are refreshed). `GSDK (0.0.7)` should appear in the
install summary (matches `Podfile.lock`).

If this fails with a network/DNS error: stop, do not proceed to Step 3 —
report the network limitation and fall back to static-only verification
(the spec already accounts for this).

- [ ] **Step 3: Attempt an archive build with explicit modules forced on**

Run:
```bash
mkdir -p /private/tmp/claude-502/-Users-roby-FlutterProject-bluetooth-print-plus/9ec8cda4-0937-41ad-a63b-4d31f5606e77/scratchpad/archive-prefix
cd /Users/roby/FlutterProject/bluetooth_print_plus/example/ios && \
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath /private/tmp/claude-502/-Users-roby-FlutterProject-bluetooth-print-plus/9ec8cda4-0937-41ad-a63b-4d31f5606e77/scratchpad/archive-prefix/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  CLANG_ENABLE_EXPLICIT_MODULES=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee /private/tmp/claude-502/-Users-roby-FlutterProject-bluetooth-print-plus/9ec8cda4-0937-41ad-a63b-4d31f5606e77/scratchpad/archive-prefix/prefix-build.log
```

Three possible outcomes — determine which one occurred by inspecting the
log, then proceed accordingly:

- **(a) Reproduced the target failure**: log contains `PrecompileModule` and
  references `ConnecterManager.h` and/or `non-modular-include-in-framework-module`.
  This is the expected, best-case outcome — proceed to Task 2.
- **(b) Build fails for an unrelated reason** (code signing, provisioning
  profile, missing archive destination, GSDK pod incompatibility, etc.) and
  the log does NOT mention `ConnecterManager.h` or non-modular includes:
  note this in the final report as an environment limitation per the spec's
  documented fallback, then still proceed to Task 2 (the static analysis
  already justifies the fix independent of this repro).
- **(c) Build succeeds outright**: this Xcode/toolchain combination doesn't
  enforce explicit modules strictly enough to hit the bug here. Note this in
  the final report, then still proceed to Task 2.

- [ ] **Step 4: Save the outcome for later comparison**

Record which outcome (a/b/c) occurred and keep
`.../scratchpad/archive-prefix/prefix-build.log` on disk — Task 3 diffs
against it.

---

### Task 2: Apply the header fix

**Files:**
- Modify: `ios/Classes/ConnecterManager.h:10-12`

**Interfaces:**
- Consumes: nothing.
- Produces: the corrected header that Task 3's build consumes.

- [ ] **Step 1: Make the edit**

Current content of `ios/Classes/ConnecterManager.h` lines 9-14:
```objc
#import <Foundation/Foundation.h>
#import "BLEConnecter.h"
#import "EthernetConnecter.h"
#import "Connecter.h"

/**
```

Change lines 10-12 (the three quoted GSDK imports) to:
```objc
#import <Foundation/Foundation.h>
#import <GSDK/BLEConnecter.h>
#import <GSDK/EthernetConnecter.h>
#import <GSDK/Connecter.h>

/**
```

Do not change anything else in the file — the `#import "Connecter.h"` line
is the local pod's own `Connecter.h`-shaped API imported from GSDK (it's the
same GSDK module, confirmed by checking that `Connecter.h` is not present
anywhere under `ios/Classes/`, so it must resolve from the `GSDK` pod, same
as `BLEConnecter.h` and `EthernetConnecter.h`).

- [ ] **Step 2: Confirm no other occurrences were missed**

Run:
```bash
grep -n '#import "' ios/Classes/ConnecterManager.h
```
Expected: no output (empty) — all three quoted GSDK imports are gone.

Run:
```bash
grep -rn '#import "' ios/Classes/*.h
```
Expected: no output (empty) — `ConnecterManager.h` was the only `.h` file
with this problem; confirms no other public header regressed or was missed.

---

### Task 3: Verify the fix resolves (or doesn't regress) the build

**Files:**
- None modified.

**Interfaces:**
- Consumes: the fixed `ios/Classes/ConnecterManager.h` from Task 2, and the
  baseline log from Task 1 Step 4.
- Produces: a pass/fail verdict for the final report.

- [ ] **Step 1: Re-run pod install so Pods/ picks up the local podspec change**

The example app's Pods are installed from the local path
(`.symlinks/plugins/bluetooth_print_plus/ios`, per `Podfile.lock`'s
`EXTERNAL SOURCES`), so CocoaPods should already be reading the edited
header directly — but re-run install to be safe and regenerate any cached
module maps:

```bash
cd /Users/roby/FlutterProject/bluetooth_print_plus/example/ios && pod install
```
Expected: exits 0.

- [ ] **Step 2: Re-run the same archive command from Task 1 Step 3**

```bash
mkdir -p /private/tmp/claude-502/-Users-roby-FlutterProject-bluetooth-print-plus/9ec8cda4-0937-41ad-a63b-4d31f5606e77/scratchpad/archive-postfix
cd /Users/roby/FlutterProject/bluetooth_print_plus/example/ios && \
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath /private/tmp/claude-502/-Users-roby-FlutterProject-bluetooth-print-plus/9ec8cda4-0937-41ad-a63b-4d31f5606e77/scratchpad/archive-postfix/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  CLANG_ENABLE_EXPLICIT_MODULES=YES \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee /private/tmp/claude-502/-Users-roby-FlutterProject-bluetooth-print-plus/9ec8cda4-0937-41ad-a63b-4d31f5606e77/scratchpad/archive-postfix/postfix-build.log
```

- [ ] **Step 3: Compare against the Task 1 baseline and reach a verdict**

- If Task 1 outcome was **(a)** (reproduced the failure): this run must NOT
  contain `PrecompileModule`/`ConnecterManager.h`/non-modular-include
  errors. If it's clean (or fails later for an unrelated reason, e.g.
  signing), the fix is **verified**. If the same error still appears, the
  fix did not work — stop and re-investigate before proceeding to Task 4.
- If Task 1 outcome was **(b)** or **(c)** (couldn't reproduce the original
  failure): compare the two logs — they should show the same unrelated
  failure/success in both cases (i.e. the fix didn't change unrelated
  behavior). Report this as "fix applied and confirmed not to regress the
  build; could not reproduce the original archive failure in this sandbox to
  positively confirm the resolution" — this is the documented fallback from
  the spec, not a blocker.

---

### Task 4: Commit, branch, push, open PR

**Files:**
- Modify (commit only, already edited in Task 2): `ios/Classes/ConnecterManager.h`

**Interfaces:**
- Consumes: the verified fix from Task 3.
- Produces: a pushed branch, an open PR, and a commit SHA to report back to
  the user for `simontok_flutter`'s re-pin (that repo change itself is out
  of scope).

- [ ] **Step 1: Confirm current branch and working tree state**

```bash
git status
git branch --show-current
```
Expected: `main`, and only `ios/Classes/ConnecterManager.h` shows as
modified (plus any untracked build artifacts from Tasks 1/3, which must NOT
be committed — they live under `/private/tmp/...`, outside the repo, so
this should be a non-issue, but double-check `git status` shows no
`example/ios/Pods/` or `.symlinks` changes staged).

- [ ] **Step 2: Create the branch**

```bash
git checkout -b fix/ios-modular-import
```
Expected: `Switched to a new branch 'fix/ios-modular-import'`.

- [ ] **Step 3: Stage and commit**

```bash
git add ios/Classes/ConnecterManager.h
git commit -m "$(cat <<'EOF'
fix(ios): use module-qualified imports for GSDK headers in ConnecterManager.h

ConnecterManager.h is a public header of the bluetooth_print_plus Clang
module but imported GSDK's BLEConnecter.h, EthernetConnecter.h, and
Connecter.h via quoted textual includes instead of <GSDK/...>. This
compiles under implicit module resolution but fails PrecompileModule
under Xcode's explicit module builds (e.g. xcodebuild archive on newer
Xcode/SDKs). BluetoothPrintPlusPlugin.h already used the correct
module-qualified form; ConnecterManager.h now matches it.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
Expected: commit created, output shows
`1 file changed, 3 insertions(+), 3 deletions(-)`.

- [ ] **Step 4: Push the branch**

```bash
git push -u origin fix/ios-modular-import
```
Expected: exits 0, remote branch `fix/ios-modular-import` created.

- [ ] **Step 5: Open the PR**

```bash
gh pr create --title "fix(ios): use module-qualified GSDK imports in ConnecterManager.h" --body "$(cat <<'EOF'
## Summary
- `ios/Classes/ConnecterManager.h` is a public header of the
  `bluetooth_print_plus` Clang module but quote-imported three headers
  from the `GSDK` pod instead of using module-qualified imports.
- This compiles fine under implicit module resolution but fails
  `PrecompileModule` under Xcode's explicit module builds (e.g.
  `xcodebuild archive` on newer Xcode/SDKs), producing `** ARCHIVE FAILED **`.
- `BluetoothPrintPlusPlugin.h` already used the correct
  `#import <GSDK/BLEConnecter.h>` form; this PR makes
  `ConnecterManager.h` consistent with it for all three of its GSDK
  imports (`BLEConnecter.h`, `EthernetConnecter.h`, `Connecter.h`).
- Confirmed via grep that these were the only non-modular GSDK includes
  in any public header under `ios/Classes/`.

## Test plan
- [x] Static: grepped all of `ios/Classes/**/*.h` and `*.m`; confirmed
  exactly these 3 lines in exactly this 1 file were the only public-header
  offenders.
- [x] Dynamic: ran `pod install` + `xcodebuild archive` with
  `CLANG_ENABLE_EXPLICIT_MODULES=YES` against `example/` before and after
  the fix. <REPLACE THIS LINE with the actual Task 1/Task 3 outcome before
  running `gh pr create` — use one of:>
  - Outcome (a): "Reproduced the exact `PrecompileModule` /
    non-modular-include failure referencing `ConnecterManager.h`
    pre-fix; confirmed it is gone post-fix."
  - Outcome (b): "Could not reproduce the original archive failure in
    this sandbox (unrelated failure: `<state the actual reason, e.g.
    code signing>`); confirmed the fix doesn't change that unrelated
    outcome."
  - Outcome (c): "Archive succeeded both before and after in this
    sandbox (toolchain here doesn't hit the bug); fix is justified by
    the static analysis above."

Spec: `docs/superpowers/specs/2026-07-09-ios-modular-import-fix-design.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
Expected: PR URL printed.

- [ ] **Step 6: Report the commit SHA**

```bash
git rev-parse HEAD
```
Report this SHA plus the PR URL back to the user — `simontok_flutter`'s
`pubspec.yaml`/`pubspec.lock` will need to be re-pinned to it once this PR
is reviewed/merged (that re-pin is out of scope for this task).
