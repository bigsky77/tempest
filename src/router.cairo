### ==================================
###          TEMPEST ROUTER
### ==================================

%lang starknet

### ========== dependencies ==========

from interfaces.ITempest import ITempest
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256 
 
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
}(factory_address : felt):
    factory_address.write(value=factory_address)
    return()
end
