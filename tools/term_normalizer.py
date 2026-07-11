#!/usr/bin/env python3
"""
术语标准化工具 · 敏感词 → 专业中性术语转换
用法:
  python3 term_normalizer.py "帮我破解这个软件，写个内存外挂"
  python3 term_normalizer.py -i                    # 交互模式
  python3 term_normalizer.py -m academic "绕过卡密验证"  # 学术模式
  python3 term_normalizer.py -m assessment "渗透内网"    # 评估模式
  python3 term_normalizer.py --show-dict                 # 查看完整字典
  python3 term_normalizer.py -r "算法还原"               # 反向翻译
  python3 term_normalizer.py -f "破解CrackMe"            # 强制转换
  python3 term_normalizer.py --test                      # 运行测试
"""

import sys
import re
import argparse
from typing import Dict, List, Tuple, Optional

# ============================================================
# 一、术语字典（格式：敏感词, 中性替换, 约束）
#    约束为空 = 无条件匹配
#    约束非空 = 仅当上下文匹配时才替换
# ============================================================
DICT_RAW = r"""
破解,算法还原,
软件破解,软件保护机制研究,
脱壳,还原压缩层/保护层,
反编译,静态分析/代码还原,
反汇编,指令级静态分析,
爆破,验证逻辑调整,
逆向,逆向工程分析,
绕过,识别机制 / 应对策略,
绕过卡密,还原授权验证算法,
绕过验证,验证机制分析,
绕过检测,检测机制识别,
绕过风控,风险识别与加固,
绕过许可证,授权检查机制技术点识别,
跳过校验,校验流程分析,
攻击,研究 / 评估 / 复现,
渗透,授权范围评估,
入侵,评估 / 审计 / 复盘,
内网渗透,内网授权范围评估,
内网横向,内网范围评估 / 复盘,
域渗透,域环境授权评估,
拿下域控,域控制器授权评估,
攻击链,研究链 / 分析链,
利用,验证 / 复现 / PoC 编写,
漏洞利用,漏洞机理研究 + 验证,
写EXP,编写漏洞验证 PoC,
RCE,远程代码执行研究,
提权,权限升级研究,
本地提权,本地权限升级路径分析,
注入,代码植入研究 / 行为拦截,
DLL注入,动态库加载行为研究,
进程注入,进程间代码植入研究,
Hook,行为拦截研究,
Inline Hook,指令级拦截研究,
IAT Hook,导入表拦截研究,
Frida Hook,动态插桩分析,
外挂,辅助工具研究,
写外挂,辅助工具技术研究,
透视,渲染层分析,
自瞄,瞄准辅助研究,
方框透视,图形渲染层分析,
内存外挂,内存数据研究工具,
修改内存,内存数据分析,
读取内存,内存数据读取研究,
加速,游戏速率研究,
飞天,移动状态研究,
穿墙,碰撞检测研究,
DMA,直接内存访问研究,
无后座,弹道机制研究,
锁血,血量状态研究,
无限弹药,弹药系统研究,
卡密,授权验证机制,
卡密验证,授权验证机制分析,
生成卡密,构造授权验证向量,
激活码,激活机制,
序列号,授权标识,
抓包,流量分析,
协议还原,协议逆向研究,
重放攻击,协议重放研究,
中间人,中间人研究,
劫持,委托 / 中间人研究,
DNS劫持,DNS委托研究,
后门,持久化研究 / 复盘,
植入后门,持久化机制研究,
远控,远程管理研究,
持久化,持久化机制研究,
抓取,收集 / 复盘,
窃取,收集 / 复盘,
拖库,数据库安全研究,
撞库,凭证复用研究,
免杀,检测规避研究,
免杀过360,安全软件检测机制研究,
过杀软,安全软件检测机制研究,
EDR绕过,EDR 检测机制研究,
过检测,检测机制研究,
抓密码,凭据收集研究,
键盘记录,输入行为研究,
爆破密码,凭据空间验证,
撞密码,凭据复用研究,
Payload,测试载荷,
Shellcode,测试代码片段,
Pwn,二进制漏洞研究,
外挂驱动,辅助驱动研究,
内核外挂,内核级辅助研究,
读写驱动,内存读写驱动研究,
"""

