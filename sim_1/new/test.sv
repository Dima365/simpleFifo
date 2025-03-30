module Test #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 10
) ();
  logic writeClk;
  logic writeRst;

  logic readClk;
  logic readRst;

  logic write;
  logic [WIDTH-1:0] writeData;
  logic full;

  logic read;
  logic [WIDTH-1:0] readData;
  logic empty;

  logic [WIDTH-1:0] queue_fifo[$];

  Fifo #(
      .WIDTH(WIDTH),
      .DEPTH(DEPTH)
  ) DUT (
      .*
  );

  always #10 writeClk = ~writeClk;
  always #13 readClk = ~readClk;

  always @(posedge writeClk)
    if (write && ~full) begin
      queue_fifo.push_front(writeData);
    end

  always @(posedge readClk)
    if (read && ~empty) begin
      #1
      if (queue_fifo.pop_back != readData) begin
        $display("************ ERROR ************** time: %t", $time);
        #100 $stop;
      end
    end

  task automatic ResetWrite();
    @(posedge writeClk);
    #1;
    writeRst = 1;
    #30 @(posedge writeClk);
    #1;
    writeRst = 0;
  endtask

  task automatic ResetRead();
    @(posedge readClk);
    #1;
    readRst = 1;
    #30 @(posedge readClk);
    #1;
    readRst = 0;
  endtask

  initial begin
    writeClk = 0;
    readClk = 0;
    write = 0;
    writeData = 0;
    read = 0;

    #30;
    fork
      ResetWrite();
      ResetRead();
    join

    WorkAroundEmpty();
    WorkAroundMiddle();
    WorkAroundFull();

    MakeFifoEmpty();

    WorkAroundFull();
    WorkAroundEmpty();
    WorkAroundMiddle();

    #100 $stop;
  end

  task automatic WriteData(input int number);
    repeat (number) begin
      @(posedge writeClk);
      #1;
      write = $urandom_range(0, 1);
      if (write) writeData = $urandom;
      else writeData = 0;
    end
    write = 0;
    writeData = 0;
  endtask

  task automatic ReadData(input int number);
    repeat (number) begin
      @(posedge readClk);
      #1;
      read = $urandom_range(0, 1);
    end
    read = 0;
  endtask

  task automatic MakeFifoEmpty;
    while (~empty) begin
      @(posedge readClk);
      #1;
      read = 1;
    end
    read = 0;
  endtask

  task automatic MakeFifoFull;
    while (~full) begin
      @(posedge writeClk);
      #1;
      write = 1;
      writeData = $urandom;
    end
    write = 0;
    writeData = 0;
  endtask

  task automatic MakeFifoHalfFilled;
    while (DUT.head[WIDTH-1:0] < 2 ** (WIDTH - 1)) begin
      @(posedge writeClk);
      #1;
      write = 1;
      writeData = $urandom;
    end
    write = 0;
    writeData = 0;
  endtask

  task automatic WorkAroundFull;
    MakeFifoFull();
    fork
      WriteData($urandom_range(10, 23));
      ReadData($urandom_range(10, 23));
    join
  endtask

  task automatic WorkAroundEmpty;
    MakeFifoEmpty();
    fork
      WriteData($urandom_range(10, 23));
      ReadData($urandom_range(10, 23));
    join
  endtask

  task automatic WorkAroundMiddle;
    MakeFifoEmpty();
    MakeFifoHalfFilled();
    fork
      WriteData($urandom_range(10, 23));
      ReadData($urandom_range(10, 23));
    join
  endtask

endmodule
