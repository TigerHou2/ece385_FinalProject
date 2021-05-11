=========================
SUMMARY
=========================

This is the root directory of my final project for the ECE 385 Spring 2021
course at the University of Illinois at Urbana-Champaign. This file contains
a brief description of the project and instructions on how to run the project
on the DE10-Lite FPGA.


=========================
DESCRIPTION 
=========================

This project is a TF2 (Team Fortress 2) themed 2D artillery game inspired by
Worm Clan Wars / Tank Wars. The game features two opposing characters who
fire projectiles along parabolic trajectories with the goal of defeating
their opponent. 

Characters are spawned onto pseudo-randomly generated, deformable terrain,
and players control the movement, power, and angle of their characters'
projectiles. Health is deducted when a player is hit either by direct impact
or a nearby explosion. Self damage is not implemented. An AI can be toggled 
for P2 to allow for either a single player or two players.


=========================
SETUP
=========================

1. You will need the following components:
    a) DE10-LITE FPGA with USB blaster cable;
    b) Arduino USB host shield*;
    c) USB keyboard;
    d) VGA monitor and a VGA cable.

2. Assemble the components:
    a) Install the USB shield onto the FPGA;
    b) Attach the USB keyboard to the USB shield;
    c) Connect the FPGA to the VGA monitor;
    d) Connect the FPGA to your computer via the USB blaster.

3. Load the project onto the FPGA via the USB blaster. You shouldn't need to
compile the project. The monitor should display some terrain with two
characters (red and blue) and a background. 

4. Press KEY0 on the FPGA to reset the environment.

5. Open the Eclipse editor, build the C program and run it on the FPGA. This
allows the characters to be controlled and also starts the AI.

* I used a shield specifically provided for the ECE 385 course designed by
Professor Zuofu Cheng.


=========================
GAMEPLAY
=========================

- The two characters can jump, move left/right, aim, and shoot. 

- Shooting is controlled by one button. Holding down the shoot button will
charge up a shot (longer hold = farther shot) as indicated by seven short
bars under the healthbar. The charging loops back to minimum power after the
maximum is reached.

- Aiming is controlled by two buttons, which either adjust the aim clockwise
or counterclockwise. The aim angle is bounded to +/- 90 degrees from 
vertical.

- Player 1 controls : W (Jump), A (Left), D (Right),
                      S (Shoot), Q (aim CCW), E (aim CW)

- Player 2 controls : I (Jump), J (Left), L (Right),
                      K (Shoot), 8 (aim CCW), 9 (aim CW)

- KEY1 on the FPGA toggles the AI for Player 2. This allows the game to be
either played by one or two players.

- Switches 9-0 control the seed for pseudo-random terrain generation. Once a
new seed is selected, press KEY0 on the FPGA to reset the game and load in
the new terrain.

- Switch 9 controls the map background. Resetting is not needed for the
background to change. There are two background options.


=========================
KNOWN ISSUES
=========================

- Seed 0 generates a patterned terrain with repeating hills.
