// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

interface IBondFactory {
    struct CreateBondDetails {
        string name;
        string symbol;
        uint256 maturity;
        address paymentToken;
        address collateralToken;
        uint256 collateralTokenAmount;
        uint256 convertibleTokenAmount;
        uint256 bonds;
        string daoName;
        uint256 interestRate;
    }

    /**
        @notice Emitted when the restriction of bond creation to allow-listed
            accounts is toggled on or off.
        @param isIssuerAllowListEnabled The new state of the allow list.
    */
    event IssuerAllowListEnabled(bool isIssuerAllowListEnabled);

    /**
        @notice Emitted when the restriction of collateralToken and paymentToken
            to allow-listed tokens is toggled on or off.
        @param isTokenAllowListEnabled The new state of the allow list.
    */
    event TokenAllowListEnabled(bool isTokenAllowListEnabled);

    /**
        @notice Emitted when a new bond is created.
        @param newBond The address of the newly deployed bond.
        @param name Passed into the ERC20 token to define the name.
        @param symbol Passed into the ERC20 token to define the symbol.
        @param owner Ownership of the created Bond is transferred to this
            address by way of _transferOwnership and tokens are minted to this
            address. See `initialize` in `Bond`.
        @param maturity The timestamp at which the Bond will mature.
        @param paymentToken The ERC20 token address the Bond is redeemable for.
        @param bonds The amount of bond shares to give to the owner during the
            one-time mint during the `Bond`'s `initialize`.
    */
    event BondCreated(
        address newBond,
        string name,
        string symbol,
        address indexed owner,
        uint256 maturity,
        address indexed paymentToken,
        uint256 bonds
    );

    /// @notice Fails if the collateralToken takes a fee.
    error InvalidDeposit();

    /// @notice Decimals with more than 18 digits are not supported.
    error TooManyDecimals();

    /// @notice Maturity date is not valid.
    error InvalidMaturity();

    /// @notice There must be more collateralTokens than convertibleTokens.
    error CollateralTokenAmountLessThanConvertibleTokenAmount();

    /// @notice Bonds must be minted during initialization.
    error ZeroBondsToMint();

    /// @notice The paymentToken and collateralToken must be different.
    error TokensMustBeDifferent();

    function createBond(CreateBondDetails calldata _bond)
        external
        returns (address clone);

    /**  
        @notice If enabled, issuance is restricted to those with ISSUER_ROLE.
        @dev Emits `IssuerAllowListEnabled` event.
        @return isEnabled Whether or not the `ISSUER_ROLE` will be checked when
            creating new bonds.
    */
    function isIssuerAllowListEnabled() external view returns (bool isEnabled);

    /**  
        @notice If enabled, tokens used as paymentToken and collateralToken are
            restricted to those with the ALLOWED_TOKEN role.
        @dev Emits `TokenAllowListEnabled` event.
        @return isEnabled Whether or not the collateralToken and paymentToken
            are checked for the `ALLOWED_TOKEN` role when creating new bonds.
    */
    function isTokenAllowListEnabled() external view returns (bool isEnabled);

    /**
        @notice Returns whether or not the given address key is a bond created
            by this Bond factory.
        @dev This mapping is used to check if a bond was issued by this contract
            on-chain. For example, if we want to make a new contract that
            accepts any issued Bonds and exchanges them for new Bonds, the
            exchange contract would need a way to know that the Bonds are owned
            by this contract.
    */
    function isBond(address) external view returns (bool);

    /**
        @notice Sets the state of bond restriction to allow-listed accounts.
        @param _isIssuerAllowListEnabled If the issuer allow list should be
            enabled or not.
        @dev Must be called by the current owner.
    */
    function setIsIssuerAllowListEnabled(bool _isIssuerAllowListEnabled)
        external;

    /**
        @notice Sets the state of token restriction to the list of allowed
            tokens.
        @param _isTokenAllowListEnabled If the token allow list should be
            enabled or not.
        @dev Must be called by the current owner.
    */
    function setIsTokenAllowListEnabled(bool _isTokenAllowListEnabled) external;

    /**
        @notice Address where the bond implementation contract is stored.
        @dev This is needed since we are using a clone proxy.
        @return The implementation address.
    */
    function tokenImplementation() external view returns (address);
}
