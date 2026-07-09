# AGENTS.md — Lessons Learned

| Date | Error / Pitfall Encountered | Technical Root Cause | Prevention & Resolution Strategy |
| :--- | :--- | :--- | :--- |
| 2026-06-30 | QR code printed nothing on paper despite `addStoreQRCodeData()` being called | The GPrinter ESC/POS SDK requires a mandatory two-step sequence: `addStoreQRCodeData(content)` buffers the QR data, then `addPrintQRCode()` must follow to emit `GS ( k pL pH cn fn=81 m` and actually render it. The second call was absent in `EscCommandPlugin.java`. | Always follow GPrinter SDK docs for multi-step print commands. For QR codes specifically: call `addStoreQRCodeData()` then immediately call `addPrintQRCode()` before `result.success(true)`. |
