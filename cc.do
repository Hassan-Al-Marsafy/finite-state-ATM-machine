vlib work
vlog edaii.v eda_TBii.v +cover
vsim -voptargs=+acc work.atm_tb -cover 
add wave *
coverage save atm_tb.ucdb -onexit -du ATM
run -all