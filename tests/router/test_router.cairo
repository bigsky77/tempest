### ==================================
###           ROUTER TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.IRouter import IRouter



### ============= set-up =============

@external
func __setup__{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals


   return() 
end


