%lang starknet
from src.tempest import account_balance, update_balance, pool_balance, update_pool_balance 
from starkware.cairo.common.cairo_builtins import HashBuiltin    
    

## test increase balance 

@external
func test_increase_balance{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (result_before) = account_balance.read(1, 2)
    assert result_before = 0

    update_balance(1, 2, 42)    

    let (result_after) = account_balance.read(1, 2)
    assert result_after = 42
    return ()
end

@external
func test_update_pool_balance{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let (balance_before) = pool_balance.read(1)
    assert balance_before = 0

    update_pool_balance(1, 100)

    let (result_after) = pool_balance.read(1)
    assert result_after = 100
    return()
end

