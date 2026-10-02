# Logic Pro 11 Patcher for macOS 27+

A quick, automated fix for **Logic Pro 11.0.1** crashing on launch when running on newer macOS versions (such as macOS 27 Golden Gate on Apple Silicon Macs).

---

## 💡 What Is This?

If you recently updated macOS and Logic Pro crashes immediately every time you try to open it (showing a `Symbol not found: _BNNSGraphContextGetContextSize` crash window), Apple removed an internal machine learning component from macOS that Logic Pro was expecting.

This tool automatically patches the issue so you can open Logic Pro and access all your projects again.

> [!NOTE]
> **Your original Logic Pro is 100% safe.**  
> The patcher **never modifies your original app**. Instead, it creates a separate, safe copy named **`Logic Pro X Patched.app`** in your `/Applications` folder.

> [!IMPORTANT]
> **Feature Notice:**  
> Core Logic Pro functions (recording, editing, mixing, plugins, instruments, audio playback, project loading) work normally. However, newer AI-based tools that rely on Apple's removed neural library (such as the Stem Splitter or AI Session Players) will not work because the underlying macOS code was eliminated by Apple.

---

## 📋 Prerequisites

Before running the patch, make sure you have Apple's Command Line Tools installed (needed for compiling the fix). If you don't have them yet, open Terminal and run:

```bash
xcode-select --install
```

_(If a prompt appears, click **Install** and wait for it to complete)._

---

## 🚀 Easy Step-by-Step Guide (How to Run)

Follow these 4 simple steps:

### Step 1: Open Terminal

1. Press `Command (⌘) + Space` on your keyboard to open Spotlight Search.
2. Type `Terminal` and press `Enter`.

### Step 2: Download / Clone and open the folder

In Terminal, clone this repository and enter the directory:

```bash
git clone https://github.com/jerearaujo03/logic-pro-patcher.git
cd logic-pro-patcher
```

_(Alternatively, if you downloaded the repository as a ZIP file, extract it, type `cd ` in Terminal with a space after it, and drag and drop the extracted folder into the Terminal window, then press `Enter`)._

### Step 3: Run the patcher script

Copy and paste this command and press `Enter`:

```bash
./patch_logic.sh
```

### Step 4: Open Logic Pro

Wait about 15–30 seconds for the script to finish. When you see:

```text
=== PATCH COMPLETED SUCCESSFULLY! ===
```

You are done! You will now find **Logic Pro X Patched** in your **Applications** folder (or Launchpad). Double-click it to start working!

---

## ❓ Frequently Asked Questions & Troubleshooting

### 1. macOS says: _"Logic Pro X Patched cannot be opened because Apple cannot check it for malicious software"_

Because the app was re-signed on your Mac to bypass the crash, macOS Gatekeeper may show a warning on first launch:

1. In Finder, open your **Applications** folder.
2. **Right-click** (or `Control + Click`) on **Logic Pro X Patched**.
3. Select **Open** from the menu.
4. Click **Open** again in the popup dialog box.  
   _(You only have to do this once. After that, it will open normally)._

### 2. Can I delete my original Logic Pro?

**No**, keep your original `Logic Pro X.app` untouched. It serves as your clean original backup whenever Apple releases an official update for macOS or Logic Pro.

### 3. What if my Logic Pro has a custom name or location?

You can pass custom source and destination paths to the script:

```bash
./patch_logic.sh "/Applications/Custom Logic Name.app" "/Applications/My Patched Logic.app"
```

---

## 🛠️ Technical Details (For Developers & Reverse Engineers)

<details>
<summary>Click to view in-depth technical analysis</summary>

### Root Cause

Under macOS 27, `Accelerate.framework` removed legacy BNNS (Basic Neural Network Subroutines) v1 graph context functions (`_BNNSGraphContextGetContextSize` and `_BNNSGraphContextInitialize`).

Because `MAMachineLearning.framework` imports these symbols via a Mach-O **Two-Level Namespace** linked against `/System/Library/Frameworks/Accelerate.framework/Versions/A/Accelerate`, the dynamic linker (`dyld`) halts before `main()` with:

```
Exception Type: EXC_CRASH (SIGABRT)
Termination Reason: Namespace DYLD, Code 4, Symbol missing
Symbol not found: _BNNSGraphContextGetContextSize
```

### How the Patch Works

1. **Universal Shim Dylib (`bnns_shim.c`)**:  
   Exports stub implementations of the missing BNNS symbols and re-exports the system `Accelerate.framework` (`-reexport_framework Accelerate`).
2. **Load Command Redirection**:  
   Uses `install_name_tool -change` on `MAMachineLearning` to redirect the `Accelerate` link reference to `@loader_path/libBNNSFix.dylib`.
3. **Inside-Out Ad-Hoc Signing**:  
   Clears quarantine attributes (`xattr -cr`) and re-signs all nested frameworks, dylibs, executables, and the outer bundle so AMFI and the macOS kernel permit execution.

The entire process is automated in `patch_logic.sh`.

</details>
