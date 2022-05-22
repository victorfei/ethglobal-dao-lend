// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IBondFactory} from "./interfaces/IBondFactory.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {FixedPointMathLib} from "./utils/FixedPointMathLib.sol";

import "./Bond.sol";

/** 
    @title Bond Factory
    @author Porter Finance
    @notice This factory contract issues new bond contracts.
    @dev This uses a cloneFactory to save on gas costs during deployment.
        See OpenZeppelin's "Clones" proxy.
*/
contract BondFactory is IBondFactory, AccessControl {
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    /// @notice Max length of the Bond.
    uint256 internal constant MAX_TIME_TO_MATURITY = 3650 days;

    /**
        @notice The max number of decimals for the paymentToken and
            collateralToken.
    */
    uint8 internal constant MAX_DECIMALS = 18;

    /// @notice The role required to issue bonds.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    /// @notice The role given to allowed tokens.
    bytes32 public constant ALLOWED_TOKEN = keccak256("ALLOWED_TOKEN");

    /// @inheritdoc IBondFactory
    address public immutable tokenImplementation;

    /// @inheritdoc IBondFactory
    mapping(address => bool) public isBond;

    /// @inheritdoc IBondFactory
    bool public isIssuerAllowListEnabled = false;

    /// @inheritdoc IBondFactory
    bool public isTokenAllowListEnabled = false;

    /**
        @dev If allow list is enabled, only allow-listed issuers are
            able to call functions.
    */
    modifier onlyIssuer() {
        if (isIssuerAllowListEnabled) {
            _checkRole(ISSUER_ROLE, _msgSender());
        }
        _;
    }

    /*
        When deployed, the deployer will be granted the DEFAULT_ADMIN_ROLE. This
        gives the ability the ability to call `grantRole` to grant access to
        the ISSUER_ROLE as well as the ability to toggle if the allow list
        is enabled or not at any time.
    */
    constructor() {
        tokenImplementation = address(new Bond());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @inheritdoc IBondFactory
    function setIsIssuerAllowListEnabled(bool _isIssuerAllowListEnabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isIssuerAllowListEnabled = _isIssuerAllowListEnabled;
        emit IssuerAllowListEnabled(_isIssuerAllowListEnabled);
    }

    function setIsTokenAllowListEnabled(bool _isTokenAllowListEnabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isTokenAllowListEnabled = _isTokenAllowListEnabled;
        emit TokenAllowListEnabled(_isTokenAllowListEnabled);
    }

    /// @inheritdoc IBondFactory
    function createBond(CreateBondDetails calldata _bond)
        external
        onlyIssuer
        returns (address clone)
    {
        if (_bond.bonds == 0) {
            revert ZeroBondsToMint();
        }
        if (_bond.paymentToken == _bond.collateralToken) {
            revert TokensMustBeDifferent();
        }
        if (_bond.collateralTokenAmount < _bond.convertibleTokenAmount) {
            revert CollateralTokenAmountLessThanConvertibleTokenAmount();
        }
        if (
            _bond.maturity <= block.timestamp ||
            _bond.maturity > block.timestamp + MAX_TIME_TO_MATURITY
        ) {
            revert InvalidMaturity();
        }
        if (
            IERC20Metadata(_bond.paymentToken).decimals() > MAX_DECIMALS ||
            IERC20Metadata(_bond.collateralToken).decimals() > MAX_DECIMALS
        ) {
            revert TooManyDecimals();
        }
        if (isTokenAllowListEnabled) {
            _checkRole(ALLOWED_TOKEN, _bond.paymentToken);
            _checkRole(ALLOWED_TOKEN, _bond.collateralToken);
        }

        {
            clone = Clones.clone(tokenImplementation);

            isBond[clone] = true;
            uint256 collateralRatio = _bond.collateralTokenAmount.divWadDown(
                _bond.bonds
            );
            uint256 convertibleRatio = _bond.convertibleTokenAmount.divWadDown(
                _bond.bonds
            );
            _deposit(
                _msgSender(),
                clone,
                _bond.collateralToken,
                _bond.collateralTokenAmount
            );

            Bond(clone).initialize(
                _bond.name,
                _bond.symbol,
                _msgSender(),
                _bond.maturity,
                _bond.paymentToken,
                _bond.collateralToken,
                collateralRatio,
                convertibleRatio,
                _bond.bonds
            );
        }
        emit BondCreated(clone, _msgSender(), _bond);
    }

    function _deposit(
        address owner,
        address clone,
        address collateralToken,
        uint256 collateralToDeposit
    ) internal {
        IERC20Metadata(collateralToken).safeTransferFrom(
            owner,
            clone,
            collateralToDeposit
        );
        uint256 amountDeposited = IERC20Metadata(collateralToken).balanceOf(
            clone
        );

        /*
            Check that the amount of collateral in the contract is the expected
            amount deposited. A token could take a fee upon transfer. If the
            collateralToken takes a fee than the transaction will be reverted. 
        */
        if (collateralToDeposit != amountDeposited) {
            revert InvalidDeposit();
        }
    }
}
