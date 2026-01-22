// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/ERC404.sol";
import {ERC404Deposits} from "../contracts/ERC404Deposits.sol";  // 导入整个合约
// 创建一个简单的 ERC404 实现用于测试
// Mock ERC721 Receiver 用于测试 safeTransferFrom
contract MockERC721Receiver {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bool public shouldRevert;
    bool public shouldReturnWrongValue;

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function setShouldReturnWrongValue(bool _shouldReturnWrongValue) external {
        shouldReturnWrongValue = _shouldReturnWrongValue;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (shouldRevert) {
            revert("MockERC721Receiver: revert");
        }
        if (shouldReturnWrongValue) {
            return bytes4(0);
        }
        return _ERC721_RECEIVED;
    }
}

contract TestERC404 is ERC404 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC404(name_, symbol_, decimals_) {}

    // 实现必需的 tokenURI 函数
    function tokenURI(uint256) public pure override returns (string memory) {
        return "test-uri";
    }

    // 添加公共铸造函数用于测试
    function mint(address to, uint256 value) public {
        _mintERC20(to, value);
    }

    // 暴露内部函数用于测试
    function setERC721TransferExempt(address target_, bool state_) public {
        _setERC721TransferExempt(target_, state_);
    }
}

contract ERC404Test is Test {
    struct TokenDeposit {
        address tokenAddress;
        uint256 amount;
    }

    event ApprovalFailed(string message);
    event ApprovalSuccess(string message);
    
    TestERC404 public token;
    MockERC721Receiver public mockReceiver;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    
    uint8 public constant DECIMALS = 18;
    uint256 public constant UNIT = 10 ** DECIMALS;

    function setUp() public {
        // 部署测试合约
        token = new TestERC404("Test Token", "TEST", DECIMALS);
        mockReceiver = new MockERC721Receiver();
        
        // 给测试账户一些 ETH
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
    }

    function testInitialSetup() public {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.units(), UNIT);
    }

    function testMinting() public {
        // 铸造 1 个完整单位的代币
        token.mint(alice, 2*UNIT);
        
        // 检查 ERC20 余额
        assertEq(token.erc20BalanceOf(alice), 2*UNIT);
        
    }

    function testTransferandApprove() public {
        // 先铸造一些代币给 Alice
        token.mint(alice, 10*UNIT);

        // 切换到 Alice 的视角
        vm.startPrank(alice);

        //这里用try catch测试一下approve
        try token.approve(bob, UNIT) {
            emit ApprovalSuccess("approve success");
        } catch (bytes memory) {
            emit ApprovalFailed("approve failed");
        }


        vm.stopPrank();

        vm.startPrank(bob);
        
        token.transferFrom(alice, bob, UNIT);
        //查看一下_storedERC721Ids 具体内容
        uint256[] memory aliceNFTs = token.owned(alice);
        console.log("Alice's NFT IDs:");
        for(uint256 i = 0; i < aliceNFTs.length; i++) {
            console.log("NFT #", i, ":", aliceNFTs[i]);
        }

        if (aliceNFTs.length > 0) {
        ERC404Deposits.TokenDeposit[] memory deposits = token.getTokenDeposits(aliceNFTs[0]);  
        console.log("Alice's deposits for NFT", aliceNFTs[0], ":");
        for(uint256 i = 0; i < deposits.length; i++) {
            console.log("Deposit #1233", i, "amount:", deposits[i].amount);
            console.log("Deposit #", i, "token:", deposits[i].tokenAddress);
        }
        //@audit 我没有默认存储，所以返回了0
        console.log("Alice's deposits length:", deposits.length);   
    } else {
        console.log("Alice has no NFTs");
    }
        vm.stopPrank();
    }

    function testWithdrawAndStoreERC721() public {
        token.mint(alice, 10*UNIT);
        vm.startPrank(alice);
        //获取某个nftid
        uint256[] memory aliceNFTs = token.owned(alice);
        console.log("Alice's NFT ID for deposit:");
        for(uint256 i = 0; i < aliceNFTs.length; i++) {
            console.log("NFT #", i, ":", aliceNFTs[i]);
        }

        token.depositTokens(aliceNFTs[0], address(token), 9*UNIT);
        //查看自己的余额，用console.log
        console.log("Alice's balanceafter!!!:", token.balanceOf(alice));
        uint256[] memory aliceNFTsafter = token.owned(alice);
        console.log("Alice's NFT ID for deposit after!!!:");
        for(uint256 i = 0; i < aliceNFTsafter.length; i++) {
            console.log("NFT #", i, ":", aliceNFTsafter[i]);
        }
    }
    // ============ 更多测试用例 ============

    function testMintingMultipleUnits() public {
        token.mint(alice, 5 * UNIT);
        
        assertEq(token.erc20BalanceOf(alice), 5 * UNIT);
        assertEq(token.erc721BalanceOf(alice), 5);
        
        uint256[] memory ownedNFTs = token.owned(alice);
        assertEq(ownedNFTs.length, 5);
    }

    function testMintingFractionalAmount() public {
        // 铸造 2.5 个单位
        token.mint(alice, 2 * UNIT + UNIT / 2);
        
        assertEq(token.erc20BalanceOf(alice), 2 * UNIT + UNIT / 2);
        // 只有 2 个完整的 NFT
        assertEq(token.erc721BalanceOf(alice), 2);
    }

    function testMintToZeroAddressReverts() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidRecipient()"));
        token.mint(address(0), UNIT);
    }

    function testTransferERC20() public {
        token.mint(alice, 10 * UNIT);
        
        vm.prank(alice);
        token.transfer(bob, 2 * UNIT);
        
        assertEq(token.erc20BalanceOf(alice), 8 * UNIT);
        assertEq(token.erc20BalanceOf(bob), 2 * UNIT);
        assertEq(token.erc721BalanceOf(alice), 8);
        assertEq(token.erc721BalanceOf(bob), 2);
    }

    function testTransferFractionalAmount() public {
        token.mint(alice, 3 * UNIT);
        
        vm.prank(alice);
        // 转账 0.5 个单位，不应该转移 NFT
        token.transfer(bob, UNIT / 2);
        
        assertEq(token.erc20BalanceOf(alice), 2 * UNIT + UNIT / 2);
        assertEq(token.erc20BalanceOf(bob), UNIT / 2);
        // ERC404 设计：转账时不会自动销毁 NFT，只有转账到豁免地址时才会
        // Alice 仍然有 3 个 NFT（因为没有转移完整单位）
        assertEq(token.erc721BalanceOf(alice), 3);
        // Bob 没有完整的单位，所以没有 NFT
        assertEq(token.erc721BalanceOf(bob), 0);
    }

    function testTransferToZeroAddressReverts() public {
        token.mint(alice, UNIT);
        
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("InvalidRecipient()"));
        token.transfer(address(0), UNIT);
    }

    function testApproveAndTransferFrom() public {
        token.mint(alice, 5 * UNIT);
        
        vm.prank(alice);
        token.approve(bob, 2 * UNIT);
        
        assertEq(token.allowance(alice, bob), 2 * UNIT);
        
        vm.prank(bob);
        token.transferFrom(alice, charlie, 2 * UNIT);
        
        assertEq(token.erc20BalanceOf(alice), 3 * UNIT);
        assertEq(token.erc20BalanceOf(charlie), 2 * UNIT);
        assertEq(token.allowance(alice, bob), 0);
    }

    function testUnlimitedApproval() public {
        token.mint(alice, 10 * UNIT);
        
        vm.prank(alice);
        token.approve(bob, type(uint256).max);
        
        vm.prank(bob);
        token.transferFrom(alice, charlie, 5 * UNIT);
        
        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    function testERC721Transfer() public {
        token.mint(alice, 3 * UNIT);
        
        uint256[] memory aliceNFTs = token.owned(alice);
        uint256 tokenId = aliceNFTs[0];
        
        vm.prank(alice);
        token.erc721TransferFrom(alice, bob, tokenId);
        
        assertEq(token.ownerOf(tokenId), bob);
        assertEq(token.erc721BalanceOf(alice), 2);
        assertEq(token.erc721BalanceOf(bob), 1);
    }

    function testSafeTransferFrom() public {
        token.mint(alice, 2 * UNIT);
        
        uint256[] memory aliceNFTs = token.owned(alice);
        uint256 tokenId = aliceNFTs[0];
        
        vm.prank(alice);
        token.safeTransferFrom(alice, address(mockReceiver), tokenId);
        
        assertEq(token.ownerOf(tokenId), address(mockReceiver));
    }

    function testSafeTransferFromToNonReceiverReverts() public {
        token.mint(alice, 2 * UNIT);
        
        uint256[] memory aliceNFTs = token.owned(alice);
        uint256 tokenId = aliceNFTs[0];
        
        mockReceiver.setShouldReturnWrongValue(true);
        
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("UnsafeRecipient()"));
        token.safeTransferFrom(alice, address(mockReceiver), tokenId);
    }

    function testSetApprovalForAll() public {
        token.mint(alice, 3 * UNIT);
        
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        
        assertTrue(token.isApprovedForAll(alice, bob));
        
        uint256[] memory aliceNFTs = token.owned(alice);
        
        vm.prank(bob);
        token.erc721TransferFrom(alice, charlie, aliceNFTs[0]);
        
        assertEq(token.ownerOf(aliceNFTs[0]), charlie);
    }

    function testDepositTokens() public {
        token.mint(alice, 5 * UNIT);
        
        uint256[] memory aliceNFTs = token.owned(alice);
        uint256 tokenId = aliceNFTs[0];
        
        vm.prank(alice);
        token.depositTokens(tokenId, address(token), 1 * UNIT);
        
        ERC404Deposits.TokenDeposit[] memory deposits = token.getTokenDeposits(tokenId);
        assertEq(deposits.length, 1);
        assertEq(deposits[0].amount, 2 * UNIT);
    }

    function testDepositTokensInsufficientBalance() public {
        token.mint(alice, 2 * UNIT);
        
        uint256[] memory aliceNFTs = token.owned(alice);
        uint256 tokenId = aliceNFTs[0];
        
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        token.depositTokens(tokenId, address(token), 3 * UNIT);
    }

    function testDepositTokensUnauthorized() public {
        token.mint(alice, 3 * UNIT);
        
        uint256[] memory aliceNFTs = token.owned(alice);
        uint256 tokenId = aliceNFTs[0];
        
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSignature("Unauthorized()"));
        token.depositTokens(tokenId, address(token), 1 * UNIT);
    }

    function testERC721TransferExempt() public {
        token.setERC721TransferExempt(alice, true);
        
        assertTrue(token.erc721TransferExempt(alice));
        
        token.mint(alice, 5 * UNIT);
        
        assertEq(token.erc721BalanceOf(alice), 0);
        assertEq(token.erc20BalanceOf(alice), 5 * UNIT);
    }

    function testRemoveERC721TransferExempt() public {
        token.setERC721TransferExempt(alice, true);
        token.mint(alice, 3 * UNIT);
        
        assertEq(token.erc721BalanceOf(alice), 0);
        
        token.setERC721TransferExempt(alice, false);
        
        assertEq(token.erc721BalanceOf(alice), 3);
    }

    function testTransferBetweenExemptAndNonExempt() public {
        token.setERC721TransferExempt(alice, true);
        token.mint(alice, 5 * UNIT);
        
        vm.prank(alice);
        token.transfer(bob, 3 * UNIT);
        
        assertEq(token.erc20BalanceOf(bob), 3 * UNIT);
        assertEq(token.erc721BalanceOf(bob), 3);
    }

    function testERC721Queue() public {
        token.mint(alice, 5 * UNIT);
        
        token.setERC721TransferExempt(bob, true);
        
        vm.prank(alice);
        token.transfer(bob, 3 * UNIT);
        
        assertEq(token.getERC721QueueLength(), 3);
    }

    function testRetrieveFromQueue() public {
        token.mint(alice, 5 * UNIT);
        
        token.setERC721TransferExempt(bob, true);
        
        vm.prank(alice);
        token.transfer(bob, 3 * UNIT);
        
        uint256 queueLengthBefore = token.getERC721QueueLength();
        
        vm.prank(bob);
        token.transfer(charlie, 2 * UNIT);
        
        assertEq(token.getERC721QueueLength(), queueLengthBefore - 2);
        assertEq(token.erc721BalanceOf(charlie), 2);
    }

    function testTryGetMoreValue() public {
        token.mint(alice, 5 * UNIT);
        
        uint256 nftCountBefore = token.erc721BalanceOf(alice);
        
        vm.prank(alice);
        token.tryGetMoreValue(2 * UNIT);
        
        assertGe(token.erc721BalanceOf(alice), nftCountBefore);
    }

    function testTryGetMoreValueInsufficientBalance() public {
        token.mint(alice, 1 * UNIT);
        
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        token.tryGetMoreValue(2 * UNIT);
    }

    function testPermit() public {
        uint256 privateKey = 0x1234;
        address signer = vm.addr(privateKey);
        
        token.mint(signer, 5 * UNIT);
        
        uint256 deadline = block.timestamp + 1 hours;
        uint256 value = 2 * UNIT;
        
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                signer,
                bob,
                value,
                token.nonces(signer),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        token.permit(signer, bob, value, deadline, v, r, s);
        
        assertEq(token.allowance(signer, bob), value);
    }

    function testPermitExpiredDeadline() public {
        uint256 privateKey = 0x1234;
        address signer = vm.addr(privateKey);
        
        token.mint(signer, 5 * UNIT);
        
        uint256 deadline = block.timestamp - 1;
        uint256 value = 2 * UNIT;
        
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                signer,
                bob,
                value,
                token.nonces(signer),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        
        vm.expectRevert(abi.encodeWithSignature("PermitDeadlineExpired()"));
        token.permit(signer, bob, value, deadline, v, r, s);
    }

    function testSupportsInterface() public view {
        assertTrue(token.supportsInterface(0x01ffc9a7));
        assertTrue(token.supportsInterface(type(IERC404).interfaceId));
    }

    function testTransferEntireBalance() public {
        token.mint(alice, 3 * UNIT);
        
        vm.prank(alice);
        token.transfer(bob, 3 * UNIT);
        
        assertEq(token.erc20BalanceOf(alice), 0);
        assertEq(token.erc721BalanceOf(alice), 0);
        assertEq(token.erc20BalanceOf(bob), 3 * UNIT);
        assertEq(token.erc721BalanceOf(bob), 3);
    }

    function testMultipleSmallTransfers() public {
        token.mint(alice, 10 * UNIT);
        
        vm.startPrank(alice);
        for (uint256 i = 0; i < 5; i++) {
            token.transfer(bob, UNIT / 10);
        }
        vm.stopPrank();
        
        assertEq(token.erc20BalanceOf(alice), 10 * UNIT - 5 * (UNIT / 10));
        assertEq(token.erc20BalanceOf(bob), 5 * (UNIT / 10));
    }

    function testGasForLargeTransfer() public {
        token.mint(alice, 100 * UNIT);
        
        uint256 gasBefore = gasleft();
        vm.prank(alice);
        token.transfer(bob, 50 * UNIT);
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Gas used for 50 unit transfer:", gasUsed);
        
        assertEq(token.erc20BalanceOf(bob), 50 * UNIT);
        assertEq(token.erc721BalanceOf(bob), 50);
    }
}
