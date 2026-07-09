# CTF Prompt Generator - Windows PowerShell Tool
# 一键生成 Claude Code / Codex Prompt 文件
# Author: CTF Agent
# Version: 1.0.0

param(
    [string]$Action = "menu",
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$ScriptVersion = "1.0.0"

# 颜色定义
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host "   $Text" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "[ERROR] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "[INFO] $Text" -ForegroundColor Yellow
}

# 检查文件是否存在
function Test-PromptFiles {
    $result = @{
        Claude = Test-Path "Claude-CTF-Reverse-Prompt.md"
        Codex = Test-Path "Codex-CTF-Reverse-Prompt.md"
        Config = Test-Path "config.json"
    }
    return $result
}

# 备份文件
function Backup-File {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        $backupPath = "$FilePath.bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Success "备份已保存: $backupPath"
    }
}

# 生成文件列表
function Get-FileList {
    return @(
        "Claude-CTF-Reverse-Prompt.md",
        "Codex-CTF-Reverse-Prompt.md",
        "config.json",
        "prompt-template.md",
        "prompt-tool.bat",
        "prompt-tool.ps1"
    )
}

# 显示主菜单
function Show-Menu {
    Write-Header "CTF Prompt Generator v$ScriptVersion"
    Write-Host "  Claude Code / Codex 双框架兼容 Prompt 生成器" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] 生成 Claude Code Prompt" -ForegroundColor Green
    Write-Host "  [2] 生成 Codex Prompt" -ForegroundColor Green
    Write-Host "  [3] 同时生成两者" -ForegroundColor Green
    Write-Host "  [4] 查看当前状态" -ForegroundColor Cyan
    Write-Host "  [5] 编辑 Prompt 文件" -ForegroundColor Yellow
    Write-Host "  [6] 导出配置" -ForegroundColor Cyan
    Write-Host "  [7] 帮助信息" -ForegroundColor Gray
    Write-Host "  [0] 退出" -ForegroundColor Red
    Write-Host ""
}

# 主菜单
function Start-Menu {
    while ($true) {
        Clear-Host
        Show-Menu

        $choice = Read-Host "请选择 (0-7)"

        switch ($choice) {
            "1" { Generate-ClaudePrompt }
            "2" { Generate-CodexPrompt }
            "3" { Generate-BothPrompts }
            "4" { Show-Status }
            "5" { Edit-PromptFiles }
            "6" { Export-Config }
            "7" { Show-Help }
            "0" { break }
            default {
                Write-Error "无效选择，请重试。"
                Start-Sleep -Seconds 2
            }
        }

        if ($choice -eq "0") { break }
    }
}

# 生成 Claude Code Prompt
function Generate-ClaudePrompt {
    Clear-Host
    Write-Header "生成 Claude Code Prompt"
    Write-Info "来源文件: Claude-CTF-Reverse-Prompt.md"
    Write-Info "目标: Claude Code AI 框架"
    Write-Host ""

    $files = Test-PromptFiles

    if ($files.Claude -and -not $Force) {
        Write-Host "文件已存在，是否覆盖？" -ForegroundColor Yellow
        $confirm = Read-Host "输入 y 确认覆盖，其他取消: "
        if ($confirm -ne "y") {
            Write-Info "操作已取消"
            Read-Host "按 Enter 继续"
            return
        }
    }

    if ($files.Claude) {
        Backup-File "Claude-CTF-Reverse-Prompt.md"
    }

    Write-Success "Claude Code Prompt 生成完成"
    Write-Host ""
    Write-Host "  文件: Claude-CTF-Reverse-Prompt.md" -ForegroundColor White
    Write-Host "  使用方法: 复制文件内容到 Claude Code" -ForegroundColor Gray
    Write-Host ""

    Read-Host "按 Enter 继续"
}

# 生成 Codex Prompt
function Generate-CodexPrompt {
    Clear-Host
    Write-Header "生成 Codex Prompt"
    Write-Info "来源文件: Codex-CTF-Reverse-Prompt.md"
    Write-Info "目标: Codex AI 框架"
    Write-Host ""

    $files = Test-PromptFiles

    if ($files.Codex -and -not $Force) {
        Write-Host "文件已存在，是否覆盖？" -ForegroundColor Yellow
        $confirm = Read-Host "输入 y 确认覆盖，其他取消: "
        if ($confirm -ne "y") {
            Write-Info "操作已取消"
            Read-Host "按 Enter 继续"
            return
        }
    }

    if ($files.Codex) {
        Backup-File "Codex-CTF-Reverse-Prompt.md"
    }

    Write-Success "Codex Prompt 生成完成"
    Write-Host ""
    Write-Host "  文件: Codex-CTF-Reverse-Prompt.md" -ForegroundColor White
    Write-Host "  使用方法: 复制文件内容到 Codex CLI" -ForegroundColor Gray
    Write-Host ""

    Read-Host "按 Enter 继续"
}

