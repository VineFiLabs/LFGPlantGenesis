// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract LFGPlantGenesisNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable
{
    using MessageHashUtils for bytes32;

    uint256 private id;

    bytes1 private immutable ONEBYTES1 = 0x01;
    uint8 private lockState;
    uint16 private immutable _totalSupply = 10000;
    uint64 private fee = 0.01 ether;
    address private feeReceiver;
    string private URI;

    mapping(address => bool) public Signer;
    mapping(bytes32 => bool) public UserClaimProof;
    mapping(address => mapping(uint8 => bool)) public WhitelistMintState;
    // mapping(address => )

    constructor(
        address initialOwner,
        address _feeReceiver,
        address _signer
    ) ERC721("LFG Plant Genesis Collection", "LPG") Ownable(initialOwner) {
        feeReceiver = _feeReceiver;
        Signer[_signer] = true;
    }

    modifier Lock() {
        require(lockState == 0, "Locked");
        _;
    }

    function setFee(uint64 newFee) external onlyOwner {
        fee = newFee;
    }

    function setLock(uint8 state) external onlyOwner {
        lockState = state;
    }

    function setSigner(address signer, bool state) external onlyOwner {
        Signer[signer] = state;
    }

    function setURI(string memory _newURI) external onlyOwner {
        URI = _newURI;
    }

    function claim(uint8 number) external payable Lock {
        uint256 totalFee = fee * number;
        require(msg.value >= totalFee, "Insufficient eth");
        require(_batchMint(number, msg.sender) == ONEBYTES1, "Invalid mint");
    }

    function whitelistClaim(
        bytes32 claimNftData,
        bytes calldata sign,
        uint8 number
    ) external {
        require(UserClaimProof[claimNftData] == false, "Already claim");
        require(
            getSignatureVerify(number, packData(number, msg.sender), sign),
            "signature error"
        );
        require(_batchMint(number, msg.sender) == ONEBYTES1, "Invalid mint");
        //mint
        WhitelistMintState[msg.sender][number] = false;
        UserClaimProof[claimNftData] = true;
    }

    function getSignatureVerify(
        uint8 _number,
        bytes32 _signHash,
        bytes calldata _signature
    ) public view returns (bool state) {
        state = WhitelistMintState[
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(_signHash),
                _signature
            )
        ][_number];
    }

    function getEncodeData(
        uint8 number,
        address user
    ) external view returns (bytes32) {
        return packData(number, user);
    }

    function packData(
        uint8 number,
        address user
    ) private view returns (bytes32 _packData) {
        _packData = keccak256(
            abi.encode(address(this), block.chainid, user, number)
        );
    }

    function totalSupply()
        public
        view
        override(ERC721Enumerable)
        returns (uint256)
    {
        return _totalSupply;
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
