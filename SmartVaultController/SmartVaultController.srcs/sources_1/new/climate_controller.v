`timescale 1ns / 1ps

module climate_controller 
    #(parameter
        STANDBY = 3'b000,
        ON = 3'b001,
        CLIMATE_OFF = 3'b010,
        DISPLAY_OFF = 3'b011,
        OFF = 3'b100
    )
    (
    // clock
    input wire clk,
    // slide switches
    input wire [2:0] outside_temp,
    input wire [2:0] desired_temp,
    input wire [3:0] ppl_counter,
    // heartbeats
    input wire beat,
    input wire double_beat,
    input wire half_beat,
    
    input wire vault_occupied,

    // SSDs
    output reg [15:0] SSDs // covers 2 SSDs
    );
    
    reg [2:0] state, nextstate;
    reg [4:0] timer;
    reg [2:0] current_temp;
    wire [15:0] local_ssds;
       
    sevenSegmentDecoder ssdec1_inst (.bcd(4'd2), .ssd(local_ssds[15:8])); // always shows '2'
    sevenSegmentDecoder ssdec2_inst (.bcd(current_temp), .ssd(local_ssds[7:0]));
    
    initial begin
        state = OFF;
        current_temp = outside_temp;
    end
       
    // current state transition
    always @(posedge clk) begin
        state <= nextstate;
    end    
    
    // timer increments every second when in relevant states
    always @(posedge clk) begin
        // reset timer when a state change occurs
        if (state != nextstate) begin
            timer <= 5'd0;
        end else if (beat && (state == CLIMATE_OFF || state == DISPLAY_OFF)) begin
            timer <= timer + 1'b1;    
        end
        else begin
            timer <= timer;
        end
    end
    
    // handle temperature change
    always @(posedge clk) begin
        if (state == ON) begin
            // adjust temperature based on the number of people in the vault
            if ((ppl_counter <= 4'd5 && double_beat) || (ppl_counter > 4'd5 && beat)) begin
                if (current_temp < desired_temp) begin
                    current_temp <= current_temp + 1'b1;    
                end else if (current_temp > desired_temp) begin
                    current_temp <= current_temp - 1'b1;
                end else begin
                    current_temp <= current_temp;
                end
            end else begin
                current_temp <= current_temp;
            end
        end else if (state == CLIMATE_OFF && half_beat) begin // stabilise temp to outside temp
            if (current_temp < outside_temp) begin
                current_temp <= current_temp + 1'b1;
            end else if (current_temp > outside_temp) begin
                current_temp <= current_temp - 1'b1;
            end else begin
                current_temp <= current_temp;
            end
        end
    end
    
    // next state logic
    always @(*) begin
        case(state)
            STANDBY: begin
                if (ppl_counter == 4'd0 && ~vault_occupied) begin // vault has been vacated
                    nextstate = CLIMATE_OFF;
                end else if (current_temp != desired_temp) begin // turn on active temperature adjustment
                    nextstate = ON;
                end else begin
                    nextstate = STANDBY;
                end
            end
            ON: begin
                if (ppl_counter == 4'd0 && ~vault_occupied) begin
                    nextstate = CLIMATE_OFF;
                end else if (current_temp == desired_temp) begin // temperature has adjusted
                    nextstate = STANDBY;
                end else begin
                    nextstate = ON;
                end
            end
            CLIMATE_OFF: begin
                if (ppl_counter > 4'd0 && vault_occupied) begin // vault is being occupied
                    nextstate = STANDBY;
                end else if (timer == 5'd10) begin // 10 seconds has elapsed
                    nextstate = DISPLAY_OFF;
                end else begin
                    nextstate = CLIMATE_OFF;
                end
            end
            DISPLAY_OFF: begin
                if (ppl_counter > 4'd0 && vault_occupied) begin
                    nextstate = STANDBY;
                end else if (timer == 5'd20) begin // 20 seconds has elapsed
                    nextstate = OFF;
                end else begin
                    nextstate = DISPLAY_OFF;
                end
            end
            OFF: begin
                if (ppl_counter > 4'd0 && vault_occupied) begin
                    nextstate = STANDBY;
                end else begin
                    nextstate = OFF;
                end
            end
            default: begin
                nextstate = OFF;
            end
        endcase
    end
    
    // output logic
    always @(*) begin
        case(state)
            STANDBY: begin
                SSDs = local_ssds;
            end
            ON: begin
                SSDs = local_ssds;
            end
            CLIMATE_OFF: begin
                SSDs = local_ssds;
            end
            DISPLAY_OFF: begin
                SSDs = local_ssds;
            end
            default: begin
                SSDs = 16'b11111111_11111111; // blank
            end
        endcase
    end
    
endmodule