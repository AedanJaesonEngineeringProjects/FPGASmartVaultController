# Smart Vault Controller using Basys3 FPGA Development Board

## Overview
The Smart Vault Controller project is an advanced security and environmental control system implemented on the Basys3 FPGA Development Board. It integrates robust access control with automated climate regulation, ensuring both security and optimal environmental conditions within a vault.

## Key Features
1. **Vault Door Access Control**
2. **Automated Climate Control**

## User Interface

### Components
1. **Slide Switches**
   - **PIN Input:** 7-digit binary PIN input.
   - **People Control:** Add/remove people from the vault.
   - **Temperature Control:** Input the outside and desired temperatures.

2. **Buttons**
   - **DOOR_MASTER:** Emergency door open.
   - **SECURITY_RESET:** Reset the security alarm.
   - **ENTER:** Confirm PIN or security code.
   - **Morse Code:** Input morse code for emergency exit.

3. **LEDs**
   - Indicate the status of the vault door, alarm, and entered morse code.

4. **Seven Segment Displays (SSD)**
   - Show the number of people in the vault, current temperature, and morse code input status.

## Functionalities Implemented

### Vault Door Access Control
- **Vault Entry:** Controlled by a 7-digit binary PIN. Incorrect attempts trigger an alarm.
- **Vault Exit:** Requires a correct 10-digit morse code sequence for people inside the vault.
- **Emergency Access:** Emergency button to open the door anytime.
- **Automatic Door Control:** Door status LEDs indicate door opening/closing progress.

### Automated Climate Control
- **Temperature Regulation:** Adjusts internal vault temperature to match the desired temperature based on occupancy.
- **Outside Temperature Equalization:** When the vault is vacated, the temperature equalizes with the outside environment.
- **Dynamic Rate Adjustment:** Temperature change rate varies with the number of people in the vault.

## Project Structure

### Top Module
This module integrates the Vault Door Access Control and Automated Climate Control features, managing all input/output data.

#### Block Circuit Diagram
- **Heartbeat Generators:** Generate synchronized timing signals.
- **Debouncers and SPOTs:** Filter noise from user inputs.
- **Door Access Controller:** Manages vault access control and security.
- **Climate Controller:** Automates vault climate control based on occupancy and settings.
- **SSD Manager:** Manages the seven-segment displays.

### Design Choices
- **Debouncers and SPOTs:** Implemented to handle the bouncing nature of mechanical switches and ensure stable inputs.
- **Resource Saving:** Shared heartbeat generators to optimize resource usage and maintain system synchronization.
- **FSM for Logic Implementation:** Finite State Machines (FSM) are used for clear and manageable state transitions in both door access control and climate control.

### Detailed Module Descriptions

#### Door Access Controller
Manages all features related to vault access, including:
- **State Management:** Utilizes an FSM to handle different states like PIN entry, alarm, trap, door opening/closing, and vault occupancy.
- **Morse Code Decoder:** Submodule to handle morse code input for vault exit.

#### Climate Controller
Handles the automated climate control within the vault:
- **State Management:** FSM used to manage climate control states like standby, active temperature adjustment, and display management.
- **Temperature Adjustment:** Changes vault temperature based on desired settings and occupancy.

## Assumptions
- **Morse Code Input:** Button presses shorter than 0.5 seconds are considered accidental.
- **Temperature Control:** Assumes default temperature equal to the outside temperature upon deployment, not when the climate controller first turns on.

## Conclusion
The Smart Vault Controller project showcases the integration of advanced security and climate control systems using FPGA technology. It demonstrates efficient resource management, user-friendly interface design, and robust state-driven logic implementation.
