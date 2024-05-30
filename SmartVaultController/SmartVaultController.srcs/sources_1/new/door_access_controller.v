`timescale 1ns / 1ps

 module door_access_controller
    #(parameter
        // states
        PIN_ENTRY=3'b000,
        ALARM=3'b001,
        TRAP=3'b010,
        UNUSED=3'b011,
        DOOR_OPENING=3'b100,
        DOOR_OPEN=3'b101,
        DOOR_CLOSING=3'b110,
        VAULT_OCCUPIED=3'b111 
    )
    (
    // clock
    input wire clk,
    // buttons
    input wire ENTER,
    input wire SECURITY_RESET,
    input wire morse_code_in,
    input wire DOOR_MASTER,
    // slide switches
    input wire [6:0] access_code,
    input wire person_in,
    input wire person_out,
    // heartbeats
    input wire beat,
    input wire double_beat,
    input wire half_beat,
    
    output reg vault_occupied,
    output reg [3:0] ppl_counter,
    // LEDs
    output reg [3:0] door_status,
    output reg [3:0] alarm,
    output wire [7:0] pinBCD,
    
    // SSDs
    output wire [7:0] ppl_in_vault,
    output wire [7:0] ssd_morse_code_digit
    );
    
    reg [2:0] state, nextstate;
    
    reg [4:0] timer;
    
    wire [6:0] correct_pin;
    assign correct_pin = 7'b0011011;
    wire [6:0] reset_pin = 7'b1010101;

    wire [3:0] morse_code_digit;
    
    initial begin
        state = PIN_ENTRY;
    end
    
    MorseCodeDecoder morse_decoder (
        .clk(clk),
        .morseInput(morse_code_in),
        .enable(vault_occupied),
        .beat(beat),
        .double_beat(double_beat),
        .ssdOutput(morse_code_digit),  // Connect Morse code digit output
        .validPin(validPin),
        .morseLEDs(pinBCD)
    );
    
    // SSD to display # of people in the vault
    sevenSegmentDecoder ssd_inst (.bcd(ppl_counter), .ssd(ppl_in_vault));
    sevenSegmentDecoder ssd_morse_inst(
        .bcd(morse_code_digit),  // Input: 4-bit Morse code digit
        .ssd(ssd_morse_code_digit)  // Output: segments to display the digit
    );
    
    // current state transition
    always @(posedge clk) begin
        state <= nextstate;
    end
    
    // timer increments every second when in relevant states
    always @(posedge clk) begin
        // reset timer when a state change occurs
        if (state != nextstate) begin
            timer <= 5'd0;
        end else if (beat && (state == ALARM || state == DOOR_OPENING || state == DOOR_OPEN || state == DOOR_CLOSING || state == VAULT_OCCUPIED)) begin
            timer <= timer + 1'b1;    
        end
        else begin
            timer <= timer;
        end
    end
    
    // handle alarm LEDs
    always @(posedge clk) begin
        if (state == ALARM) begin
            if (half_beat) alarm <= ~alarm; // fast toggle in TRAP state
            else alarm <= alarm;
        end else if (state == TRAP) begin
            if (double_beat) alarm <= ~alarm; // slow toggle in ALARM state
            else alarm <= alarm;
        end else begin
            alarm <= 4'b0000;
        end
    end
    
    // Handle door status LEDs
    always @(posedge clk) begin
        if (state == DOOR_OPENING) begin
            if (beat) door_status <= door_status >> 1; // shift LEDs off one-by-one
        end else if (state == DOOR_CLOSING) begin
            if (beat) door_status <= door_status << 1 | 4'b0001; // shift LEDs with 1 (ON) one-by-one
        end else if (state == DOOR_OPEN) begin
            door_status <= 4'b0000;
        end else begin
            door_status <= 4'b1111;
        end
    end
    
    // handle entry/exit switches for counting people in the vault with the door open
    always @(posedge clk) begin
        if (person_in && state == DOOR_OPEN && ppl_counter < 4'd9) begin // add people
            ppl_counter <= ppl_counter + 1'b1;
        end else if (person_out && state == DOOR_OPEN && ppl_counter > 4'd0) begin // remove people
            ppl_counter <= ppl_counter - 1'b1;
        end else begin
            ppl_counter <= ppl_counter;
        end
    end
    
    // next state logic
    always @(*) begin
        case(state)
            PIN_ENTRY: begin
                if (ENTER) begin
                    if (access_code == correct_pin) begin
                        nextstate = DOOR_OPENING;
                    end else begin // incorrect code
                        nextstate = ALARM;
                    end
                end else if (DOOR_MASTER) begin
                    nextstate = DOOR_OPENING;    
                end else begin
                    nextstate = PIN_ENTRY;
                end
            end
            ALARM: begin
                if (SECURITY_RESET) begin
                    nextstate = PIN_ENTRY;
                end else if (ENTER) begin
                    if (access_code == correct_pin) begin
                        nextstate = DOOR_OPENING;
                    end else begin // incorrect code
                        nextstate = TRAP;
                    end
                end else if (timer == 5'd20) begin // 20 seconds has elapsed
                    nextstate = TRAP;
                end else if (DOOR_MASTER) begin
                    nextstate = DOOR_OPENING;                    
                end else begin
                    nextstate = ALARM;
                end
            end
            TRAP: begin
                if (SECURITY_RESET) begin
                    nextstate = PIN_ENTRY;
                end else if (access_code == reset_pin && ENTER) begin
                    nextstate = PIN_ENTRY; 
                end else if (DOOR_MASTER) begin
                    nextstate = DOOR_OPENING;      
                end else begin
                    nextstate = TRAP;
                end
            end
            DOOR_OPENING: begin
                if (timer == 5'd4) begin // 4 seconds has elapsed
                    nextstate = DOOR_OPEN;
                end else begin
                    nextstate = DOOR_OPENING;
                end
            end
            DOOR_OPEN: begin
                if (timer == 5'd30) begin // 30 seconds has elapsed
                    nextstate = DOOR_CLOSING;
                end else begin
                    nextstate = DOOR_OPEN;
                end
            end
            DOOR_CLOSING: begin
              if (timer == 5'd4) begin // 4 seconds has elapsed
                 if (ppl_counter > 4'd0) begin
                    nextstate = VAULT_OCCUPIED;
                 end else begin
                    nextstate = PIN_ENTRY;
                 end
              end else begin
                 nextstate = DOOR_CLOSING;
              end
            end
            VAULT_OCCUPIED: begin
                // Preventing new entries, allow only exits or emergency reset
                if (ppl_counter == 0) begin
                    nextstate = PIN_ENTRY; // Transition to PIN_ENTRY if vault becomes empty
                end else if (validPin) begin
                    nextstate = DOOR_OPENING;
                end else if (DOOR_MASTER) begin
                    nextstate = DOOR_OPENING;                  
                end else begin
                    nextstate = VAULT_OCCUPIED;
                end
            end
            
           
        endcase
    end
    
    // set vault_occupied register for other modules to check if the vault is occupied
    always@(*) begin
        case(state)
            VAULT_OCCUPIED: begin
                vault_occupied = 1'b1;
            end
            default: begin
                vault_occupied = 1'b0;
            end
        endcase
    end
     
    
endmodule