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
    


    return()
end







