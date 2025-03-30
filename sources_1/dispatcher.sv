module Dispatcher #(
    parameter int WIDTH
) (
    input logic outClk,
    input logic outRst,
    input logic [WIDTH - 1:0] in,
    output logic [WIDTH - 1:0] out
);
  logic [WIDTH - 1:0] unsyncData;
  logic [WIDTH - 1:0] syncData;

  Bin2Gray #(
      .WIDTH(WIDTH)
  ) bin2Gray (
      .bin (in),
      .gray(unsyncData)
  );

  Sync #(
      .WIDTH(WIDTH)
  ) sync (
      .syncClk(outClk),
      .syncRst(outRst),
      .unsyncData(unsyncData),
      .syncData(syncData)
  );

  Gray2Bin #(
      .WIDTH(WIDTH)
  ) gray2bin (
      .gray(syncData),
      .bin (out)
  );

endmodule

module Sync #(
    parameter int WIDTH
) (
    input logic syncClk,
    input logic syncRst,
    input logic [WIDTH - 1:0] unsyncData,
    output logic [WIDTH - 1:0] syncData
);
  logic [WIDTH - 1:0] trigger1;
  logic [WIDTH - 1:0] trigger2;

  always_ff @(posedge syncClk)
    if (syncRst) begin
      trigger1 <= 0;
      trigger2 <= 0;
    end else begin
      trigger1 <= unsyncData;
      trigger2 <= trigger1;
    end

  assign syncData = trigger2;

endmodule

module Bin2Gray #(
    parameter int WIDTH
) (
    input  logic [WIDTH - 1:0] bin,
    output logic [WIDTH - 1:0] gray
);

  assign gray = (bin >> 1) ^ bin;

endmodule

module Gray2Bin #(
    parameter int WIDTH
) (
    input  logic [WIDTH-1:0] gray,
    output logic [WIDTH-1:0] bin
);
  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin : gen_gray2bin
      assign bin[i] = ^(gray >> i);
    end
  endgenerate

endmodule
