%lang starknet
from src.tempest import account_balance, update_balance, pool_balance, update_pool_balance, swap 
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin    
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.crypto.signature.signature import (
    pedersen_hash, private_to_stark_key, sign)

const TOKEN_A = 1
const TOKEN_B = 2

const USER = 1

## test increase balance 

@external
func test_increase_balance{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (result_before) = account_balance.read(USER, TOKEN_A)
    assert result_before = 0

    update_balance(USER, TOKEN_A, 42)    

    let (result_after) = account_balance.read(USER, TOKEN_A)
    assert result_after = 42
    return ()
end

@external
func test_update_pool_balance{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (balance_before) = pool_balance.read(TOKEN_A)
    assert balance_before = 0

    update_pool_balance(TOKEN_A, 100)

    let (result_after) = pool_balance.read(TOKEN_A)
    assert result_after = 100
    return()
end

@external
func test_swap{ecdsa_ptr : SignatureBuiltin*, syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    let private_key : felt = 1234
    let message_hash = pedersen_hash(4321)
    let public_key = private_to_stark_key(private_key)
    let sig = sign(msg_hash=message_hash, priv_key=private_key)

    update_pool_balance(TOKEN_A, 1000)
    update_pool_balance(TOKEN_B, 1000)

    update_balance(USER, TOKEN_A, 100)

    let (local balance_before) = account_balance.read(USER, TOKEN_B)
    assert balance_before = 0

    let (new_balance) = swap(USER, TOKEN_A, 100, sig) 

    let (balance_after) = account_balance.read(USER, TOKEN_B)
    assert balance_after = balance_before + new_balance 

    return()
end









