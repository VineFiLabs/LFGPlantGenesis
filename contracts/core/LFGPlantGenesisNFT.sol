// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LFGPlantGenesisNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable,
    ReentrancyGuard
{
    using MessageHashUtils for bytes32;

    uint256 private id;

    bytes1 private immutable ONEBYTES1 = 0x01;
    uint8 private lockState;
    uint16 private immutable limitSupply = 10000;
    uint64 public fee;
    address public feeReceiver;
    string private URI;

    mapping(address => bool) public SignerValidState;
    mapping(bytes32 => mapping(bytes => bool)) public UserClaimProof;

    constructor(
        address _owner,
        address _feeReceiver,
        address _signer,
        uint64 _fee
    ) ERC721("LFG Plant Genesis Collection", "LPG") Ownable(_owner) {
        feeReceiver = _feeReceiver;
        SignerValidState[_signer] = true;
        fee = _fee;
    }

    modifier Lock{
        require(lockState == 0, "Locked");
        _;
    }

    modifier Limit{
        require(id <= limitSupply, "Overflow");
        _;
    }

    receive() external payable{}

    function setFee(uint64 newFee) external onlyOwner {
        fee = newFee;
    }

    function setLock(uint8 state) external onlyOwner {
        lockState = state;
    }

    function setSigner(address signer, bool state) external onlyOwner {
        SignerValidState[signer] = state;
    }

    function setURI(string memory _newURI) external onlyOwner {
        URI = _newURI;
    }

    function claim(uint8 number) external payable nonReentrant Lock Limit{
        uint256 totalFee = fee * number;
        require(msg.value >= totalFee, "Insufficient eth");
        (bool success, ) = feeReceiver.call{value: totalFee}("");
        require(success, "Fee receive fail");
        require(_batchMint(number, msg.sender) == ONEBYTES1, "Invalid mint");
    }

    function whitelistClaim(
        bytes32 claimNftData,
        bytes calldata sign,
        uint8 number
    ) external nonReentrant Limit{
        require(UserClaimProof[claimNftData][sign] == false, "Already claim");
        require(
            getSignatureVerify(packData(number, msg.sender), sign),
            "signature error"
        );
        //mint
        UserClaimProof[claimNftData][sign] = true;
        require(_batchMint(number, msg.sender) == ONEBYTES1, "Invalid mint");
    }

    function skim(address token)external onlyOwner{
        uint256 balance;
        if(token == address(0)){
            balance = address(this).balance;
            (bool success, ) = feeReceiver.call{value: balance}("");
            require(success, "Skim eth fail");
        }else{
            balance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(feeReceiver, balance);
        }
    }

    function getSignatureVerify(
        bytes32 _signHash,
        bytes calldata _signature
    ) public view returns (bool state) {
        state = SignerValidState[
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(_signHash),
                _signature
            )
        ];
    }

    function getEncodeData(
        uint8 number
    ) external view returns (bytes32) {
        return packData(number, msg.sender);
    }

    function packData(
        uint8 number,
        address user
    ) private view returns (bytes32 _packData) {
        _packData = keccak256(
            abi.encode(address(this), block.chainid, user, number)
        );
    }

    function _batchMint(uint8 number, address receiver) private returns (bytes1 state) {
        for(uint8 i; i<number; i++){
            _safeMint(receiver, id);
            _setTokenURI(id, URI);
            id++;
        }
        state = ONEBYTES1;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
