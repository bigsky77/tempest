### ==================================
###          TEMPEST ROUTER
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256 
from starkware.cairo.common.cairo_builtins import HashBuiltin

### ======= storage-variables ========

@storage_var
func factory_address() -> (value : felt):
end

### ========== constructor ===========

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(factory : felt):

    factory_address.write(factory)
    return()
end
