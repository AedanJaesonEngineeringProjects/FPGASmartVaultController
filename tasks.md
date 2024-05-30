## Meeting Notes - 30/03/2024

- Use one hot encoding for encoding both the climate control and door access control states

Tasks:
- Brady: Vault entry features (door access controller)
- Aedan: Vault exit features (door access controller, incl. advanced morse code SSD/LED feature)

## Meeting Notes - 02/04/2024

Tasks:
- Brady: Climate controller and switches including temperature SSDs
- Aedan: Morse code decoder, door master button, door closing and potentially ON/OFF SSD for climate control




Demo Example Structure:

1. Show that we can't add people to a closed vault (switch 7 and 8)
2. Input incorrect PIN
3. Input incorrect PIN again
4. Input security PIN (1010101)
5. Input incorrect PIN to show ALARM LEDs, wait for TRAP state to show the timer (10sec to go to TRAP)
6. Use SECURITY_RESET button
7. Input correct PIN (0011011)
8. Add/remove people from vault with switch 7 and 8 (show lower and upper bounds).
9. Leave 5 people in the vault
10. Change desired temp (switches 0-2) to 22
11. Change desired temp to 27 (after it settles from previous step)
12. Show invalid dot first (<0.5s), then show dot (0.5-1.5s), then show dash (>1.5s).
13. Do 8 dots to clear the "cache" (show that the LED turns off after 10 presses)
14. Enter morse code "- - - - - - - . . ." (07)
15. Remove everyone from the vault.
16. wait till CC SSDs turn off
17. press DOOR_MASTER
18. add 6 people to vault (then wait for door to close)
19. see the CC SSDs are slower to updated
20. press DOOR_MASTER again