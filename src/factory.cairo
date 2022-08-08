### ==================================
###          TEMPEST FACTORY
### ==================================

%lang starknet

### ========== dependencies ==========

from interfaces.ITempest import ITempest
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import deploy

### ======= storage-variables ========

@storage_var
func salt() -> (value : felt):
end

@storage_var
func tempest_class_hash() -> (value : felt):
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
    tempest_class_hash.write(value=tempest_class_hash)

    # prevents first salt from being 0 address 
    salt.write(1)
    return()
end

### ======== view-functions ==========


### ====== external-functions ========

@external
func create_pair{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_address_a : felt, token_address_b : felt) -> (pair_address : felt):
    alloc_locals
    
    let pair_arr : felt*
    assert pair_arr[0] = token_address_a
    assert pair_arr[1] = token_address_b

    # check if pair already exists
    let (local pair) = pair_address.read(token_address_a, token_address_b)
    assert pair == 0

    # must be valid tokens
    assert token_address_a != 0
    assert token_address_b != 0

    # set up contract information 
    let (current_salt) = salt.read()
    let (class_hash) = tempest_class_hash.read()
    
    let (pool_address) = deploy(
        class_hash=class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=2,
        constructor_calldata=pair_arr,
    )

    pair_address.write(token_address_a, token_address_b, pair=pool_address)
    salt.write(current_salt + 1)

    return()
end







