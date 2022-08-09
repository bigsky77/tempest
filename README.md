								
 
 ##       🌊🌊🌊🌊🌊🌊🌊🌊🌊🌊
 ##       Welcome to Tempest!
  
Tempest is Starknet based AMM that impliments full Uniswap V2 style functionality on starknet.   
 
### Installation

Make sure you have Protostar installed.

```sh
protostar build --cairo-path ./cairo_contracts/src
```

### Test

```sh
protostar test 
```

### Test Specific Contract

Router

```sh
protostar test tests/router 
```

Tempest

```sh
protostar test tests/tempest

Factory

```sh
protostar test tests/factory
