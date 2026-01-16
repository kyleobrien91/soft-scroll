# Improvement Plan for Soft Scroll

This document outlines a roadmap for improving the Soft Scroll application. The improvements are categorized by User Experience (UX), Reliability, Security, Packagability, and Cross-Platform compatibility.

## 1. User Experience (UX)

The current experience is functional but minimal. To match the polish of macOS or commercial Windows utilities, several additions are needed.

### 1.1 "Start with Windows"
**Issue:** Users must manually start the app after every reboot.
**Recommendation:** Implement auto-start functionality.
- **Implementation:** Use the Windows Registry `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` key or place a shortcut in the User Startup folder.
- **UI:** Add a checkbox in Settings.

### 1.2 Per-App Exclusion List
**Issue:** Games and full-screen applications often misbehave with injected input (e.g., anti-cheat triggers, camera glitches).
**Recommendation:** Allow users to define a "Blacklist" of executable names (e.g., `cs2.exe`, `photoshop.exe`).
- **Implementation:**
  - Maintain a `List<string> ExcludedApps` in `AppSettings`.
  - In `SmoothScrollEngine` or `GlobalMouseHook`, check the process name of the foreground window (`GetForegroundWindow` -> `GetWindowThreadProcessId`).
  - If the foreground app is blacklisted, bypass the smooth scroll logic and let the original event pass through.

### 1.3 Tray Icon Enhancements
**Issue:** The tray menu is basic. Users often need to quickly disable the app for a moment.
**Recommendation:**
- Add a "Pause for 1 hour" option.
- Add a "Disable for this app" option (adds current foreground app to blacklist).
- Update the icon to indicate state (e.g., grayed out when disabled).

### 1.4 Modern UI Polish
**Issue:** The settings window has a custom dark theme that may not match the user's system preference.
**Recommendation:**
- Use [WPF UI](https://wpfui.lepo.co/) or standard Windows 11 styles (Mica background).
- Respect the system's Light/Dark mode setting.
- Ensure High-DPI scaling is perfect (WPF handles this well, but custom bitmaps/icons need checking).

---

## 2. Reliability & Performance

### 2.1 Robust Exception Handling
**Issue:** `AppSettings.Load/Save` and `GlobalMouseHook` operations may silently fail or crash the app.
**Recommendation:**
- Implement a global exception handler in `App.xaml.cs` (`DispatcherUnhandledException` and `AppDomain.CurrentDomain.UnhandledException`).
- Log errors to a file (e.g., `%AppData%\SoftScroll\error.log`) using a library like Serilog or a simple text writer.
- Ensure the hook is uninstalled cleanly on crash to avoid leaving the mouse in a weird state (though Windows cleans up hooks eventually).

### 2.2 Threading & Timing
**Issue:** `SmoothScrollEngine` uses `Thread.Sleep(1)` in a loop.
**Recommendation:**
- While `Thread.Sleep(1)` is acceptable on Windows for this purpose, consider `QueryPerformanceCounter` or a high-resolution timer for smoother frame delivery if users report micro-stutter.
- Ensure the thread priority is set to `ThreadPriority.AboveNormal` to prevent UI lag in other apps from affecting scroll smoothness.

### 2.3 Input Injection Safety
**Issue:** `SendInput` can theoretically fail or get stuck.
**Recommendation:**
- Add a "watchdog" counter. If `SendInput` fails consecutively, disable the engine and notify the user via a toast notification.

---

## 3. Security

### 3.1 Least Privilege
**Issue:** Global hooks often require the app to run with the same privileges as the target window. To hook Admin apps (Task Manager), Soft Scroll must run as Admin.
**Recommendation:**
- Add an `app.manifest`.
- Decide on the policy:
  - **Option A:** Request `requireAdministrator` (User gets UAC prompt every launch).
  - **Option B:** Run `asInvoker` (Default), but detect when the user is trying to scroll an Admin window and show a notification explaining why it doesn't work.
- **Preferred:** Option A is standard for system-wide utilities, but Option B provides a better seamless startup experience. A hybrid approach (launch as user, restart as Admin button in settings) is best.

### 3.2 Secure Configuration
**Issue:** `settings.json` is plain text.
**Recommendation:**
- Ensure the file permissions on `%AppData%\SoftScroll` restrict access to the current user (default Windows behavior, but good to verify).
- Validate all input values in `AppSettings.Load` to prevent integer overflows or negative values that could crash the engine.

---

## 4. Packagability & Distribution

### 4.1 Installer
**Issue:** The current distribution is a raw `.exe`.
**Recommendation:**
- Create an installer using **WiX Toolset** or **Inno Setup**.
- An installer allows:
  - Creating the Start Menu shortcut.
  - Creating the Desktop shortcut.
  - Adding the "Start with Windows" registry key properly.
  - Uninstalling cleanly.

### 4.2 Signing (Critical)
**Issue:** "Unknown Publisher" and SmartScreen warnings scare users.
**Recommendation:**
- Obtain a Code Signing Certificate (EV or Standard).
- Sign the `.exe` and the Installer.
- This is the single biggest step to increasing user trust and adoption.

### 4.3 CI/CD
**Issue:** Manual builds.
**Recommendation:**
- Create a `.github/workflows/build.yml` file.
- Automate the build and release process on every tag push.

---

## 5. Cross-Platform (Long Term)

**Issue:** The app is tightly coupled to `user32.dll` (Win32 API).
**Recommendation:**
- **Architecture:** Interface-out the OS dependencies.
  - `IMouseHook`: `Install()`, `Uninstall()`.
  - `IInputInjector`: `Scroll(dx, dy)`.
- **Linux:** Use `libinput` or X11/Wayland extensions (harder due to security models).
- **macOS:** Use Quartz Event Taps (`CGEventTap`).
- **UI:** Migrate from WPF to **Avalonia UI** for a shared XAML codebase across Windows, macOS, and Linux.

---

## 6. Code Quality

### 6.1 Unit Tests
**Recommendation:**
- Extract the math logic in `SmoothScrollEngine` (acceleration, easing) into a pure class that doesn't depend on `SendInput`.
- Write unit tests (`xUnit` or `NUnit`) to verify the math outputs correct scroll deltas for given inputs.

### 6.2 Modern C# Features
**Recommendation:**
- Ensure usages of `using` declarations are consistent.
- Use `file-scoped namespaces` (already partially used) consistently.
- Use `record` types for immutable data structures like event args.
