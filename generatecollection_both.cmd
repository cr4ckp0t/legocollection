@echo off
pwsh %~dp0Generate-CollectionTable.ps1
notepad %~dp0owned.md
notepad %~dp0minifigs.md