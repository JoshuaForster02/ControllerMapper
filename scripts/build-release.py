#!/usr/bin/env python3
"""Build Ctrl using Apple's SDKs, with no package downloads or signing secrets."""
from pathlib import Path
import os, plistlib, shutil, subprocess
ROOT = Path(__file__).resolve().parents[1]
BUILD = Path(os.environ.get("CTRL_BUILD_DIR", str(ROOT / "build")))
BUILD.mkdir(parents=True, exist_ok=True)
def run(*args):
    result = subprocess.run([str(x) for x in args], cwd=ROOT, capture_output=True, text=True)
    if result.returncode: raise RuntimeError(result.stdout + result.stderr)
    return result.stdout
sdk = run("xcrun", "--sdk", "macosx", "--show-sdk-path").strip()
print(run("xcrun", "swiftc", "-swift-version", "5", ROOT / "Models.swift", ROOT / "InputSafety.swift", ROOT / "Tests/SafetyTests.swift", "-o", BUILD / "safety-tests"))
print(run(BUILD / "safety-tests"))
sources = sorted(ROOT.glob("*.swift"))
for arch in ["arm64", "x86_64"]:
    run("xcrun", "swiftc", "-swift-version", "5", "-O", "-sdk", sdk, "-target", arch + "-apple-macos14.0", "-module-cache-path", BUILD / "module-cache", *sources, "-o", BUILD / ("Ctrl-" + arch))
app = BUILD / "Ctrl.app"
if app.exists(): shutil.rmtree(app)
mac = app / "Contents/MacOS"; resources = app / "Contents/Resources"
mac.mkdir(parents=True); resources.mkdir()
run("/usr/bin/lipo", "-create", BUILD / "Ctrl-arm64", BUILD / "Ctrl-x86_64", "-output", mac / "Ctrl")
run("xcrun", "actool", ROOT / "Assets.xcassets", "--compile", resources, "--platform", "macosx", "--minimum-deployment-target", "14.0", "--app-icon", "AppIcon", "--output-partial-info-plist", BUILD / "asset-info.plist")
info = plistlib.loads((BUILD / "asset-info.plist").read_bytes())
info.update({"CFBundleName":"Ctrl", "CFBundleDisplayName":"Ctrl", "CFBundleExecutable":"Ctrl", "CFBundleIdentifier":"com.joshuaforster.controllermapper", "CFBundlePackageType":"APPL", "CFBundleShortVersionString":"1.3.0", "CFBundleVersion":"2", "LSMinimumSystemVersion":"14.0", "NSPrincipalClass":"NSApplication", "NSHighResolutionCapable":True, "LSApplicationCategoryType":"public.app-category.utilities", "NSBluetoothAlwaysUsageDescription":"Ctrl verbindet Gamepads und liest optional den gemeldeten Akkustand.", "UTExportedTypeDeclarations":[{"UTTypeIdentifier":"com.joshuaforster.ctrl.profile", "UTTypeDescription":"Ctrl Profile", "UTTypeConformsTo":["public.json"], "UTTypeTagSpecification":{"public.filename-extension":["cmprofile"]}}]})
(app / "Contents/Info.plist").write_bytes(plistlib.dumps(info))
for name in ["LICENSE", "README.md", "SETUP.md"]: shutil.copy2(ROOT / name, resources / name)
run("/usr/bin/xattr", "-cr", app)
run("/usr/bin/codesign", "--force", "--options", "runtime", "--timestamp=none", "--sign", os.environ.get("CTRL_SIGN_IDENTITY", "-"), app)
run("/usr/bin/codesign", "--verify", "--strict", app)
run("/usr/bin/ditto", "-c", "-k", "--keepParent", app, BUILD / "Ctrl-mac.zip")
print("Universal Ctrl 1.3.0 ready; signature verified:", BUILD / "Ctrl-mac.zip")
