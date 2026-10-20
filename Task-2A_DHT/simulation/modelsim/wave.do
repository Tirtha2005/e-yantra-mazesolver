onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk_50M
add wave -noupdate /tb/reset
add wave -noupdate /tb/sensor
add wave -noupdate /tb/T_integral
add wave -noupdate /tb/T_decimal
add wave -noupdate /tb/RH_integral
add wave -noupdate /tb/RH_decimal
add wave -noupdate /tb/Checksum
add wave -noupdate /tb/data_valid
add wave -noupdate /tb/exp_T_integral
add wave -noupdate /tb/exp_T_decimal
add wave -noupdate /tb/exp_RH_integral
add wave -noupdate /tb/exp_RH_decimal
add wave -noupdate /tb/exp_Checksum
add wave -noupdate /tb/exp_data_valid
add wave -noupdate /tb/error_count
add wave -noupdate /tb/fw
add wave -noupdate /tb/j
add wave -noupdate /tb/sensor_driver
add wave -noupdate /tb/sensor_drive_enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {57396590216 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {78750 us}
