%lang starknet

### ========= Dependencies =================

from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.math import (assert_nn_le, unsigned_div_rem, assert_le)
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.hash import hash2
from openzeppelin.token.ERC20.IERC20 import IERC20
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.uint256 import Uint256 

### ============ Constants ===============

const BALANCE_UPPER_BOUND = 62 ** 2

const TOKEN_A = 1
const TOKEN_B = 2

### ======= Storage Variables ============

@storage_var
func token_address() -> (token : felt):
end

@storage_var 
func account_balance(account_id : felt, token_type : felt) -> (balance : felt):
end

@storage_var
func pool_balance(token_type : felt) -> (balance : felt):
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
    token_address.write(token_a)
    token_address.write(token_b)
    return()
end

### ========= View Functions ============ 

@view
func get_account_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_type : felt) -> (balance : felt):
    let (balance) = account_balance.read(account_id=account_id, token_type=token_type)
    return(balance=balance)
end

@view 
func get_pool_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_type : felt) -> (balance : felt):
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
}(account_id : felt, token_type : felt, amount : felt) -> (new_balance : felt):

  let (current_balance) = account_balance.read(account_id=account_id, token_type=token_type)
  tempvar new_balance = current_balance + amount
    
  assert_nn_le(new_balance, BALANCE_UPPER_BOUND - 1)

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
}(account_id : felt, token_type : felt, amount_from : felt) -> (amount_to : felt):
    alloc_locals 

    assert (token_type - TOKEN_A) * (token_type - TOKEN_B) = 0
    assert_nn_le (amount_from, BALANCE_UPPER_BOUND - 1)

    let (local account_from_balance) = account_balance.read(account_id=account_id, token_type=token_type)

    assert_le(amount_from, account_from_balance)

    let (local to_token) = get_opposite_token(token_type)

    let (local amm_from_balance) = pool_balance.read(token_type=token_type)
    let (local amm_to_balance) = pool_balance.read(token_type=to_token)
        
    let (local amount_to, _) = unsigned_div_rem(
        amm_to_balance * amount_from, amm_from_balance + amount_from 
    )

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
        token_type=amount_from,
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
}(token_type : felt, amount : felt) -> (new_balance : felt):
    alloc_locals

    let (local current_balance) = pool_balance.read(token_type=token_type)

    tempvar new_balance = current_balance + amount

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

func execute_swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_to : felt, token_from : felt, amount_from : felt) -> (new_balance : felt):
    alloc_locals

    let (local account_from_balance) = account_balance.read(account_id=account_id, token_type=token_to)
    assert_le(account_from_balance, amount_from)

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

    return()
end








