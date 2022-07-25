%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn_le

const BALANCE_UPPER_BOUND = 62 ** 2

const TOKEN_A = 1
const TOKEN_B = 2

@storage_var 
func account_balance(account_id : felt, token_type : felt) -> (balance : felt):
end

@storage_var
func pool_balance(token_type : felt) -> (balance : felt):
end

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

func swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_type : felt, amount : felt) -> (balance : felt):
    let (from_balance) = pool_balance.read(token_type=token_type)
    
    let (to_token) = get_opposite_token(token_type=token_type)
    let (to_balance) = pool_balance.read(token_type=to_token)
    
    

    return(balance=balance)
end

func get_opposite_token(token_type : felt) -> (token_type : felt):
    if token_type == TOKEN_A:
        return(TOKEN_B)
    else:
        return(TOKEN_A) 
    end
end