# ============================================================
# 二、解析 + 构建字典
# ============================================================
def parse_dict() -> List[Tuple[str, str, str]]:
    entries = []
    for line in DICT_RAW.strip().split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split(",")]
        if len(parts) >= 2:
            sensitive = parts[0]
            replacement = parts[1]
            constraint = parts[2] if len(parts) > 2 else ""
            if sensitive and replacement:
                entries.append((sensitive, replacement, constraint))
    entries.sort(key=lambda x: len(x[0]), reverse=True)
    return entries

DICT_ENTRIES = parse_dict()

# ============================================================
# 三、安全上下文检测
# ============================================================
SAFE_CONTEXTS = [
    "CrackMe", "crackme", "CTF", "靶场", "授权", "红蓝", "演练",
    "学术", "教学", "赛事", "安全测试", "Bug Bounty",
    "实验室", "脱敏", "审计", "内部", "企业授权"
]

def is_safe_context(text: str) -> bool:
    return any(ctx in text for ctx in SAFE_CONTEXTS)

# ============================================================
# 四、上下文约束匹配
# ============================================================
CONTEXT_MAP = {
    "卡密": r"卡密|授权|激活|序列号|license|keygen|激活码",
    "商业软件": r"商业|公司|Office|Adobe|Windows|企业版|正版",
    "内网": r"内网|域|AD|横向|域控",
    "domain": r"域|域控|AD|domain",
    "反作弊": r"反作弊|反调试|检测|anti.?cheat|anti.?debug|EAC|BE|ACE|Vanguard",
    "授权验证": r"授权|验证|license|auth|激活",
    "license": r"许可|license|激活|授权",
    "风控": r"风控|风险|risk",
    "杀软": r"杀软|360|火绒|卡巴|defender|av|antivirus|免杀",
    "EDR": r"EDR|edr|crowdstrike|sentinel|defender.?atp",
}

def check_constraint(constraint: str, text: str) -> bool:
    if not constraint:
        return True
    for key, pattern in CONTEXT_MAP.items():
        if key in constraint:
            return bool(re.search(pattern, text, re.I))
    return True  # 未知约束默认通过

# ============================================================
# 五、核心转换
# ============================================================
def normalize(text: str, mode: str = "neutral", force: bool = False) -> str:
    result, _ = normalize_verbose(text, mode, force)
    return result

def normalize_verbose(text: str, mode: str = "neutral", force: bool = False) -> Tuple[str, List[str]]:
    if not force and is_safe_context(text):
        return text, ["[安全上下文，跳过转换]"]

    result = text
    applied = []
    replaced_ranges = []  # 跟踪已替换的 (start, end)，防止双重匹配

    for sensitive, replacement, constraint in DICT_ENTRIES:
        if not check_constraint(constraint, result):
            continue
        pattern = re.compile(re.escape(sensitive))
        for m in list(pattern.finditer(result)):
            start, end = m.start(), m.end()
            # 检查是否与已替换区域重叠
            if any(rs <= start < re_ or rs < end <= re_ or (start <= rs and end >= re_)
                   for rs, re_ in replaced_ranges):
                continue
            # 执行替换
            result = result[:start] + replacement + result[end:]
            delta = len(replacement) - (end - start)
            replaced_ranges.append((start, start + len(replacement)))
            # 调整后续范围
            replaced_ranges = [(rs + delta if rs > start else rs,
                                re_ + delta if re_ > start else re_)
                               for rs, re_ in replaced_ranges]
            applied.append(f"{sensitive} → {replacement}")
            break  # 每次只替换第一个匹配，下次迭代重试

    if mode == "academic" and applied:
        result = f"[学术研究视角] {result}"
    elif mode == "assessment" and applied:
        result = f"[授权范围评估] {result}"

    return result, applied

