### ==================================
###           TEMPEST TESTS
### ==================================

%lang starknet

### ========== dependencies ==========
 
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul, uint256_sqrt, uint256_eq

### =========== constants ============   

const TOKEN_A = 1
const ADDRESS_A = 0xA71775cf1e309d254c882fC7B6bc61338a5656DA

const TOKEN_B = 2
const ADDRESS_B = 0x0A1fb0ec3B837aAdDdFDC1e989C77649a4856a41

const USER = 1

### ============= interface =============

@contract_interface
namespace ITempest:
    func initialize(
    name : felt, 
    symbol : felt, 
    decimals : felt, 
    initial_supply : Uint256, 
    recipient : felt, 
    owner : felt
) -> ():
    end
end

### ============= tests ==============

@external
func test_proxy_tempest{
        syscall_ptr : felt*,
        range_check_ptr,
}():
    alloc_locals

    local contract_address : felt
    %{ ids.contract_address = deploy_contract(
        "./src/tempest.cairo", 
        [0, 1]).contract_address 
    %}

    return()
end












