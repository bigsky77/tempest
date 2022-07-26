%lang starknet
from src.tempest import account_balance, update_balance, pool_balance, update_pool_balance, swap 
from starkware.cairo.common.cairo_builtins import HashBuiltin    
    
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
func test_swap{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    update_pool_balance(TOKEN_A, 1000)
    update_pool_balance(TOKEN_B, 1000)

    update_balance(USER, TOKEN_A, 100)

    let (local balance_before) = account_balance.read(USER, TOKEN_B)
    assert balance_before = 0

    let (new_balance) = swap(USER, TOKEN_A, 100) 

    let (balance_after) = account_balance.read(USER, TOKEN_B)
    assert balance_after = balance_before + new_balance 

    return()
end









