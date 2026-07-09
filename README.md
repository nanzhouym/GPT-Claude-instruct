<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GPT-Claude CTF Reverse Engineering Prompt Template</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #24292f;
            background: #f6f8fa;
        }

        .lang-switcher {
            position: fixed;
            top: 16px;
            right: 20px;
            z-index: 1000;
            display: flex;
            align-items: center;
            gap: 8px;
            background: #fff;
            border: 1px solid #d0d7de;
            border-radius: 6px;
            padding: 4px 10px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        }

        .lang-switcher button {
            background: none;
            border: none;
            padding: 4px 8px;
            cursor: pointer;
            font-size: 13px;
            color: #57606a;
            border-radius: 4px;
            transition: all 0.2s;
        }

        .lang-switcher button:hover {
            background: #f3f4f6;
            color: #0969da;
        }

        .lang-switcher button.active {
            background: #0969da;
            color: #fff;
            font-weight: 600;
        }

        .lang-switcher .divider {
            color: #d0d7de;
            font-size: 12px;
        }

        .container {
            max-width: 960px;
            margin: 0 auto;
            padding: 40px 20px;
        }

        .header {
            text-align: center;
            padding: 60px 0 40px;
        }

        .header h1 {
            font-size: 2.4em;
            font-weight: 700;
            color: #0969da;
            margin-bottom: 12px;
        }

        .header .subtitle {
            font-size: 1.15em;
            color: #57606a;
            max-width: 680px;
            margin: 0 auto 24px;
        }

        .qr-section {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 32px 0;
            padding: 24px;
            background: #fff;
            border: 1px solid #d0d7de;
            border-radius: 12px;
        }

        .qr-section img {
            width: 200px;
            height: 200px;
            border-radius: 8px;
        }

        .qr-section .qr-label {
            margin-top: 12px;
            font-size: 15px;
            color: #57606a;
            text-align: center;
        }

        .qr-section .qr-label strong {
            color: #24292f;
            font-size: 16px;
        }

        .badges {
            display: flex;
            justify-content: center;
            gap: 12px;
            flex-wrap: wrap;
            margin-top: 16px;
        }

        .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            background: #ddf4ff;
            color: #0969da;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
        }

        /* Language-specific content */
        [data-lang="en"] .lang-en { display: block; }
        [data-lang="en"] .lang-zh { display: none; }
        [data-lang="zh"] .lang-en { display: none; }
        [data-lang="zh"] .lang-zh { display: block; }

        .section {
            background: #fff;
            border: 1px solid #d0d7de;
            border-radius: 12px;
            padding: 28px 32px;
            margin-bottom: 20px;
        }

        .section h2 {
            font-size: 1.4em;
            color: #24292f;
            margin-bottom: 16px;
            padding-bottom: 8px;
            border-bottom: 2px solid #ddf4ff;
        }

        .section p {
            margin-bottom: 12px;
            color: #57606a;
        }

        .section ul {
            list-style: none;
            margin: 12px 0;
        }

        .section ul li {
            padding: 6px 0;
            color: #57606a;
            position: relative;
            padding-left: 20px;
        }

        .section ul li::before {
            content: '▹';
            position: absolute;
            left: 0;
            color: #0969da;
        }

        .file-tree {
            background: #f6f8fa;
            border-radius: 8px;
            padding: 16px 20px;
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-size: 13px;
            line-height: 1.8;
            color: #57606a;
            overflow-x: auto;
        }

        .file-tree .dir { color: #8250df; font-weight: 600; }
        .file-tree .file { color: #24292f; }

        .cta-buttons {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            margin: 20px 0;
        }

        .cta-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            background: #0969da;
            color: #fff;
            text-decoration: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            transition: background 0.2s;
        }

        .cta-btn:hover { background: #0860ca; }
        .cta-btn.secondary {
            background: #2da44e;
        }
        .cta-btn.secondary:hover { background: #269f42; }

        .footer {
            text-align: center;
            padding: 40px 0;
            color: #8c959f;
            font-size: 13px;
        }

        .footer a {
            color: #0969da;
            text-decoration: none;
        }

        /* Category grid */
        .cat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 12px;
            margin: 16px 0;
        }

        .cat-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 14px;
            background: #f6f8fa;
            border-radius: 8px;
            font-size: 14px;
            color: #57606a;
        }

        .cat-item .tag {
            display: inline-block;
            padding: 2px 8px;
            background: #0969da;
            color: #fff;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            min-width: 48px;
            text-align: center;
        }

        .usage-block {
            background: #f6f8fa;
            border-radius: 8px;
            padding: 16px 20px;
            margin: 12px 0;
            overflow-x: auto;
        }

        .usage-block code {
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-size: 13px;
            color: #24292f;
        }

        .lang-indicator {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 10px;
            background: #ddf4ff;
            color: #0969da;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 12px;
        }

        @media (max-width: 640px) {
            .header h1 { font-size: 1.6em; }
            .lang-switcher { top: 10px; right: 10px; }
            .section { padding: 20px 16px; }
            .cat-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body data-lang="en">

    <!-- Language Switcher -->
    <div class="lang-switcher">
        <button class="active" id="btn-en" onclick="switchLang('en')">EN</button>
        <span class="divider">|</span>
        <button id="btn-zh" onclick="switchLang('zh')">中文</button>
    </div>

    <div class="container">

        <!-- Header -->
        <div class="header">
            <h1>GPT-Claude CTF Reverse Engineering Prompt Template</h1>

            <!-- English content -->
            <div class="lang-en">
                <p class="subtitle">Professional-grade CTF Reverse Engineering Prompt Templates for dual-framework compatibility — Claude Code and Codex CLI agents.</p>
                <div class="badges">
                    <span class="badge">Claude Code</span>
                    <span class="badge">Codex</span>
                    <span class="badge">CTF</span>
                    <span class="badge">Reverse Engineering</span>
                    <span class="badge">Security Research</span>
                </div>
            </div>

            <!-- Chinese content -->
            <div class="lang-zh">
                <p class="subtitle">专业级 CTF 逆向工程 Prompt 模板，双框架兼容 —— Claude Code 与 Codex CLI 智能体均可使用。</p>
                <div class="badges">
                    <span class="badge">Claude Code</span>
                    <span class="badge">Codex</span>
                    <span class="badge">CTF</span>
                    <span class="badge">逆向工程</span>
                    <span class="badge">安全研究</span>
                </div>
            </div>
        </div>

        <!-- QR Code -->
        <div class="qr-section">
            <img src="images/b2b81cd407357da51e7990223fe6cf9d.png" alt="QQ Group QR Code">
            <div class="lang-en qr-label">
                <strong>Amiya Exchange Group</strong><br>
                Group Number: 1081165166<br>
                <span style="font-size:13px;color:#8c959f;">Scan to join our community</span>
            </div>
            <div class="lang-zh qr-label">
                <strong>亚弥雅交流群</strong><br>
                群号：1081165166<br>
                <span style="font-size:13px;color:#8c959f;">扫描二维码加入群聊</span>
            </div>
        </div>

        <!-- Quick Start -->
        <div class="section">
            <h2 class="lang-en">⚡ Quick Start</h2>
            <h2 class="lang-zh">⚡ 快速开始</h2>

            <div class="lang-en">
                <div class="cta-buttons">
                    <a href="prompts/Claude-CTF-Reverse-Prompt.md" class="cta-btn">
                        ⎈ Claude Code Prompt
                    </a>
                    <a href="prompts/Codex-CTF-Reverse-Prompt.md" class="cta-btn secondary">
                        ⚡ Codex Prompt
                    </a>
                </div>

                <h3 style="font-size:1.1em;margin:16px 0 10px;">For Claude Code</h3>
                <div class="usage-block">
                    <code>cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md</code>
                </div>

                <h3 style="font-size:1.1em;margin:16px 0 10px;">For Codex</h3>
                <div class="usage-block">
                    <code>cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md</code>
                </div>

                <h3 style="font-size:1.1em;margin:16px 0 10px;">Windows Quick Tools</h3>
                <div class="usage-block">
                    <code>.\tools\prompt-tool.bat</code><br>
                    <code>powershell -ExecutionPolicy Bypass -File .\tools\prompt-tool.ps1</code>
                </div>
            </div>

            <div class="lang-zh">
                <div class="cta-buttons">
                    <a href="prompts/Claude-CTF-Reverse-Prompt.md" class="cta-btn">
                        ⎈ Claude Code Prompt
                    </a>
                    <a href="prompts/Codex-CTF-Reverse-Prompt.md" class="cta-btn secondary">
                        ⚡ Codex Prompt
                    </a>
                </div>

                <h3 style="font-size:1.1em;margin:16px 0 10px;">Claude Code 用户</h3>
                <div class="usage-block">
                    <code>cp prompts/Claude-CTF-Reverse-Prompt.md ~/.claude/prompts/ctf-reverse.md</code>
                </div>

                <h3 style="font-size:1.1em;margin:16px 0 10px;">Codex 用户</h3>
                <div class="usage-block">
                    <code>cp prompts/Codex-CTF-Reverse-Prompt.md ~/.codex/prompts/ctf-reverse.md</code>
                </div>

                <h3 style="font-size:1.1em;margin:16px 0 10px;">Windows 快捷工具</h3>
                <div class="usage-block">
                    <code>.\tools\prompt-tool.bat</code><br>
                    <code>powershell -ExecutionPolicy Bypass -File .\tools\prompt-tool.ps1</code>
                </div>
            </div>
        </div>

        <!-- CTF Categories -->
        <div class="section">
            <h2 class="lang-en">🛡️ CTF Categories Covered</h2>
            <h2 class="lang-zh">🛡️ 支持的 CTF 类别</h2>

            <div class="cat-grid">
                <div class="cat-item"><span class="tag">RE</span> Reverse Engineering</div>
                <div class="cat-item"><span class="tag">Pwn</span> Binary Exploitation</div>
                <div class="cat-item"><span class="tag">Crypto</span> Cryptography</div>
                <div class="cat-item"><span class="tag">Web</span> Web Security</div>
                <div class="cat-item"><span class="tag">Forensics</span> Digital Forensics</div>
                <div class="cat-item"><span class="tag">Stego</span> Steganography</div>
                <div class="cat-item"><span class="tag">Mobile</span> Mobile Security</div>
                <div class="cat-item"><span class="tag">IoT</span> IoT Security</div>
                <div class="cat-item"><span class="tag">Cloud</span> Cloud Security</div>
            </div>

            <div class="lang-en">
                <p>Full coverage includes static analysis, dynamic debugging, symbolic execution, exploit development, anti-debug bypassing, unpacking, and deobfuscation.</p>
                <p><strong>Full documentation:</strong> <a href="docs/README_en.md">docs/README_en.md</a></p>
            </div>
            <div class="lang-zh">
                <p>完整覆盖包括静态分析、动态调试、符号执行、漏洞利用开发、反调试绕过、脱壳和反混淆。</p>
                <p><strong>完整文档：</strong> <a href="docs/README_zh.md">docs/README_zh.md</a></p>
            </div>
        </div>

        <!-- File Structure -->
        <div class="section">
            <h2 class="lang-en">📁 File Structure</h2>
            <h2 class="lang-zh">📁 文件结构</h2>

            <div class="file-tree">
                <span class="dir">git内容/</span><br>
                ├── <span class="dir">prompts/</span><br>
                │   ├── <span class="file">Claude-CTF-Reverse-Prompt.md</span><br>
                │   ├── <span class="file">Codex-CTF-Reverse-Prompt.md</span><br>
                │   ├── <span class="file">prompt-template.md</span><br>
                │   └── <span class="file">config.json</span><br>
                ├── <span class="dir">tools/</span><br>
                │   ├── <span class="file">prompt-tool.bat</span><br>
                │   └── <span class="file">prompt-tool.ps1</span><br>
                ├── <span class="dir">docs/</span><br>
                │   ├── <span class="file">README_en.md</span><br>
                │   └── <span class="file">README_zh.md</span><br>
                ├── <span class="dir">images/</span><br>
                │   └── <span class="file">b2b81cd407357da51e7990223fe6cf9d.png</span><br>
                └── <span class="file">README.md</span> (this file)<br>
            </div>
        </div>

        <!-- Disclaimer -->
        <div class="section">
            <h2 class="lang-en">⚠️ Disclaimer</h2>
            <h2 class="lang-zh">⚠️ 免责声明</h2>

            <div class="lang-en">
                <p>This project is provided for <strong>CTF competition preparation and authorized security research</strong> only.</p>
                <ul>
                    <li>NOT for commercial software cracking</li>
                    <li>NOT for unauthorized system access</li>
                    <li>NOT for real-world attack deployment</li>
                    <li>NOT for piracy or license bypass</li>
                </ul>
                <p>Please adhere to responsible security research practices.</p>
            </div>

            <div class="lang-zh">
                <p>本项目仅用于 <strong>CTF 竞赛备赛和授权安全研究</strong>。</p>
                <ul>
                    <li>禁止用于商业软件破解</li>
                    <li>禁止用于未授权系统访问</li>
                    <li>禁止用于真实环境攻击部署</li>
                    <li>禁止用于盗版或授权绕过</li>
                </ul>
                <p>请遵守负责任的安全研究实践规范。</p>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            <div class="lang-en">
                <p><a href="https://github.com/nanzhouym/GPT-Claude-instruct">GitHub Repository</a> · Last updated: 2026-07-09</p>
                <p style="margin-top:6px;">Claude Code by Anthropic · Codex by OpenAI · CTF Community</p>
            </div>
            <div class="lang-zh">
                <p><a href="https://github.com/nanzhouym/GPT-Claude-instruct">GitHub 仓库</a> · 最后更新：2026-07-09</p>
                <p style="margin-top:6px;">Claude Code by Anthropic · Codex by OpenAI · CTF 社区</p>
            </div>
        </div>

    </div>

    <script>
        function switchLang(lang) {
            document.body.setAttribute('data-lang', lang);
            document.getElementById('btn-en').classList.toggle('active', lang === 'en');
            document.getElementById('btn-zh').classList.toggle('active', lang === 'zh');
            // Remember preference
            try { localStorage.setItem('readme-lang', lang); } catch(e) {}
        }

        // Restore language preference
        (function() {
            try {
                var saved = localStorage.getItem('readme-lang');
                if (saved) switchLang(saved);
            } catch(e) {}
        })();

        // URL parameter: ?lang=zh
        (function() {
            var params = new URLSearchParams(window.location.search);
            if (params.get('lang') === 'zh') switchLang('zh');
            if (params.get('lang') === 'en') switchLang('en');
        })();
    </script>

</body>
</html>
