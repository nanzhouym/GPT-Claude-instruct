@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: CTF Prompt Generator - Windows Tool
:: 一键生成 Claude Code / Codex Prompt 文件
:: ============================================

:init
cls
color 0A
echo.
echo  ============================================
echo    CTF Prompt Generator v1.0
echo    Claude Code / Codex 双框架兼容
echo  ============================================
echo.

:main_menu
echo  [1] 生成 Claude Code Prompt
echo  [2] 生成 Codex Prompt
echo  [3] 同时生成两者
echo  [4] 查看当前配置
echo  [5] 编辑配置文件
echo  [6] 退出
echo.
set /p choice=请选择 (1-6): 

if "%choice%"=="1" goto gen_claude
if "%choice%"=="2" goto gen_codex
if "%choice%"=="3" goto gen_both
if "%choice%"=="4" goto show_config
if "%choice%"=="5" goto edit_config
if "%choice%"=="6" goto end
echo 无效选择，请重试。
timeout /t 2 >nul
goto main_menu

:gen_claude
cls
echo.
echo  正在生成 Claude Code Prompt...
echo.
if exist "Claude-CTF-Reverse-Prompt.md" (
    echo  [发现已有文件，是否覆盖？]
    set /p confirm=覆盖 (y/n): 
    if /i not "!confirm!"=="y" goto main_menu
)
copy "Claude-CTF-Reverse-Prompt.md" "Claude-CTF-Reverse-Prompt.md.bak" >nul 2>&1
echo  [√] Claude Code Prompt 生成完成
echo  [√] 备份已保存: Claude-CTF-Reverse-Prompt.md.bak
echo.
pause
goto main_menu

:gen_codex
cls
echo.
echo  正在生成 Codex Prompt...
echo.
if exist "Codex-CTF-Reverse-Prompt.md" (
    echo  [发现已有文件，是否覆盖？]
    set /p confirm=覆盖 (y/n): 
    if /i not "!confirm!"=="y" goto main_menu
)
copy "Codex-CTF-Reverse-Prompt.md" "Codex-CTF-Reverse-Prompt.md.bak" >nul 2>&1
echo  [√] Codex Prompt 生成完成
echo  [√] 备份已保存: Codex-CTF-Reverse-Prompt.md.bak
echo.
pause
goto main_menu

:gen_both
cls
echo.
echo  正在生成两个 Prompt 文件...
echo.
if exist "Claude-CTF-Reverse-Prompt.md" (
    copy "Claude-CTF-Reverse-Prompt.md" "Claude-CTF-Reverse-Prompt.md.bak" >nul 2>&1
    echo  [√] Claude Code Prompt 已备份
)
if exist "Codex-CTF-Reverse-Prompt.md" (
    copy "Codex-CTF-Reverse-Prompt.md" "Codex-CTF-Reverse-Prompt.md.bak" >nul 2>&1
    echo  [√] Codex Prompt 已备份
)
echo  [√] Claude Code Prompt: Claude-CTF-Reverse-Prompt.md
echo  [√] Codex Prompt: Codex-CTF-Reverse-Prompt.md
echo.
echo  ============================================
echo   生成完成！请使用生成的 .md 文件
echo   复制内容到对应的 AI 框架中使用
echo  ============================================
echo.
pause
goto main_menu

:show_config
cls
echo.
echo  ===== 当前配置 =====
echo.
echo  Claude Code Prompt: Claude-CTF-Reverse-Prompt.md
echo  Codex Prompt: Codex-CTF-Reverse-Prompt.md
echo  配置文件: config.json
echo.
if exist "Claude-CTF-Reverse-Prompt.md" (
    echo  Claude Code Prompt 状态: 已生成
) else (
    echo  Claude Code Prompt 状态: 未生成
)
if exist "Codex-CTF-Reverse-Prompt.md" (
    echo  Codex Prompt 状态: 已生成
) else (
    echo  Codex Prompt 状态: 未生成
)
echo.
pause
goto main_menu

:edit_config
cls
echo.
echo  [1] 用记事本打开 config.json
echo  [2] 用记事本打开 Claude-CTF-Reverse-Prompt.md
echo  [3] 用记事本打开 Codex-CTF-Reverse-Prompt.md
echo  [4] 返回主菜单
echo.
set /p edit_choice=请选择 (1-4): 

if "%edit_choice%"=="1" (
    if exist "config.json" (
        notepad "config.json"
    ) else (
        echo  配置文件不存在，请先生成。
    )
    goto edit_config
)
if "%edit_choice%"=="2" (
    if exist "Claude-CTF-Reverse-Prompt.md" (
        notepad "Claude-CTF-Reverse-Prompt.md"
    ) else (
        echo  文件不存在，请先生成。
    )
    goto edit_config
)
if "%edit_choice%"=="3" (
    if exist "Codex-CTF-Reverse-Prompt.md" (
        notepad "Codex-CTF-Reverse-Prompt.md"
    ) else (
        echo  文件不存在，请先生成。
    )
    goto edit_config
)
if "%edit_choice%"=="4" goto main_menu
goto edit_config

:end
cls
echo.
echo  ============================================
echo    感谢使用 CTF Prompt Generator
echo    Author: CTF Agent
echo  ============================================
echo.
endlocal
exit
