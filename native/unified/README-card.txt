AM2ARM for ARM64 Linux

1. Extract the Linux launcher ZIP on your computer. If extraction creates
   a folder named like the ZIP, open it. You should see am2arm-launcher,
   ports, Tools, Apps and App together.
2. Using a card reader or USB file transfer, copy everything inside to the
   destination for your firmware. Merge the folders if prompted.

   On ROCKNIX, open games-internal/roms on the system card, roms on a
   separate games card, or the games-roms network share.
   On AmberELEC, let the handheld finish its first boot, then open GAMES.
   On NextUI, stock TrimUI and spruceOS, open the top level of the game card.
   On other supported Ports firmware, open the ROM library containing ports.

3. Put your original Windows AM2R_11.zip beside am2arm-launcher. Keep it
   zipped and allow 500 MB of free space after copying.
4. Open AM2ARM in Ports on ROCKNIX and other supported Ports firmware,
   Tools on NextUI, or Apps on stock TrimUI and spruceOS. The first launch
   installs and starts the game. Open the same entry next time to play.

With two screens, the game asks once which shows the gameplay, or whether
to use one. Options > Display changes it at any time. If the installer asks
for the original ZIP, select it with the D-pad and A. This also works with a
renamed backup.

On one screen, the game fits the picture to your screen. To choose another
aspect ratio, open Options > Display. To exit to the handheld menu, save at a
station and hold Start + Select for one second. On a Smart Pro S with spruceOS,
the Menu button also works if its tap or hold action is set to Exit game in
the firmware.

The launcher runs directly from your handheld menu. Installation and gameplay
work offline. The firmware supplies the display, sound and controller drivers.

On ROCKNIX, check these paths from the ROM library if the entry is missing.
  AM2R_11.zip
  am2arm-launcher/launch.sh
  ports/AM2ARM.sh
Then open Start > Game Settings > Update Gamelists. On Ports firmware with a
capital Roms directory, open Roms as the destination before copying.

Already playing? Replace am2arm-launcher with the new one and open AM2ARM.
It updates the game from your original ZIP. Games and saves stay in
AM2ARM-data, and saves from the earlier Standard and Dual Screen editions are
copied there the first time. Options > Data backs saves up to
AM2ARM-data/saves/backup and restores them, including PC saves.

For help with a supported ARM64 handheld, include your model, firmware and
am2arm-launcher/AM2ARM/logs/compatibility.txt. On direct-display firmware the same
logs folder contains the installer and game logs.
https://github.com/PatchDev-AM2ARM/AM2ARM

Thanks to Jeod for suggesting first-launch patching and sharing the LADXHD
and AM2R PortMaster launchers as references.
https://github.com/JeodC/RHH-Ports/tree/main/ports/released/zelda-ladxhd
https://github.com/JeodC/RHH-Ports/tree/main/ports/released/gamemakerengine/am2r
