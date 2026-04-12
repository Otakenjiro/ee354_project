# ee354_project
Pokemon Battle Simulator on Nexys A7-100T (Artix-7 FPGA) with VGA output.

## Design Sources
- `src/pokemon_vga_top.v` — top module (set as top)
- `src/battle_scene.v` — battle animation state machine & sprite compositing
- `src/background_gen.v` — reusable VGA background (sky, trees, grass, diagonal path)
- `display_controller.v` — VGA timing (hSync, vSync, 640x480 @ 60 Hz)
- `pokemon_sprites/charizard_12_bit_rom.v` — Charizard 80x80 sprite ROM
- `pokemon_sprites/pikachu_12_bit_rom.v` — Pikachu 80x80 sprite ROM

## Constraints
- `constraints/pokemon_vga.xdc` — Nexys A7-100T pin assignments

## How to Run

1. Open **Vivado** and create a new RTL project targeting **xc7a100tcsg324-1** (Nexys A7-100T).
2. Add all 6 design sources listed above.
3. Add the constraints file `constraints/pokemon_vga.xdc`.
4. Set `pokemon_vga_top` as the top module.
5. Run **Synthesis** → **Implementation** → **Generate Bitstream**.
6. Open **Hardware Manager**, connect to the board, and program the bitstream.
7. Connect a VGA monitor to the board's VGA port.

## Controls
| Button | Action |
|--------|--------|
| **BtnR** | Charizard attacks Pikachu (lunge → return → Pikachu shakes/flashes red) |
| **BtnL** | Pikachu attacks Charizard (lunge → return → Charizard shakes/flashes red) |

## Architecture

```
pokemon_vga_top
├── display_controller    (25 MHz pixel clock, VGA sync signals)
├── background_gen        (procedural background: sky, trees, grass, path)
├── charizard_rom         (80x80 sprite, 12-bit color)
├── pikachu_rom           (80x80 sprite, 12-bit color)
└── battle_scene          (animation FSM, sprite addressing, transparency, pixel mux)
```

- **background_gen** is a standalone combinational module so it can be reused in other scenes (e.g. title screen, selection screen).
- Sprite transparency uses range-based color matching to filter out all background color variants from the ROM data.
- The animation state machine has 10 states (4-bit): idle, P1 lunge/return, P2 hit, P2 lunge/return, P1 hit, and a shared cooldown.
