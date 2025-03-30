module Fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 10
) (
    input logic writeClk,
    input logic writeRst,

    input logic readClk,
    input logic readRst,

    input logic write,
    input logic [WIDTH-1:0] writeData,
    output logic full,

    input logic read,
    output logic [WIDTH-1:0] readData,
    output logic empty
);
  localparam int WIDTH_PTR = DEPTH + 1;

  logic [WIDTH-1:0] buffer[0:2**DEPTH-1];

  logic [WIDTH_PTR-1:0] head;
  logic [WIDTH_PTR-1:0] tail;

  logic [WIDTH_PTR-1:0] headSyncReadClk;
  logic [WIDTH_PTR-1:0] tailSyncWrtieClk;

  always_ff @(posedge writeClk)
    if (writeRst) begin
      head <= 0;
    end else if (write && ~full) begin
      buffer[head[DEPTH-1:0]] <= writeData;
      head <= head + 1;
    end

  always_ff @(posedge readClk)
    if (readRst) begin
      tail <= 0;
      readData <= 0;
    end else if (read && ~empty) begin
      readData <= buffer[tail[DEPTH-1:0]];
      tail <= tail + 1;
    end

  Dispatcher #(
      .WIDTH(WIDTH_PTR)
  ) write2read (
      .outClk(readClk),
      .outRst(readRst),
      .in(head),
      .out(headSyncReadClk)
  );

  Dispatcher #(
      .WIDTH(WIDTH_PTR)
  ) read2write (
      .outClk(writeClk),
      .outRst(writeRst),
      .in(tail),
      .out(tailSyncWrtieClk)
  );

  always_comb
    if (head[DEPTH-1:0] == tailSyncWrtieClk[DEPTH-1:0] && head[DEPTH] != tailSyncWrtieClk[DEPTH]) begin
      full = 1;
    end else begin
      full = 0;
    end

  always_comb
    if (tail[DEPTH-1:0] == headSyncReadClk[DEPTH-1:0] && tail[DEPTH] == headSyncReadClk[DEPTH]) begin
      empty = 1;
    end else begin
      empty = 0;
    end

endmodule
