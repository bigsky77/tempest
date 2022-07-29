%lang starknet

### ========= Dependencies =================

from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.math import (assert_nn_le, unsigned_div_rem, assert_le)
from starkware.cairo.common.hash import hash2
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address) 
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul

### ============ Constants ===============

const BALANCE_UPPER_BOUND = 62 ** 2

const TOKEN_A = 1
const TOKEN_B = 2
 
### ======= Storage Variables ============

@storage_var
func token_address(token_id : felt) -> (token_address : felt):
end

@storage_var 
func account_balance(account_id : felt, token_type : felt) -> (balance : Uint256):
end

@storage_var
func pool_balance(token_type : felt) -> (balance : Uint256):
end

### =========== Constructor ============= 

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(
    token_a : felt, 
    token_b : felt,
):
    token_address.write(token_id=TOKEN_A, value=token_a)
    token_address.write(token_id=TOKEN_B, value=token_b)
    return()
end

### ========= View Functions ============ 

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

### ======== External Functions =========

@external
func update_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_type : felt, amount : Uint256) -> (new_balance : Uint256):
    alloc_locals

    let (current_balance) = account_balance.read(account_id=account_id, token_type=token_type)
    let (local new_balance, _) = uint256_add(a=current_balance, b=amount)
    let (local upper_bound) = get_upperbound()

    uint256_signed_nn_le(new_balance, upper_bound)

    account_balance.write(
        account_id=account_id,
        token_type=token_type,
        value=new_balance,
    )

    return(new_balance=new_balance)
end

@external
func swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(account_id : felt, token_type : felt, amount_from : Uint256) -> (amount_to : Uint256):
    alloc_locals 

    assert (token_type - TOKEN_A) * (token_type - TOKEN_B) = 0
    let (local upper_bound) = get_upperbound()
    uint256_signed_nn_le(amount_from, upper_bound)

    let (local account_from_balance) = account_balance.read(account_id=account_id, token_type=token_type)

    uint256_le(amount_from, account_from_balance)

    let (local to_token) = get_opposite_token(token_type)
    let (local amm_from_balance) = pool_balance.read(token_type=token_type)
    let (local amm_to_balance) = pool_balance.read(token_type=to_token)
        
    let (local a, _) = uint256_mul(a=amount_from, b=amm_to_balance)
    let (local div, _) = uint256_add(a=amount_from, b=amm_from_balance)

    let (local amount_to, _) = uint256_unsigned_div_rem(a, div) 
    
    # update to balances
    
    update_balance(
        account_id=account_id, 
        token_type=to_token, 
        amount=amount_to
    )

    update_pool_balance(token_type=token_type, amount=amount_to)

    # update from balances

    update_balance(
        account_id=account_id,
        token_type=token_type,
        amount=amount_from,
    )

    update_pool_balance(token_type=token_type, amount=amount_from)
    
    return(amount_to=amount_to)
end

@external
func update_pool_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_type : felt, amount : Uint256) -> (new_balance : Uint256):
    alloc_locals

    let (local current_balance) = pool_balance.read(token_type=token_type)

    let (local new_balance, _) = uint256_add(a=current_balance, b=amount)

    pool_balance.write(token_type=token_type, value=new_balance)

    return(new_balance=new_balance)
end  

### =========== Internal Functions ========

func get_opposite_token(token_type : felt) -> (token_type : felt):
    if token_type == TOKEN_A:
        return(TOKEN_B)
    else:
        return(TOKEN_A) 
    end
end

func get_upperbound() -> (upper_bound : Uint256):
    alloc_locals

    let  y  = 62
    let  x  = 1
    let (local upper_bound) = uint256_pow2(exp=y)

    let (local upper_bound_sub_one) = uint256_sub(upper_bound, x)

    return (upper_bound=upper_bound_sub_one)
end

func execute_swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_to : felt, token_from : felt, amount_from : Uint256) -> (amount_to : Uint256):
    alloc_locals

    let (local account_from_balance) = account_balance.read(account_id=account_id, token_type=token_to)
    uint256_le(account_from_balance, amount_from)

    let (local amm_from_balance) = pool_balance.read(token_type=token_from)
    let (local amm_to_balance) = pool_balance.read(token_type=token_to)
    
    ## b = (pool_to * from_amount / pool_from + from_amount) 
    let (local amount_to, _) = unsigned_div_rem(
        amm_to_balance * token_from, 
        amm_from_balance + token_from,
    )
    
    let (local pool_address) = get_contract_address()
    let (local caller_address) = get_caller_address()

    IERC20.transferFrom(
        contract_address=pool_address,
        sender=pool_address, 
        recipient=caller_address, 
        amount=amount_to,
    )

    return(amount_to=amount_to)
end








