# ee354_project
Pokemon-based simulator using Artix-7 FPGA 

## Design Sources
- `src/pokemon_vga_top.v` — (set as top)
- `src/battle_scene.v` — battle scene state machine
- `display_controller.v` — VGA timing (hSync, vSync, 640x480 @ 60Hz)
- `pokemon_sprites/charizard_12_bit_rom.v`
- `pokemon_sprites/pikachu_12_bit_rom.v`

## Constraints
- `constraints/pokemon_vga.xdc`

## How to Run

1. Open Vivado, create a new project targeting **xc7a100tcsg324-1**
2. Add the 5 design sources listed above
3. Add the constraints file
4. Set `pokemon_vga_top` as the top module
5. Run Synthesis → Implementation → Generate Bitstream
6. Program the board via Hardware Manager
7. **BtnR** — trigger attack animation (Charizard lunges at Pikachu)

This is a basic version of the attack animation, we can adjust the size of the characters later, the background needs to be added and the backgrounds of the pokemon need to be adjusted, right now charizard and pikachu are hard coded but the animation works.

