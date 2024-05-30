`timescale 1ns / 1ps

module smart_vault_controller_TOP(
    // clock
    input wire clk,
    // buttons
    input wire btnC,
    input wire btnD,
    input wire btnL,
    input wire btnR,
    // slide switches
    input wire [15:0] SW,
    // LEDs
    output wire [15:0] LED,
    // SSDs
    output wire [7:0] ssdCathode,
    output wire [3:0] ssdAnode
    );
    
    wire [31:0] SSDs; // 7 most significant bits refers to the left-most SSD
    
    wire [3:0] ppl_counter;
    wire vault_occupied;
    
    wire deb_outC, deb_outR, deb_outL, deb_outD;
    wire spot_outC, spot_outR, spot_outL;
    
    wire deb_outSW7_up, deb_outSW7_down;
    wire deb_outSW8_up, deb_outSW8_down;
    wire spot_outSW7_up, spot_outSW7_down;
    wire spot_outSW8_up, spot_outSW8_down;
    wire double_SW7, double_SW8;
    
    wire beat, half_beat, double_beat;
    
// BUTTON DEBOUNCERS
    // center button
    debouncer deb_instC(.switchIn(btnC), .clk(clk), .reset(1'b0), .debounceout(deb_outC));
    spot spot_instC(.spot_in(deb_outC), .spot_out(spot_outC), .clk(clk));
    
    // left button
    debouncer deb_instL(.switchIn(btnL), .clk(clk), .reset(1'b0), .debounceout(deb_outL));
    spot spot_instL(.spot_in(deb_outL), .spot_out(spot_outL), .clk(clk));
    
    // right button
    debouncer deb_instR(.switchIn(btnR), .clk(clk), .reset(1'b0), .debounceout(deb_outR));
    spot spot_instR(.spot_in(deb_outR), .spot_out(spot_outR), .clk(clk));
    
    // down button (no SPOT because the button needs to be held (morse code)
    debouncer deb_instD(.switchIn(btnD), .clk(clk), .reset(1'b0), .debounceout(deb_outD));

// SWITCH DEBOUNCERS
    debouncer deb_instSW7_up(.switchIn(SW[7]), .clk(clk), .reset(1'b0), .debounceout(deb_outSW7_up));
    debouncer deb_instSW7_down(.switchIn(~SW[7]), .clk(clk), .reset(1'b0), .debounceout(deb_outSW7_down));
    spot spot_instSW7_up(.spot_in(deb_outSW7_up), .spot_out(spot_outSW7_up), .clk(clk));
    spot spot_instSW7_down(.spot_in(deb_outSW7_down), .spot_out(spot_outSW7_down), .clk(clk));
    
    debouncer deb_instSW8_up(.switchIn(SW[8]), .clk(clk), .reset(1'b0), .debounceout(deb_outSW8_up));
    debouncer deb_instSW8_down(.switchIn(~SW[8]), .clk(clk), .reset(1'b0), .debounceout(deb_outSW8_down));
    spot spot_instSW8_up(.spot_in(deb_outSW8_up), .spot_out(spot_outSW8_up), .clk(clk));
    spot spot_instSW8_down(.spot_in(deb_outSW8_down), .spot_out(spot_outSW8_down), .clk(clk));
    
    assign double_SW7 = spot_outSW7_up ^ spot_outSW7_down;
    assign double_SW8 = spot_outSW8_up ^ spot_outSW8_down;
    
    // 1Hz heartbeat gen
    clockDividerHB #(.THRESHOLD(50_000_000)) beatgen (.clk(clk), .enable(1'b1), .reset(1'b0), .beat(beat), .dividedClk());
    // 0.5Hz heartbeat gen
    clockDividerHB #(.THRESHOLD(100_000_000)) halfbeatgen (.clk(clk), .enable(1'b1), .reset(1'b0), .beat(half_beat), .dividedClk());
    // 2Hz heartbeat gen
    clockDividerHB #(.THRESHOLD(25_000_000)) doublebeatgen (.clk(clk), .enable(1'b1), .reset(1'b0), .beat(double_beat), .dividedClk());
    
// SSD MANAGER
    SSD_manager
    SSD_man_inst(
        .clk(clk),
        .SSDs(SSDs),
        .ssdCathode(ssdCathode),
        .ssdAnode(ssdAnode)
    );
    
// DOOR ACCESS
    door_access_controller
    DAC_inst(
        .clk(clk),
        .ENTER(spot_outR),
        .SECURITY_RESET(spot_outC),
        .morse_code_in(deb_outD),
        .DOOR_MASTER(spot_outL),
        .beat(beat),
        .half_beat(half_beat),
        .double_beat(double_beat),
        .vault_occupied(vault_occupied),
        .ppl_counter(ppl_counter),
        .person_in(double_SW8),
        .person_out(double_SW7),
        .access_code(SW[15:9]),
        .door_status(LED[15:12]),
        .alarm(LED[11:8]),
        .ppl_in_vault(SSDs[31:24]),
        .ssd_morse_code_digit(SSDs[23:16]),
        .pinBCD(LED[7:0])
    );
   
// CLIMATE CONTROL
    climate_controller
    CC_inst(
        .clk(clk),
        .outside_temp(SW[5:3]),
        .desired_temp(SW[2:0]),
        .ppl_counter(ppl_counter),
        .vault_occupied(vault_occupied),
        .beat(beat),
        .half_beat(half_beat),
        .double_beat(double_beat),
        .SSDs(SSDs[15:0])
    );
    
endmodule