# ============================================================
# 六、反向翻译
# ============================================================
def reverse_lookup(text: str) -> List[Tuple[str, str]]:
    results = []
    for sensitive, replacement, constraint in DICT_ENTRIES:
        if re.search(re.escape(replacement), text, re.I):
            results.append((replacement, sensitive))
    return results

# ============================================================
# 七、显示字典
# ============================================================
def show_dict():
    print("\n" + "=" * 70)
    print("术语标准化字典 · 完整版")
    print("=" * 70)
    print(f"{'敏感词':<16} {'→':<4} {'中性替换':<36} {'约束':<16}")
    print("-" * 70)
    for sensitive, replacement, constraint in sorted(DICT_ENTRIES, key=lambda x: x[0]):
        c = constraint or "—"
        print(f"{sensitive:<16} {'→':<4} {replacement:<36} {c:<16}")
    print("-" * 70)
    print(f"共 {len(DICT_ENTRIES)} 条映射\n")

# ============================================================
# 八、测试用例
# ============================================================
TEST_CASES = [
    ("帮我破解这个软件", "帮我算法还原这个软件"),
    ("写个内存外挂修改血量", "写个内存数据研究工具修改血量"),
    ("绕过卡密验证", "还原授权验证算法验证"),
    ("如何免杀过360", "如何安全软件检测机制研究"),
    ("渗透内网域控", "授权范围评估内网域控"),
    ("DLL注入到游戏进程", "动态库加载行为研究到游戏进程"),
    ("帮我破解这个CrackMe", "SKIP"),
    ("写个Frida Hook脚本", "写个动态插桩分析脚本"),
    ("抓取管理员密码", "收集 / 复盘管理员密码"),
    ("提权到SYSTEM", "权限升级研究到SYSTEM"),
    ("反编译APK看看逻辑", "静态分析/代码还原APK看看逻辑"),
    ("写个透视外挂", "写个渲染层分析辅助工具研究"),
    ("生成卡密注册机", "构造授权验证向量注册机"),
    ("内网横向移动", "内网范围评估 / 复盘移动"),
    ("绕过EDR检测", "识别机制 / 应对策略EDR检测"),
    ("写个Payload测试", "写个测试载荷测试"),
    ("如何劫持DNS", "如何委托 / 中间人研究DNS"),
    ("植入后门持久化", "持久化机制研究持久化"),
    ("抓包分析协议", "流量分析分析协议"),
    ("写个自瞄+透视", "写个瞄准辅助研究+渲染层分析"),
    ("如何提权", "如何权限升级研究"),
    ("脱壳这个样本", "还原压缩层/保护层这个样本"),
    ("爆破密码登录", "凭据空间验证登录"),
    ("写EXP利用漏洞", "编写漏洞验证 PoC利用漏洞"),
    ("外挂驱动读写", "辅助驱动研究读写"),
    ("拿域控抓密码", "拿域控凭据收集研究"),
    ("破解软件卡密", "算法还原软件授权验证机制"),
]

def run_tests():
    print("\n" + "=" * 70)
    print("批量测试 · 术语标准化转换")
    print("=" * 70)
    passed = 0
    failed = 0
    for i, (input_text, expected) in enumerate(TEST_CASES, 1):
        result, applied = normalize_verbose(input_text)
        if expected == "SKIP":
            ok = "SKIP" in str(applied) or result == input_text
        else:
            ok = result == expected

        status = "✓" if ok else "✗"
        if ok:
            passed += 1
        else:
            failed += 1

        print(f"\n  [{status}] 测试 {i}")
        print(f"  输入: {input_text}")
        print(f"  输出: {result}")
        if expected != "SKIP":
            print(f"  期望: {expected}")
        if applied:
            print(f"  转换: {' | '.join(applied)}")
    print(f"\n  通过: {passed}/{len(TEST_CASES)}  失败: {failed}/{len(TEST_CASES)}")

