%lang starknet 

### ========== dependencies ==========

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn_le, unsigned_div_rem, assert_le)
from starkware.cairo.common.hash import hash2
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.presets import ERC20Mintable
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address) 
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul, uint256_sqrt

### ==================================
###              TEMPEST
### ==================================

### =========== constants ============

const TOKEN_A = 1
const TOKEN_B = 2
const LP_TOKEN = 3

const MINIMUM_LIQUIDITY =  1 ** 3 

### =========== variables ============

@storage_var
func token_address(token_address : felt) -> (token_id : felt):
end

@storage_var
func account_balance(token_id : felt, account_id : felt) -> (balance : Uint256):
end

@storage_var
func pool_reserve(token_id : felt) -> (balance : Uint256):
end

### ========== constructor ===========

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(
    token_address_a : felt,
    token_address_b : felt,
):
    token_address.write(token_address=token_address_a, token_id=TOKEN_A)
    token_address.write(token_address=token_address_b, token_id=TOKEN_B)
    return()
end

### ============== view ==============

@view
func get_account_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_type : felt) -> (balance : Uint256):
    let (balance) = account_balance.read(account_id=account_id, token_type=token_type)
    return(balance=balance)
end

@view 
func get_pool_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_type : felt) -> (balance : Uint256):
    alloc_locals
    let (local balance) = pool_balance.read(token_type=token_type)
    return(balance=balance)
end

### ====== external functions ========

@external
func mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt) -> (liquidity : felt):
    alloc_locals
 
    let (local contract_address) = get_contract_address()
    let (local address_a) = token_address.read(token_id=TOKEN_A)
    let (local address_b) = token_address.read(token_id=TOKEN_B)

    let (local balance0) = IERC20.balanceOf(contract_address=contract_address,account=address_a)
    let (local balance1) = IERC20.balanceOf(contract_address=contract_address, account=address_b)

    let (local reserve0) = pool_balance(token_id=TOKEN_A)
    let (local reserve1) = pool_balance(token_id=TOKEN_B)

    let (local amount0) = uint256_sub(a=balance0, b=reserve0)
    let (local amount1) = uint256_sub(a=balance1, b=reserve1)

    tempvar totalSupply = IERC20.totalSupply(contract_address=contract_address)

    if totalSupply == 0:
        ## liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
        tempvar x = uint256_mul(a=amount0, b=amount1)
        tempvar y = uint256_sqrt(n=x)
        let (local liquidity) = uint256_sub(a=x, b=y)
    
        



















