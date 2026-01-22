//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC404} from "./interfaces/IERC404.sol";
import {DoubleEndedQueue} from "./lib/DoubleEndedQueue.sol";
import {ERC721Events} from "./lib/ERC721Events.sol";
import {ERC20Events} from "./lib/ERC20Events.sol";
import {ERC404Deposits} from "./ERC404Deposits.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract ERC404 is IERC404, ERC404Deposits {
  using DoubleEndedQueue for DoubleEndedQueue.Uint256Deque;

  /// @dev The queue of ERC-721 tokens stored in the contract.
  DoubleEndedQueue.Uint256Deque private _storedERC721Ids;
  
  /// @dev Token name
  string public name;

  /// @dev Token symbol
  string public symbol;

  /// @dev Decimals for ERC-20 representation
  uint8 public immutable decimals;

  /// @dev Units for ERC-20 representation
  uint256 public immutable units;

  /// @dev Total supply in ERC-20 representation
  uint256 public totalSupply;

  /// @dev Current mint counter which also represents the highest minted id
  uint256 public minted;

  /// @dev Initial chain id for EIP-2612 support
  uint256 internal immutable _INITIAL_CHAIN_ID;

  /// @dev Initial domain separator for EIP-2612 support
  bytes32 internal immutable _INITIAL_DOMAIN_SEPARATOR;

  /// @dev Tracks if an NFT has been split
  mapping(uint256 => bool) internal _isSplit;

  /// @dev Balance of user in ERC-20 representation
  mapping(address => uint256) public balanceOf;

  /// @dev Allowance of user in ERC-20 representation
  mapping(address => mapping(address => uint256)) public allowance;

  /// @dev Approval in ERC-721 representation
  mapping(uint256 => address) public getApproved;

  /// @dev Approval for all in ERC-721 representation
  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /// @dev Packed representation of ownerOf and owned indices
  mapping(uint256 => uint256) internal _ownedData;

  /// @dev Array of owned ids in ERC-721 representation
  mapping(address => uint256[]) internal _owned;

  /// @dev Addresses that are exempt from ERC-721 transfer
  mapping(address => bool) internal _erc721TransferExempt;

  /// @dev EIP-2612 nonces
  mapping(address => uint256) public nonces;

  /// @dev Address bitmask for packed ownership data
  uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

  /// @dev Owned index bitmask for packed ownership data
  uint256 private constant _BITMASK_OWNED_INDEX = ((1 << 96) - 1) << 160;

  /// @dev Constant for token id encoding
  uint256 public constant ID_ENCODING_PREFIX = 1 << 255;

  error InvalidAmount();

  constructor(string memory name_, string memory symbol_, uint8 decimals_) {
    name = name_;
    symbol = symbol_;

    if (decimals_ < 18) {
      revert DecimalsTooLow();
    }

    decimals = decimals_;
    units = 10 ** decimals;

    // EIP-2612 initialization
    _INITIAL_CHAIN_ID = block.chainid;
    _INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
  }

  /// @notice Function to find owner of a given ERC-721 token
  function ownerOf(uint256 id_) public view virtual returns (address erc721Owner) {
    erc721Owner = _getOwnerOf(id_);

    if (!_isValidTokenId(id_)) {
      revert InvalidTokenId();
    }

    if (erc721Owner == address(0)) {
      revert NotFound();
    }
  }

  function owned(address owner_) public view virtual returns (uint256[] memory) {
    return _owned[owner_];
  }

  function erc721BalanceOf(address owner_) public view virtual returns (uint256) {
    return _owned[owner_].length;
  }

  function erc20BalanceOf(address owner_) public view virtual returns (uint256) {
    return balanceOf[owner_];
  }

  function erc20TotalSupply() public view virtual returns (uint256) {
    return totalSupply;
  }

  function erc721TotalSupply() public view virtual returns (uint256) {
    return minted;
  }

  /// @notice 获取当前存储在队列中的ERC721代币数量
  function getERC721QueueLength() public view virtual returns (uint256) {
    return _storedERC721Ids.length();
  }

  /// @notice 获取队列中指定范围的ERC721代币ID
  function getERC721TokensInQueue(
    uint256 start_,
    uint256 count_
  ) public view virtual returns (uint256[] memory) {
    uint256[] memory tokensInQueue = new uint256[](count_);

    for (uint256 i = start_; i < start_ + count_; ) {
      tokensInQueue[i - start_] = _storedERC721Ids.at(i);
      unchecked {
        ++i;
      }
    }

    return tokensInQueue;
  }

  /// @notice tokenURI must be implemented by child contract
  function tokenURI(uint256 id_) public view virtual returns (string memory);
  
  /// @notice ERC-20/ERC-721 approve function
  function approve(address spender_, uint256 value_) public virtual returns (bool) {
    if (spender_ == address(0)) {
      revert InvalidSpender();
    }
    
    if (_isValidTokenId(value_)) {
      erc721Approve(spender_, value_);
    } else {
      allowance[msg.sender][spender_] = value_;
      emit ERC20Events.Approval(msg.sender, spender_, value_);
    }
    return true;
  }

  function erc721Approve(address spender_, uint256 id_) public virtual {
    address erc721Owner = _getOwnerOf(id_);

    if (msg.sender != erc721Owner && !isApprovedForAll[erc721Owner][msg.sender]) {
      revert Unauthorized();
    }

    getApproved[id_] = spender_;
    emit ERC721Events.Approval(erc721Owner, spender_, id_);
  }

  /// @notice Function for ERC-721 approvals
  function setApprovalForAll(address operator_, bool approved_) public virtual {
    if (operator_ == address(0)) {
      revert InvalidOperator();
    }
    isApprovedForAll[msg.sender][operator_] = approved_;
    emit ERC721Events.ApprovalForAll(msg.sender, operator_, approved_);
  }

  /// @notice 用于混合转账的函数
  function transferFrom(
    address from_,
    address to_,
    uint256 valueOrId_
  ) public virtual returns (bool) {
    if (_isValidTokenId(valueOrId_)) {
      erc721TransferFrom(from_, to_, valueOrId_);
    } else {
      return erc20TransferFrom(from_, to_, valueOrId_);
    }
    return true;
  }

  function erc721TransferFrom(address from_, address to_, uint256 id_) public virtual {
    if (from_ == address(0)) {
      revert InvalidSender();
    }

    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    if (from_ != _getOwnerOf(id_)) {
      revert Unauthorized();
    }

    if (
      msg.sender != from_ &&
      !isApprovedForAll[from_][msg.sender] &&
      msg.sender != getApproved[id_]
    ) {
      revert Unauthorized();
    }

    if (erc721TransferExempt(to_)) {
      revert RecipientIsERC721TransferExempt();
    }

    _transferERC721(from_, to_, id_);
  }

  function erc20TransferFrom(
    address from_,
    address to_,
    uint256 value_
  ) public virtual returns (bool) {
    if (from_ == address(0)) {
      revert InvalidSender();
    }

    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    uint256 allowed = allowance[from_][msg.sender];

    if (allowed != type(uint256).max) {
      allowance[from_][msg.sender] = allowed - value_;
    }

    return _transferERC20WithERC721(from_, to_, value_);
  }

  /// @notice Function for ERC-20 transfers.
  function transfer(address to_, uint256 value_) public virtual returns (bool) {
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }
    return _transferERC20WithERC721(msg.sender, to_, value_);
  }

  /// @notice Function for ERC-721 transfers with contract support.
  function safeTransferFrom(address from_, address to_, uint256 id_) public virtual {
    safeTransferFrom(from_, to_, id_, "");
  }

  /// @notice Function for ERC-721 transfers with contract support and callback data.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 id_,
    bytes memory data_
  ) public virtual {
    if (!_isValidTokenId(id_)) {
      revert InvalidTokenId();
    }

    transferFrom(from_, to_, id_);

    if (
      to_.code.length != 0 &&
      IERC721Receiver(to_).onERC721Received(msg.sender, from_, id_, data_) !=
      IERC721Receiver.onERC721Received.selector
    ) {
      revert UnsafeRecipient();
    }
  }

  /// @notice EIP-2612 permit function
  function permit(
    address owner_,
    address spender_,
    uint256 value_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) public virtual {
    if (deadline_ < block.timestamp) {
      revert PermitDeadlineExpired();
    }

    if (_isValidTokenId(value_)) {
      revert InvalidApproval();
    }

    if (spender_ == address(0)) {
      revert InvalidSpender();
    }

    unchecked {
      address recoveredAddress = ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR(),
            keccak256(
              abi.encode(
                keccak256(
                  "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner_,
                spender_,
                value_,
                nonces[owner_]++,
                deadline_
              )
            )
          )
        ),
        v_,
        r_,
        s_
      );

      if (recoveredAddress == address(0) || recoveredAddress != owner_) {
        revert InvalidSigner();
      }

      allowance[recoveredAddress][spender_] = value_;
    }

    emit ERC20Events.Approval(owner_, spender_, value_);
  }

  /// @notice Returns domain separator
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == _INITIAL_CHAIN_ID
        ? _INITIAL_DOMAIN_SEPARATOR
        : _computeDomainSeparator();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == type(IERC404).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /// @notice 设置自己为ERC721豁免
  function setSelfERC721TransferExempt(bool state_) public virtual {
    _setERC721TransferExempt(msg.sender, state_);
  }

  /// @notice Function to check if address is transfer exempt
  function erc721TransferExempt(address target_) public view virtual returns (bool) {
    return target_ == address(0) || _erc721TransferExempt[target_];
  }

  /// @notice 判断代币ID是否有效
  function _isValidTokenId(uint256 id_) internal pure returns (bool) {
    return id_ > ID_ENCODING_PREFIX && id_ != type(uint256).max;
  }

  /// @notice Internal function to compute domain separator for EIP-2612 permits
  function _computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256(bytes(name)),
          keccak256("1"),
          block.chainid,
          address(this)
        )
      );
  }

  /// @notice 底层 ERC-20 转账函数
  function _transferERC20(address from_, address to_, uint256 value_) internal virtual {
    if (from_ == address(0)) {
      totalSupply += value_;
    } else {
      balanceOf[from_] -= value_;
    }

    unchecked {
      balanceOf[to_] += value_;
    }

    emit ERC20Events.Transfer(from_, to_, value_);
  }

  /// @notice 转移 ERC721 及其内部存储的 ERC20 资产
  function _transferERC721(address from_, address to_, uint256 id_) internal virtual {
    // 转移与NFT关联的所有存款
    _transferDeposits(id_, from_, to_);
    
    // 执行NFT转移
    _setOwnerOf(id_, to_);

    // 只有当 from_ 不是零地址时才更新发送者的数组
    if (from_ != address(0)) {
      uint256 updatedId = _owned[from_][_owned[from_].length - 1];
      uint256 index = _getOwnedIndex(id_);
      _owned[from_][index] = updatedId;
      _owned[from_].pop();
      _setOwnedIndex(updatedId, index);
    }

    // 更新接收者的 owned 数组（排除零地址）
    if (to_ != address(0)) {
      _owned[to_].push(id_);
      _setOwnedIndex(id_, _owned[to_].length - 1);
    }
    
    // 清除授权
    delete getApproved[id_];

    emit ERC721Events.Transfer(from_, to_, id_);
  }

  /// @notice ERC-20转账的内部函数，同时处理可能需要的ERC-721转账
  function _transferERC20WithERC721(
    address from_,
    address to_,
    uint256 value_
  ) internal virtual returns (bool) {
    uint256 erc20BalanceOfSenderBefore = erc20BalanceOf(from_);
    uint256 erc20BalanceOfReceiverBefore = erc20BalanceOf(to_);

    _transferERC20(from_, to_, value_);

    bool isFromERC721TransferExempt = erc721TransferExempt(from_);
    bool isToERC721TransferExempt = erc721TransferExempt(to_);

    if (isFromERC721TransferExempt && isToERC721TransferExempt) {
      // 情况1) 发送者和接收者都是ERC-721豁免
    } else if (isFromERC721TransferExempt) {
      // 情况2) 发送者是ERC-721豁免，接收者不是
      uint256 tokensToRetrieveOrMint = (balanceOf[to_] / units) -
        (erc20BalanceOfReceiverBefore / units);
      for (uint256 i = 0; i < tokensToRetrieveOrMint; ) {
        _retrieveOrMintERC721(to_, units, false);
        unchecked {
          ++i;
        }
      }
    } else if (isToERC721TransferExempt) {
      // 情况3) 发送者不是ERC-721豁免，接收者是
      uint256 tokensToWithdrawAndStore = (erc20BalanceOfSenderBefore / units) -
        (balanceOf[from_] / units);
      for (uint256 i = 0; i < tokensToWithdrawAndStore; ) {
        _withdrawAndStoreERC721(from_);
        unchecked {
          ++i;
        }
      }
    } else {
      // 情况4) 发送者和接收者都不是ERC-721豁免
      uint256 nftsToTransfer = value_ / units;
      for (uint256 i = 0; i < nftsToTransfer; ) {
        uint256 indexOfLastToken = _owned[from_].length - 1;
        uint256 tokenId = _owned[from_][indexOfLastToken];
        _transferERC721(from_, to_, tokenId);
        unchecked {
          ++i;
        }
      }
    }

    return true;
  }

  /// @notice Internal function for ERC20 minting
  function _mintERC20(address to_, uint256 value_) internal virtual {
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    if (totalSupply + value_ > ID_ENCODING_PREFIX) {
      revert MintLimitReached();
    }

    _transferERC20WithERC721(address(0), to_, value_);
  }

  /// @notice ERC-721代币铸造和从银行取回的内部函数
  function _retrieveOrMintERC721(
    address to_, 
    uint256 availableAmount_,
    bool singleNFT_
  ) internal virtual {
    if (to_ == address(0)) {
      revert InvalidRecipient();
    }

    if (singleNFT_) {
      _retrieveSingleNFT(to_, availableAmount_);
    } else {
      _retrieveMultipleNFTs(to_, availableAmount_);
    }
  }

  /// @notice 内部函数：获取单个特定价值的NFT
  function _retrieveSingleNFT(address to_, uint256 targetAmount_) internal virtual {
    if (!_storedERC721Ids.empty()) {
      uint256 storedIdsLength = _storedERC721Ids.length();
      
      for (uint256 i = 0; i < storedIdsLength; i++) {
        uint256 candidateId = _storedERC721Ids.at(i);
        uint256 requiredAmount = _requiredAmount[candidateId];
        
        if (requiredAmount == targetAmount_ && _canRestoreNFT(candidateId)) {
          // 从队列中移除找到的元素
          _removeFromQueue(i);
          _handleNFTRestore(candidateId);
          _transferERC721(address(0), to_, candidateId);
          return;
        }
      }
    }
    
    // 如果没找到匹配的，尝试拆分为多个价值为1的NFT
    _retrieveMultipleNFTs(to_, targetAmount_);
  }

  /// @notice 内部函数：获取多个价值为1的NFT
  function _retrieveMultipleNFTs(address to_, uint256 availableAmount_) internal virtual {
    uint256 nftsToMint = availableAmount_ / units;
    
    for (uint256 i = 0; i < nftsToMint;) {
      bool found = false;
      
      if (!_storedERC721Ids.empty()) {
        uint256 storedIdsLength = _storedERC721Ids.length();
        
        for (uint256 j = 0; j < storedIdsLength && !found; j++) {
          uint256 candidateId = _storedERC721Ids.at(j);
          if (_requiredAmount[candidateId] == units && _canRestoreNFT(candidateId)) {
            _removeFromQueue(j);
            _handleNFTRestore(candidateId);
            _transferERC721(address(0), to_, candidateId);
            found = true;
          }
        }
      }
      
      // 如果没找到价值为1的NFT，铸造新的
      if (!found) {
        ++minted;
        if (minted == type(uint256).max) {
          revert MintLimitReached();
        }
        uint256 newId = ID_ENCODING_PREFIX + minted;
        _transferERC721(address(0), to_, newId);
        
        // 为新铸造的NFT添加初始存款记录
        _tokenDeposits[newId].push(TokenDeposit({
          tokenAddress: address(this),
          amount: units
        }));
      }
      
      unchecked { ++i; }
    }
  }

  /// @notice 从队列中移除指定索引的元素
  function _removeFromQueue(uint256 index_) internal {
    uint256 length = _storedERC721Ids.length();
    
    if (index_ == 0) {
      _storedERC721Ids.popFront();
    } else if (index_ == length - 1) {
      _storedERC721Ids.popBack();
    } else {
      // 对于中间元素，我们需要重新构建队列
      // 保存要删除位置之后的所有元素
      uint256[] memory temp = new uint256[](length - index_ - 1);
      for (uint256 k = 0; k < temp.length; k++) {
        temp[k] = _storedERC721Ids.at(index_ + 1 + k);
      }
      
      // 从后往前弹出到要删除的位置（包括要删除的元素）
      for (uint256 k = 0; k < length - index_; k++) {
        _storedERC721Ids.popBack();
      }
      
      // 重新添加保存的元素
      for (uint256 k = 0; k < temp.length; k++) {
        _storedERC721Ids.pushBack(temp[k]);
      }
    }
  }

  /// @notice 内部函数,用于将ERC-721存入银行
  function _withdrawAndStoreERC721(address from_) internal virtual {
    if (from_ == address(0)) {
      revert InvalidSender();
    }

    uint256 id = _owned[from_][_owned[from_].length - 1];

    // 在NFT被拆分前保存存款记录
    _handleNFTSplit(id);
    _isSplit[id] = true;

    // 转移到0地址
    _transferERC721(from_, address(0), id);

    // 将代币记录到合约的银行队列中
    _storedERC721Ids.pushFront(id);
  }

  function _setERC721TransferExempt(address target_, bool state_) internal virtual {
    if (target_ == address(0)) {
      revert InvalidExemption();
    }
    if (state_) {
      _clearERC721Balance(target_);
    } else {
      _reinstateERC721Balance(target_);
    }

    _erc721TransferExempt[target_] = state_;
  }

  /// @notice 当地址从豁免名单中移除时恢复其 ERC721 余额
  function _reinstateERC721Balance(address target_) private {
    uint256 expectedERC721Balance = erc20BalanceOf(target_) / units;
    uint256 actualERC721Balance = erc721BalanceOf(target_);

    for (uint256 i = 0; i < expectedERC721Balance - actualERC721Balance; ) {
      _retrieveOrMintERC721(target_, units, false);
      unchecked {
        ++i;
      }
    }
  }

  /// @notice 尝试获取更高价值的NFT
  /// @dev 将用户的代币转入合约，获取一个高价值NFT，然后返还代币
  function tryGetMoreValue(uint256 amountIn_) public {
    require(amountIn_ > 0, "Amount must be greater than 0");
    require(balanceOf[msg.sender] >= amountIn_, "Insufficient balance");
    
    _transferERC20WithERC721(msg.sender, address(this), amountIn_);
    _retrieveOrMintERC721(msg.sender, amountIn_, true);
    _transferERC20(address(this), msg.sender, amountIn_);
  }

  /// @notice Function to clear balance on exemption inclusion
  function _clearERC721Balance(address target_) private {
    uint256 erc721Balance = erc721BalanceOf(target_);

    for (uint256 i = 0; i < erc721Balance; ) {
      _withdrawAndStoreERC721(target_);
      unchecked {
        ++i;
      }
    }
  }

  function _getOwnerOf(uint256 id_) internal view virtual returns (address ownerOf_) {
    uint256 data = _ownedData[id_];

    assembly {
      ownerOf_ := and(data, _BITMASK_ADDRESS)
    }
  }

  function _setOwnerOf(uint256 id_, address owner_) internal virtual {
    uint256 data = _ownedData[id_];

    assembly {
      data := add(
        and(data, _BITMASK_OWNED_INDEX),
        and(owner_, _BITMASK_ADDRESS)
      )
    }

    _ownedData[id_] = data;
  }

  function _getOwnedIndex(uint256 id_) internal view virtual returns (uint256 ownedIndex_) {
    uint256 data = _ownedData[id_];

    assembly {
      ownedIndex_ := shr(160, data)
    }
  }

  function _setOwnedIndex(uint256 id_, uint256 index_) internal virtual {
    uint256 data = _ownedData[id_];

    if (index_ > _BITMASK_OWNED_INDEX >> 160) {
      revert OwnedIndexOverflow();
    }

    assembly {
      data := add(
        and(data, _BITMASK_ADDRESS),
        and(shl(160, index_), _BITMASK_OWNED_INDEX)
      )
    }

    _ownedData[id_] = data;
  }

  /// @notice 向指定的 NFT 注入 ERC20 代币
  /// @param tokenId_ NFT的ID
  /// @param tokenAddress_ ERC20代币的地址
  /// @param amount_ 注入的数量
  function depositTokens(uint256 tokenId_, address tokenAddress_, uint256 amount_) public override {
    // 验证 NFT 存在且调用者是所有者
    address owner = _getOwnerOf(tokenId_);
    if (owner != msg.sender) {
      revert Unauthorized();
    }

    // 修复：使用 <= 而不是 <
    require(amount_ <= balanceOf[msg.sender], "Insufficient balance");
    require(amount_ > 0, "Amount must be greater than 0");

    // 如果注入的是本代币，直接从用户余额中扣除
    if (tokenAddress_ == address(this)) {
      _transferERC20WithERC721(msg.sender, address(this), amount_);
      
      // 修复：正确更新存款记录
      if (_tokenDeposits[tokenId_].length > 0) {
        // 更新现有记录
        _tokenDeposits[tokenId_][0].amount += amount_;
      } else {
        // 创建新记录
        _tokenDeposits[tokenId_].push(TokenDeposit({
          tokenAddress: tokenAddress_,
          amount: amount_
        }));
      }

      emit TokensDeposited(tokenId_, tokenAddress_, amount_);
    } else {
      revert("Currently only native token deposits are supported");
    }
  }

  /// @notice 从 NFT 中提取存款
  /// @param tokenId_ NFT的ID
  function withdrawTokens(uint256 tokenId_) public {
    // 验证 NFT 存在且调用者是所有者
    address owner = _getOwnerOf(tokenId_);
    if (owner != msg.sender) {
      revert Unauthorized();
    }
    
    // 获取tokenid对应的存款
    TokenDeposit[] memory deposits = getTokenDeposits(tokenId_);
    require(deposits.length > 0, "No deposits to withdraw");
    
    // 计算超出基础值（units）的额外存款
    uint256 baseAmount = units;
    uint256 totalDeposit = deposits[0].amount;
    
    if (totalDeposit > baseAmount) {
      uint256 withdrawableAmount = totalDeposit - baseAmount;
      
      // 更新存款记录
      _tokenDeposits[tokenId_][0].amount = baseAmount;
      
      // 转移可提取的代币给用户
      _transferERC20(address(this), msg.sender, withdrawableAmount);
      
      emit TokensWithdrawn(tokenId_, deposits[0].tokenAddress, withdrawableAmount);
    }
  }

  /// @notice 获取指定 NFT 的所有存款信息
  function getTokenDeposits(uint256 tokenId_) public view override returns (TokenDeposit[] memory) {
    return _tokenDeposits[tokenId_];
  }

  /// @notice 内部函数：移除存款记录
  function _removeDeposit(uint256 tokenId_, uint256 index_) internal override {
    require(index_ < _tokenDeposits[tokenId_].length, "Invalid index");
    
    if (index_ != _tokenDeposits[tokenId_].length - 1) {
      _tokenDeposits[tokenId_][index_] = _tokenDeposits[tokenId_][_tokenDeposits[tokenId_].length - 1];
    }
    _tokenDeposits[tokenId_].pop();
  }

  /// @notice Transfer deposits when NFT is transferred
  function _transferDeposits(uint256 tokenId_, address from_, address to_) internal virtual override {
    uint256 depositAmount = _tokenDeposits[tokenId_].length;
    if (depositAmount > 0) {
      emit TokensWithdrawn(tokenId_, _tokenDeposits[tokenId_][depositAmount - 1].tokenAddress, _tokenDeposits[tokenId_][depositAmount - 1].amount);
      emit TokensDeposited(tokenId_, _tokenDeposits[tokenId_][depositAmount - 1].tokenAddress, _tokenDeposits[tokenId_][depositAmount - 1].amount);
    }
  }

  /// @notice 检查是否可以恢复特定ID的NFT
  function _canRestoreNFT(uint256 tokenId_) internal view override returns (bool) {
    if (!_isSplit[tokenId_] || _splitDeposits[tokenId_].length == 0) {
      return true;
    }

    TokenDeposit[] storage requiredDeposits = _splitDeposits[tokenId_];
    TokenDeposit[] storage currentDeposits = _tokenDeposits[tokenId_];
    
    if (currentDeposits.length == 0) return _splitDeposits[tokenId_].length > 0;
    
    return currentDeposits[0].amount >= requiredDeposits[0].amount;
  }

  /// @notice 在NFT被恢复时恢复存款记录
  function _handleNFTRestore(uint256 tokenId_) internal override {
    if (_isSplit[tokenId_] && _splitDeposits[tokenId_].length > 0) {
      // 恢复存款记录
      delete _tokenDeposits[tokenId_];
      for (uint256 i = 0; i < _splitDeposits[tokenId_].length; i++) {
        _tokenDeposits[tokenId_].push(_splitDeposits[tokenId_][i]);
      }
      
      // 清除拆分记录
      delete _splitDeposits[tokenId_];
      _isSplit[tokenId_] = false;
    }
    
    // 清除 requiredAmount
    delete _requiredAmount[tokenId_];
  }

  function _isOwner(address owner_, uint256 tokenId_) internal override returns (bool) {
    return _getOwnerOf(tokenId_) == owner_;
  }

  function _transfer(address from_, address to_, uint256 amount_) internal override returns (bool) {
    _transferERC20(from_, to_, amount_);
    return true;
  }

  function _transferFromSender(address from_, address to_, uint256 amount_) internal override returns (bool) {
    return _transferERC20WithERC721(from_, to_, amount_);
  }
}
