// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    // Variables - You will not need to change these or add any
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint8 private _decimals;

    // Events

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Emitted when tokens are minted and the total supply is increased.
     */
    event Mint(address indexed mintee, address indexed minter, uint256 value);

    /**
     * @dev Emitted when tokens are burned and the total supply is reduced.
     */
    event Burn(address indexed burnee, address indexed burner, uint256 value);

    // Constructor

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = 0;
        _balances[msg.sender] += _totalSupply;
    }

    // Contract metadata

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals for the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Public transfer functions

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * This is the public function, approval check not necssary. As the caller is the
     * one transfering the tokens. Call the internal function _transfer.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Public function, should call to interal _approve
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance. This is the public function and should check approvals. Then call the
     * internal function _transfer.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *from
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        if (_balances[from] < amount) {
            amount = _allowances[from][to];
        }
        require(_allowances[from][to] >= amount, "Allowance insufficient");
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][to] -= amount;

        _transfer(from, to, amount);
        emit Approval(from, msg.sender, amount);
        return true;
    }

    // Public supply functions

    /**
     * @dev Mint `amount` tokens to the caller's account.
     * This is the public function, Call the internal function _mint.
     *
     * Return a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: In the real world, you would never allow users to simply mint tokens
     * you would either require them to pay in some way for the tokens, or you would
     * only allow minting from a trusted source/role/owner. For the purposes of this
     * lesson, you will publically allow mints to anyone.
     */
    function mint(uint256 amount) external returns (bool) {
        return _mint(msg.sender, amount);
    }

    /**
     * @dev Mint `amount` tokens to the a specified account `to`.
     * This is the public function, Call the internal function _mint.
     *
     * Return a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: In the real world, you would never allow users to simply mint tokens
     * you would either require them to pay in some way for the tokens, or you would
     * only allow minting from a trusted source/role/owner. For the purposes of this
     * lesson, you will publically allow mints to anyone.
     */
    function mintTo(address to, uint256 amount) external returns (bool) {
        return _mint(to, amount);
    }

    /**
     * @dev Burn `amount` tokens from the caller's account.
     * This reduces the total supply. This is the public function.
     * Call the internal function _burn.
     *
     * Return a boolean value indicating whether the operation succeeded.
     */
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /**
     * @dev Burn `amount` tokens held in a specified account.
     * Ensure allowance is sufficient. This is the public function. Call the internal
     * function _burn.
     *
     * Return a boolean value indicating whether the operation succeeded.
     */
    function burnFrom(address from, uint256 amount) external returns (bool) {
        _burn(from, amount);
        return true;
    }

    // Internal functions

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = 0;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Burn `amount` tokens from the caller's account.
     * This reduces the total supply. This is the internal function
     * which should contain the logic for burning tokens.
     *
     * Return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Burn} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: burn from the zero address");
        require(_balances[to] >= amount, "ERC20: burn amount exceeds balance");
        _totalSupply -= amount;
        _balances[to] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        emit Burn(to, msg.sender, amount);
    }

    /**
     * @dev Mint `amount` tokens to the a specified account.
     * This increases the total supply. This is the internal function
     * which should contain the logic for minting tokens.
     *
     * Return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Mint} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address to, uint256 amount) internal returns (bool) {
        require(to != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        emit Mint(to, msg.sender, amount);
        return true;
    }

    // Functions for testing, not part of the ERC20 standard, do not change them

    function transferInternal(
        address from,
        address to,
        uint256 value
    ) public {
        _transfer(from, to, value);
    }

    function approveInternal(
        address owner,
        address spender,
        uint256 value
    ) public {
        _approve(owner, spender, value);
    }
}
