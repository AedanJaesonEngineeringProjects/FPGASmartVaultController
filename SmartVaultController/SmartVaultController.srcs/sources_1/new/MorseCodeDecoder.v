`timescale 1ns / 1ps

module MorseCodeDecoder(
    input wire clk,
    input wire morseInput, // Button input for Morse code
    input wire enable,
    input wire beat,
    input wire double_beat,
    
    output reg [3:0] ssdOutput = 4'd12, // SSD output to display dot or dash
    output reg validPin, // Indicates a valid pin sequence was received
    output reg [7:0] morseLEDs
    );

    parameter integer SEQUENCE_LENGTH = 10;
    reg inputPrevState = 0; // Previous state of morseInput to detect edges
    reg [4:0] sequenceCounter = 0;
    reg [9:0] pinSequence;
    reg [2:0] state, nextstate;

    parameter OFF=2'd0, RECORDING=2'd1, CHECK=2'd2, DISPLAY_ON=2'd3;
    reg pin_checked;
    reg [7:0] pinBCD;
    reg [1:0] beat_counter;
    reg [2:0] timer;
  
    initial begin
        state = OFF;
    end
  
    // current state transition
    always @(posedge clk) begin 
        state <= nextstate;
    end 
    
     // timer increments every second when in relevant states
    always @(posedge clk) begin
        // reset timer when a state change occurs
        if (state != nextstate) begin
            timer <= 3'd0;
        end else if (beat && state == DISPLAY_ON) begin
            timer <= timer + 1'b1;    
        end
        else begin
            timer <= timer;
        end
    end
 
    always @(posedge clk) begin 
        // reset all relevant registers on statechange (unless the sequence is being checked)
        if (state != nextstate && nextstate != CHECK) begin
            sequenceCounter <= 5'd0;
            pin_checked <= 1'b0;
            validPin <= 1'b0;
            pinSequence <= 10'd0;
        end else if (state == OFF) begin // reset the SSD
            ssdOutput <= 4'd12;
        end else if (state == RECORDING) begin
            if (morseInput && beat_counter < 2'd3) begin // record timing for the button press
                ssdOutput <= 4'd12;
                if (double_beat) beat_counter <= beat_counter + 1'b1; // beat_counter caps at 3
            end 
            // if the button is released, and it was held for at least 1 time unit, process the input
            else if (!morseInput && inputPrevState && beat_counter > 0) begin
                if (beat_counter < 2'd3) begin // less than dash threshold = dot
                    ssdOutput <= 4'd11; // 11 represents a dot in the SSDecoder
                    pinSequence <= (pinSequence << 1) | 1'b1;
                end else begin // beat counter = 3, its a dash
                    ssdOutput <= 4'd10; // 10 represents a dash in the SSDecoder
                    pinSequence <= (pinSequence << 1) | 1'b0;
                end
                // reset beat_counter for next morse code digit, and track the current digits in the sequence
                beat_counter <= 2'd0;
                sequenceCounter <= sequenceCounter + 1;
            end
            inputPrevState <= morseInput;
        end else if (state == CHECK) begin
            case (pinSequence)
                // Each valid sequence mapped to its Morse code equivalent
                // Assuming pinSequence is [dash=0, dot=1] and from left to right
                10'b0000000111: begin // 07
                    validPin <= 1;
                    pinBCD <= 8'b00000111; // BCD for "07"
                end
                10'b0000100000: begin // 10
                    validPin <= 1;
                    pinBCD <= 8'b00010000; // BCD for "10"
                end
                10'b0001000011: begin // 23
                    validPin <= 1;
                    pinBCD <= 8'b00100011; // BCD for "23"
                end
                10'b0001100100: begin // 34
                    validPin <= 1;
                    pinBCD <= 8'b00110100; // BCD for "34"
                end
                10'b0010100110: begin // 56
                    validPin <= 1;
                    pinBCD <= 8'b01010110; // BCD for "56"
                end
                10'b0011000111: begin // 67
                    validPin <= 1;
                    pinBCD <= 8'b01100111; // BCD for "67"
                end
                10'b0011100010: begin // 72
                    validPin <= 1;
                    pinBCD <= 8'b01110010; // BCD for "72"
                end
                10'b0011101000: begin // 78 (Note: Same as 72, needs correction if it's different)
                    validPin <= 1;
                    pinBCD <= 8'b01111000; // BCD for "78"
                end
                10'b0001100111: begin // 37
                    validPin <= 1;
                    pinBCD <= 8'b00110111; // BCD for "37"
                end
                10'b0010000101: begin // 45
                    validPin <= 1;
                    pinBCD <= 8'b01000101; // BCD for "45"
                end
                10'b0100001001: begin // 89
                    validPin <= 1;
                    pinBCD <= 8'b10001001; // BCD for "89"
                end
                10'b0100100010: begin // 92
                    validPin <= 1;
                    pinBCD <= 8'b10010010; // BCD for "92"
                end
                default: begin
                    validPin <= 0;
                    ssdOutput <= 4'd12;
                    pinBCD <= 8'b00000000; // Clear BCD output for invalid pin           
                end  
            endcase
            pin_checked <= 1'b1;
        end
    end
 
    // next-state logic
    always @(*) begin
        case(state) 
            OFF: begin
                if (enable) begin
                    nextstate = RECORDING;
                end else begin
                    nextstate = OFF; 
                end 
            end
            RECORDING: begin
                if (!enable) begin
                    nextstate = OFF;
                end else if (sequenceCounter == SEQUENCE_LENGTH) begin
                    nextstate = CHECK;
                end else begin
                    nextstate = RECORDING;
                end
            end
            CHECK: begin
                if (pin_checked) begin
                    if (validPin) begin
                        nextstate = DISPLAY_ON;
                    end else begin
                        nextstate = RECORDING;
                    end
                end else begin
                    nextstate = CHECK;
                end
            end
            DISPLAY_ON: begin
                if(timer == 3'd4) begin
                    nextstate = OFF;
                end else begin
                    nextstate = DISPLAY_ON;
                end
            end                         
        endcase
    end

    // output logic
    always @(*) begin
        case(state) 
            DISPLAY_ON: begin
                morseLEDs = pinBCD;
            end
            default: begin
                morseLEDs = 8'd0;
            end
        endcase
    end
endmodule

 