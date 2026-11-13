create_pblock pblock_u_aes_rm
add_cells_to_pblock [get_pblocks pblock_u_aes_rm] [get_cells -quiet [list u_aes_rm]]
resize_pblock [get_pblocks pblock_u_aes_rm] -add {CLOCKREGION_X1Y1:CLOCKREGION_X1Y2}
set_property SNAPPING_MODE ON [get_pblocks pblock_u_aes_rm]
