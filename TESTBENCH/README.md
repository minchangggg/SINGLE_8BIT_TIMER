// Truy cập reg_def.v như nào, có cần cop bỏ sang folder này ko
// file tb gọi file testcase, hay ngược lại

## [NOTE]
### `Coverage report` 
```verilog
vlog -coveropt 3 +cover +acc basicSimulation/basicSimulation/counter/counter.v basicSimulation/basicSimulation/counter/tcounter.v 
 
vsim -coverage -vopt work.test_counter -c -do "coverage save -onexit -directive -codeAll counter.ucdb;run -all" 
 
vcover report -html counter.ucdb
```

