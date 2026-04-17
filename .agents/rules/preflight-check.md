---
trigger: always_on
---

Context Priority: Before starting any task, check for a .ai-context file or memory-bank/ folder. Use these as your primary map to avoid full-project indexing. Auto-Update: You MUST update these metadata files immediately after any structural change (new files, refactored logic, changed APIs). Efficiency: Keep the project map "surgical." If a file becomes "noise" (bloated), mark it to be ignored in future context pulls.