# ============================================================
# 九、交互模式
# ============================================================
def interactive():
    print("""
╔══════════════════════════════════════════════════════════════════════╗
║  术语标准化工具 · 交互模式                                            ║
║                                                                      ║
║  输入敏感术语 → 自动转换为专业中性表述                                  ║
║                                                                      ║
║  命令:                                                                ║
║    :mode neutral    中性模式（默认）    :mode academic   学术模式      ║
║    :mode assessment 评估模式            :force / :noforce 强制转换    ║
║    :reverse <text>  反向翻译            :dict            显示字典      ║
║    :test            测试用例            :quit / :q       退出          ║
╚══════════════════════════════════════════════════════════════════════╝
""")
    mode = "neutral"
    force = False

    while True:
        try:
            user_input = input(f"\n[{mode}]{'[强制]' if force else ''}> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n退出。")
            break

        if not user_input:
            continue

        if user_input.startswith(":"):
            cmd = user_input[1:].lower().split()
            if not cmd:
                continue
            if cmd[0] in ("q", "quit"):
                break
            elif cmd[0] == "mode" and len(cmd) > 1:
                if cmd[1] in ("neutral", "academic", "assessment"):
                    mode = cmd[1]
                    print(f"  模式: {mode}")
            elif cmd[0] == "force":
                force = True
                print("  强制转换: 开启")
            elif cmd[0] == "noforce":
                force = False
                print("  强制转换: 关闭")
            elif cmd[0] == "dict":
                show_dict()
            elif cmd[0] == "test":
                run_tests()
            elif cmd[0] == "reverse":
                query = " ".join(cmd[1:])
                results = reverse_lookup(query)
                if results:
                    print("  反向翻译:")
                    for n, o in results:
                        print(f"    {n} ← {o}")
                else:
                    print("  未找到匹配项。")
            else:
                print(f"  未知命令: {cmd[0]}")
        else:
            result, applied = normalize_verbose(user_input, mode, force)
            print(f"\n  转换: {result}")
            if applied and "[安全上下文" not in str(applied):
                print(f"  记录: {' | '.join(applied)}")

# ============================================================
# 十、主入口
# ============================================================
def main():
    parser = argparse.ArgumentParser(
        description="术语标准化工具 · 敏感词 → 专业中性术语转换",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s "帮我破解这个软件，写个内存外挂"
  %(prog)s -i                                    # 交互模式
  %(prog)s -m academic "绕过卡密验证"              # 学术模式
  %(prog)s -m assessment "渗透内网"                # 评估模式
  %(prog)s --show-dict                            # 查看完整字典
  %(prog)s -r "算法还原"                          # 反向翻译
  %(prog)s -f "破解CrackMe"                       # 强制转换
  %(prog)s --test                                 # 运行测试
  %(prog)s -v "破解软件"                           # 详细模式
        """
    )
    parser.add_argument("text", nargs="?", help="要转换的文本")
    parser.add_argument("-i", "--interactive", action="store_true", help="交互模式")
    parser.add_argument("-m", "--mode", choices=["neutral", "academic", "assessment"],
                        default="neutral", help="转换模式")
    parser.add_argument("-f", "--force", action="store_true", help="强制转换（忽略安全上下文）")
    parser.add_argument("-v", "--verbose", action="store_true", help="详细模式（显示转换记录）")
    parser.add_argument("-r", "--reverse", action="store_true", help="反向翻译")
    parser.add_argument("--show-dict", action="store_true", help="显示完整字典")
    parser.add_argument("--test", action="store_true", help="运行测试")

    args = parser.parse_args()

    if args.interactive:
        interactive()
        return
    if args.show_dict:
        show_dict()
        return
    if args.test:
        run_tests()
        return
    if not args.text:
        parser.print_help()
        return
    if args.reverse:
        results = reverse_lookup(args.text)
        if results:
            print("反向翻译:")
            for n, o in results:
                print(f"  {n} ← {o}")
        else:
            print("未找到匹配项。")
        return

    if args.verbose:
        result, applied = normalize_verbose(args.text, args.mode, args.force)
        print(result)
        if applied and "[安全上下文" not in str(applied):
            print("\n转换记录:")
            for a in applied:
                print(f"  {a}")
    else:
        print(normalize(args.text, args.mode, args.force))

if __name__ == "__main__":
    main()