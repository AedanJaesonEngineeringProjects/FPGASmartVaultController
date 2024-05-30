`timescale 1ns / 1ps

module SSD_manager (
    input wire clk,
    input wire [31:0] SSDs,
    output reg [7:0] ssdCathode,
    output reg [3:0] ssdAnode
    );
    
    wire beat;
    
    // 1000Hz
    clockDividerHB #(
        .THRESHOLD(50_000)
        )
    clockDivHB_inst(
        .clk(clk),
        .enable(1'b1),
        .reset(1'b0),
        .beat(beat),
        .dividedClk()
    );
    
    // cycle through each of the 4 SSDs (this register will overflow to keep looping)
    reg [1:0] activeDisplay;
    always @(posedge clk) begin
        if (beat == 1'b1) begin
            activeDisplay <= activeDisplay + 1'b1;
        end
    end

    // For each anode, map the corresponding SSD cathode to the output
    always @(*) begin
        case(activeDisplay)
        2'd0: begin
            ssdCathode = SSDs[31:24];
            ssdAnode = 4'b0111;
        end
        2'd1: begin
            ssdCathode = SSDs[23:16];
            ssdAnode = 4'b1011;
        end
        2'd2: begin
            ssdCathode = SSDs[15:8];
            ssdAnode = 4'b1101;
        end
        2'd3: begin
            ssdCathode = SSDs[7:0];
            ssdAnode = 4'b1110;
        end
        default : begin
            ssdCathode = 8'b11111111;
            ssdAnode = 4'b1111;
        end
        endcase
    end
    
endmodule