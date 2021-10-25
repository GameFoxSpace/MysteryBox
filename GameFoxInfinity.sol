// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function viewTokenID() external view returns (uint256);

    function mint(
        address _to,
        uint256 _tokenId,
        uint16 _nftType,
        uint16 _quaTypes,
        uint16 _fiveEle,
        uint16 _level,
        uint256 _force,
        uint256 _skill,
        string calldata _uri
    ) external;

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address account, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract GameFox {
    using SafeMath for uint256;
    IERC20 FirstBuyErc20;

    address nftAddress = 0xF62a1cc8c47c418E800771B4E612B91A1f2C4934; //nft contract address
    address buyNftAddress = 0x4eE38077253c6688dDcca6207E9a3ea1451EE13D; //Token contract address used to purchase NFT
    address colWallAddress = 0xe9920B8fdD303E077fC879009227d24Af9b25255; //Cold wallet address
    address poolWallAddress = 0xe9920B8fdD303E077fC879009227d24Af9b25255; //Pool address
    uint8 poolFree = 20; //The proportion of coins transferred from the mining pool
    uint256 public startTime = 1627815600; //Opening time, default contract release time
    address public owner;
    address public manager;

    mapping(address => uint256) public buyNftErc20TokenAmount; //Open token address and corresponding price
    mapping(address => uint256) public typeId; //The typeid corresponding to the NFT address
    mapping(uint256 => uint256) public maxAmount; //NFT type corresponds to the maximum sale quantity
    uint256 public totalSaleAmount = 500000000;
    uint256 public alreadSaleAmount; //Number of NFTs sold
    uint256 public version = 4;

    uint256 public busdTicket;

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
        setBuyNftErc20TokenAmount(buyNftAddress, 18, 20);
    }

    uint256[] public _type_u;

    modifier onlyManager {
        require(manager == msg.sender);
        _;
    }

    function setStartTime(uint256 _startTime) public onlyManager {
        if (_startTime > block.timestamp) {
            startTime = _startTime;
        }
    }

    function setManager(address _mAddr) public {
        require(msg.sender == owner, "only owner");
        manager = _mAddr;
    }

    function setTotalSaleAmount(uint8 _amount) public onlyManager {
        totalSaleAmount = _amount;
    }

    function buyOneFoxMul(address _erc20Addr, uint8 _amount) public {
        for (uint8 i = 0; i < _amount; i++) {
            buyOneFox(_erc20Addr);
        }
    }

    function buyOneFox(address _erc20Addr) public returns (uint256 _typeN) {
        require(
            buyNftErc20TokenAmount[_erc20Addr] > 0,
            "Fox box price set error"
        );
        require(block.timestamp >= startTime, "ship not start");
        require(
            IERC20(_erc20Addr).allowance(msg.sender, address(this)) >=
                buyNftErc20TokenAmount[_erc20Addr],
            "not enght allowance"
        );
        uint256 erc20BusdTicketAmount = buyNftErc20TokenAmount[_erc20Addr];
        IERC20 erc20Address = IERC20(_erc20Addr);
        require(
            IERC20(_erc20Addr).balanceOf(msg.sender) >= erc20BusdTicketAmount,
            "not enght token"
        );
        if (poolFree == 0) {
            erc20Address.transferFrom(
                msg.sender,
                colWallAddress,
                erc20BusdTicketAmount
            );
        } else {
            erc20Address.transferFrom(
                msg.sender,
                colWallAddress,
                (erc20BusdTicketAmount * poolFree) / 100
            );
            erc20Address.transferFrom(
                msg.sender,
                poolWallAddress,
                (erc20BusdTicketAmount * (100 - poolFree)) / 100
            );
        }

        uint256 _tempQuaType;
        _tempQuaType = round(900000 + alreadSaleAmount); //_quaTypes
        _typeN = _tempQuaType;
        require(_tempQuaType > 0, "QuaType is error");
        if (_tempQuaType != 0) {
            _type_u.push(_tempQuaType);
            alreadSaleAmount++;
            uint16 _nftType = roundName(80000 + alreadSaleAmount);
            uint16 _quaTypes = uint8(_typeN); //Quality: white, green, blue, purple, orange, red
            uint16 _fiveEle = round(40000 + alreadSaleAmount); //Five Elements Water Wood Golden Fire Earth
            uint16 _level = 0; //level
            uint256 _force = 0;
            uint256 _skill = 0;
            string memory _uri = "";

            uint256 _tokenId = 0; // Purchase currency transfer out, getNewTokenId(_nftType,_tempQuaType,_fiveEle);
            IERC20(nftAddress).mint(
                msg.sender,
                _tokenId,
                _nftType,
                _quaTypes,
                _fiveEle,
                _level,
                _force,
                _skill,
                _uri
            );
        }

        return _typeN;
    }

    function getAlreadSaleAmount() public view returns (uint256 alSaleAmount) {
        alSaleAmount = alreadSaleAmount;
    }

    function getNewTokenId(
        uint256 _nftType,
        uint256 _quaType,
        uint256 _fiveEle
    ) public view returns (uint256 _newTokenId) {
        uint256 erc20_tokenid = IERC20(nftAddress).viewTokenID();
        _newTokenId =
            _nftType *
            10000000000 +
            _quaType *
            1000000000 +
            uint256(_fiveEle) *
            100000000 +
            erc20_tokenid;
    }

    function round(uint256 _idex) public view returns (uint8 _type) {
        uint256 balanceOfUSDT = FirstBuyErc20.balanceOf(address(this));
        uint256 result2 = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number),
                    msg.sender,
                    now,
                    balanceOfUSDT,
                    _idex,
                    block.difficulty
                )
            )
        );

        result2 = result2 - (result2 / 10000) * 10000;

        if (result2 >= 0 && result2 <= 5555) {
            //55%  White
            _type = 1;
        } else if (result2 >= 5556 && result2 <= 8500) {
            //30.00% green
            _type = 2;
        } else if (result2 >= 8501 && result2 <= 9500) {
            //10% blue
            _type = 3;
        } else if (result2 >= 9501 && result2 <= 9999) {
            //5% purple
            _type = 4;
        } else if (result2 >= 9700 && result2 <= 9999) {
            //3%  orange
            _type = 5;
        } else if (result2 >= 992 && result2 <= 999) {
            //0.075%  red
            _type = 6;
        }
    }

    function roundName(uint256 _idex) public view returns (uint8 _type) {
        uint256 balanceOfUSDT = FirstBuyErc20.balanceOf(address(this));
        uint256 result2 = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number),
                    msg.sender,
                    now,
                    balanceOfUSDT,
                    _idex,
                    block.difficulty
                )
            )
        );

        result2 = result2 - (result2 / 10000) * 10000;

        if (result2 >= 0 && result2 <= 3000) {
            //30%
            _type = 1;
        } else if (result2 >= 3001 && result2 <= 4000) {
            //10%
            _type = 2;
        } else if (result2 >= 4001 && result2 <= 6500) {
            //25%
            _type = 3;
        } else if (result2 >= 6501 && result2 <= 7000) {
            //5%
            _type = 4;
        } else if (result2 >= 7001 && result2 <= 9999) {
            //30%
            _type = 5;
        }
    }

    //Set the ERC tokens out of the box and the purchase amount
    function setBuyNftErc20TokenAmount(
        address _erc20Addr,
        uint256 _decimals,
        uint256 _priceAmount
    ) public onlyManager {
        FirstBuyErc20 = IERC20(_erc20Addr);
        uint256 pAmount = _priceAmount * 10**_decimals;
        buyNftErc20TokenAmount[_erc20Addr] = pAmount;
    }

    function setPoolFree(uint8 _poolFree) public onlyManager {
        poolFree = _poolFree;
    }

    function getBuyNftErc20TokenAmount(address _erc20Addr)
        public
        view
        returns (uint256)
    {
        return buyNftErc20TokenAmount[_erc20Addr];
    }

    function withOtherERC20(
        address _token,
        address _to,
        uint256 _Amount
    ) public onlyManager {
        require(_to != address(0), "to is zero");
        uint256 balanceAmount = IERC20(_token).balanceOf(address(this));
        uint256 leftAmount = _Amount;
        if (_Amount > balanceAmount) {
            leftAmount = balanceAmount;
        }
        IERC20(_token).transfer(_to, leftAmount);
    }
}
