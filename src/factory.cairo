### ==================================
###          TEMPEST FACTORY
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import deploy

### ======= storage-variables ========

@storage_var
func salt() -> (value : felt):
end

@storage_var
func contract_class_hash() -> (value : felt):
end

@storage_var
func pair_address(token_address_a : felt, token_address_b : felt) -> (pair : felt):
end

@storage_var
func pool_index(pool_id : felt) -> (pool_address : felt):
end

### ========== constructor ===========

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(tempest_class_hash : felt):
    contract_class_hash.write(value=tempest_class_hash)

    # prevents first salt from being 0 address 
    salt.write(1)
    return()
end

### ======== view functions ==========

@view
func get_pair_address{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_address_a : felt, token_address_b : felt) -> (pool_address : felt):
    alloc_locals 
    let (pool_address) = pair_address.read(token_address_a, token_address_b)
    return(pool_address)
end


### ====== external-functions ========

@external
func create_pair{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_address_a : felt, token_address_b : felt) -> (pool_address : felt):
    alloc_locals
    
    let (pair_arr) = alloc()
    assert [pair_arr] = token_address_a
    assert [pair_arr + 1] = token_address_b

    # check if pair already exists
    let (local pair) = pair_address.read(token_address_a, token_address_b)
#    assert_not_zero(value=pair)

    # must be valid tokens
    assert_not_zero(token_address_a)
    assert_not_zero(token_address_b)

    # set up contract information 
    let (current_salt) = salt.read()
    let (class_hash) = contract_class_hash.read()
    
    let (pool_address) = deploy(
        class_hash=class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=2,
        constructor_calldata=pair_arr,
    )

    pair_address.write(token_address_a, token_address_b, value=pool_address)
    salt.write(current_salt + 1)

    return(pool_address)
end







