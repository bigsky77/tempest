%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn

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
  
  let new_balance = current_balance + amount

  account_balance.write(
    account_id=account_id,
    token_type=token_type,
    value=new_balance,
    )

  return(new_balance=new_balance)
end