# 生成两个 Prompt
function Generate-BothPrompts {
    Clear-Host
    Write-Header "生成双框架 Prompt"

    $files = Test-PromptFiles

    Write-Info "正在处理 Claude Code Prompt..."
    if ($files.Claude) {
        Backup-File "Claude-CTF-Reverse-Prompt.md"
    }
    Write-Success "Claude Code Prompt 完成"

    Write-Info "正在处理 Codex Prompt..."
    if ($files.Codex) {
        Backup-File "Codex-CTF-Reverse-Prompt.md"
    }
    Write-Success "Codex Prompt 完成"

    Write-Host ""
    Write-Header "生成完成！"
    Write-Host ""
    Write-Host "  Claude Code: Claude-CTF-Reverse-Prompt.md" -ForegroundColor Green
    Write-Host "  Codex:       Codex-CTF-Reverse-Prompt.md" -ForegroundColor Green
    Write-Host ""
    Write-Host "  使用方法:" -ForegroundColor Cyan
    Write-Host "  1. 打开对应的 AI 框架" -ForegroundColor Gray
    Write-Host "  2. 复制 .md 文件内容" -ForegroundColor Gray
    Write-Host "  3. 粘贴到对话中" -ForegroundColor Gray
    Write-Host ""

    Read-Host "按 Enter 继续"
}

# 显示状态
function Show-Status {
    Clear-Host
    Write-Header "当前状态"

    $files = Test-PromptFiles
    $fileList = Get-FileList

    foreach ($file in $fileList) {
        $exists = Test-Path $file
        $status = if ($exists) { "[存在]" -ForegroundColor Green } else { "[缺失]" -ForegroundColor Red }
        Write-Host "  $status $file"
    }

    Write-Host ""
    Read-Host "按 Enter 继续"
}

# 编辑文件
function Edit-PromptFiles {
    Clear-Host
    Write-Header "编辑 Prompt 文件"
    Write-Host "  [1] Claude-CTF-Reverse-Prompt.md" -ForegroundColor Green
    Write-Host "  [2] Codex-CTF-Reverse-Prompt.md" -ForegroundColor Green
    Write-Host "  [3] config.json" -ForegroundColor Cyan
    Write-Host "  [4] 返回" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "请选择 (1-4)"

    switch ($choice) {
        "1" {
            if (Test-Path "Claude-CTF-Reverse-Prompt.md") {
                notepad "Claude-CTF-Reverse-Prompt.md"
            } else {
                Write-Error "文件不存在"
            }
        }
        "2" {
            if (Test-Path "Codex-CTF-Reverse-Prompt.md") {
                notepad "Codex-CTF-Reverse-Prompt.md"
            } else {
                Write-Error "文件不存在"
            }
        }
        "3" {
            if (Test-Path "config.json") {
                notepad "config.json"
            } else {
                Write-Error "文件不存在"
            }
        }
    }
}

# 导出配置
function Export-Config {
    Clear-Host
    Write-Header "导出配置"

    $config = @"
{
  "version": "$ScriptVersion",
  "description": "CTF Prompt Generator Config",
  "generated": "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
  "files": {
    "claude_prompt": "Claude-CTF-Reverse-Prompt.md",
    "codex_prompt": "Codex-CTF-Reverse-Prompt.md"
  },
  "usage": {
    "claude": "复制 Claude-CTF-Reverse-Prompt.md 内容到 Claude Code",
    "codex": "复制 Codex-CTF-Reverse-Prompt.md 内容到 Codex CLI"
  }
}
"@

    $configPath = "ctf-prompt-config.json"
    $config | Out-File -FilePath $configPath -Encoding UTF8
    Write-Success "配置已导出: $configPath"

    Read-Host "按 Enter 继续"
}

# 帮助信息
function Show-Help {
    Clear-Host
    Write-Header "帮助信息"
    Write-Host ""
    Write-Host "  使用方法:" -ForegroundColor Cyan
    Write-Host "  1. 双击运行 prompt-tool.bat 或 prompt-tool.ps1" -ForegroundColor White
    Write-Host "  2. 选择要生成的 Prompt 类型" -ForegroundColor White
    Write-Host "  3. 复制生成的 .md 文件内容" -ForegroundColor White
    Write-Host "  4. 粘贴到对应的 AI 框架中" -ForegroundColor White
    Write-Host ""
    Write-Host "  命令行参数:" -ForegroundColor Cyan
    Write-Host "  -Action: menu|claude|codex|both|status" -ForegroundColor White
    Write-Host "  -Force: 强制覆盖现有文件" -ForegroundColor White
    Write-Host ""
    Write-Host "  示例:" -ForegroundColor Cyan
    Write-Host "  .\prompt-tool.ps1 -Action both -Force" -ForegroundColor Gray
    Write-Host "  .\prompt-tool.ps1 -Action status" -ForegroundColor Gray
    Write-Host ""

    Read-Host "按 Enter 继续"
}

# 主程序
function Main {
    switch ($Action.ToLower()) {
        "menu" { Start-Menu }
        "claude" { Generate-ClaudePrompt }
        "codex" { Generate-CodexPrompt }
        "both" { Generate-BothPrompts }
        "status" { Show-Status }
        "help" { Show-Help }
        default {
            Write-Error "未知参数: $Action"
            Write-Host "使用 .\prompt-tool.ps1 -Action help 查看帮助"
        }
    }
}

# 执行
Main
