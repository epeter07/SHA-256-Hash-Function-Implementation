//----------------------------------------------------------------------------------------------------
// To run simulation
//
// vlog -sv ece564_project_tb_top.v
// vsim -c -do "run 1us; quit" tb_top
//
// you can display the expected intermediate and output results by adding defines to vlog
// vlog -sv +define+TB_DISPLAY_INTERMEDIATE+TB_DISPLAY_EXPECTED ece564_project_tb_top.v
//
//
// ECE464 and EOL students
//`define ECE464
// All students
// - set based on your message memory depth
`define MSG_LENGTH 5

// synopsys translate_off
/*
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_fp_cmp.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_fp_cmp_DG.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_fp_mult.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_fp_mac.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_fp_dp2.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_fp_ifp_conv.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_ifp_fp_conv.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_ifp_mult.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW_ifp_addsub.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW02_mult_5_stage.v"
`include "/afs/eos.ncsu.edu/dist/synopsys2013/syn/dw/sim_ver/DW01_addsub.v"
*/

//synopsys translate_on
//
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// Tesbench
// - instantiate the DUT and testbench

module tb_top ();


  parameter CLK_PHASE=12.5  ;
  `ifdef ECE464
  parameter OUTPUT_LENGTH       = 16 ;
  `else
  parameter OUTPUT_LENGTH       = 8 ;
  `endif
  parameter MAX_MESSAGE_LENGTH  = 55;
  parameter NUMBER_OF_Ks        = 64;
  parameter NUMBER_OF_Hs        = 8 ;
  parameter SYMBOL_WIDTH        = 8 ;
 
  //---------------------------------------------------------------------------
  // General
  //
  reg                                   clk                  ;
  reg                                   reset                ;
  reg                                   xxx__dut__go         ;
  reg   [ $clog2(MAX_MESSAGE_LENGTH):0] xxx__dut__msg_length ;
  wire                                  dut__xxx__finish     ;

  integer runId ;
  integer numberOfClocks ;
  integer totalNumberOfClocks ;
  integer compareNumberOfClocks ;
  // compare files
  reg [31:0] comparisonMem [OUTPUT_LENGTH-1:0];
  reg [31:0] resultMem [OUTPUT_LENGTH-1:0];

  bit dutRunning, waitForFinishLow;
  bit errorObserved ;
  string outputType;

  initial begin
      `ifdef ECE464
      outputType = "M_1";
      `else
      outputType = "Hash";
      `endif
    end


  wire [ $clog2(MAX_MESSAGE_LENGTH)-1:0]   dut__msg__address  ;  // address of letter
  wire                                     dut__msg__enable   ;
  wire                                     dut__msg__write    ;
  wire [7:0]                               msg__dut__data     ;  // read each letter
                                          
  wire [ $clog2(NUMBER_OF_Ks)-1:0]         dut__kmem__address  ;
  wire                                     dut__kmem__enable   ;
  wire                                     dut__kmem__write    ;
  wire [31:0]                              kmem__dut__data     ;  // read data
                                          
  wire [ $clog2(NUMBER_OF_Hs )-1:0]        dut__hmem__address  ;
  wire                                     dut__hmem__enable   ;
  wire                                     dut__hmem__write    ;
  wire [31:0]                              hmem__dut__data     ;  // read data
                                          
  wire [ $clog2(OUTPUT_LENGTH)-1:0]        dut__dom__address  ;
  wire [31:0]                              dut__dom__data     ;  // write data
  wire                                     dut__dom__enable   ;
  wire                                     dut__dom__write    ;

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  
  sram  #(.ADDR_WIDTH    ($clog2(MAX_MESSAGE_LENGTH)),
          .DATA_WIDTH    (SYMBOL_WIDTH              ),
          .MEM_INIT_FILE ("message.dat"             ))
         msg_mem  (
          .address      ( dut__msg__address  ),
          .write_data   ( {SYMBOL_WIDTH {1'b0}}), 
          .read_data    ( msg__dut__data     ), 
          .enable       ( dut__msg__enable   ),
          .write        ( dut__msg__write    ),
          .clock        ( clk                )
         );

  sram  #(.ADDR_WIDTH    ( $clog2(NUMBER_OF_Ks)),
          .DATA_WIDTH    (32),
          .MEM_INIT_FILE ("K.dat"         ))
          kmem_mem (

          .address     ( dut__kmem__address  ),
          .write_data  ( 'd0                 ), 
          .read_data   ( kmem__dut__data     ), 
          .enable      ( dut__kmem__enable   ),
          .write       ( dut__kmem__write    ),

          .clock       ( clk                 )
         );

  sram  #(.ADDR_WIDTH    ( $clog2(NUMBER_OF_Hs )),
          .DATA_WIDTH    (32),
          .MEM_INIT_FILE ("H.dat"         ))
          hmem_mem (

          .address     ( dut__hmem__address  ),
          .write_data  ( 'd0                 ), 
          .read_data   ( hmem__dut__data     ), 
          .enable      ( dut__hmem__enable   ),
          .write       ( dut__hmem__write    ),

          .clock       ( clk                 )
         );

  sram  #(.ADDR_WIDTH  ($clog2(OUTPUT_LENGTH)),
          .DATA_WIDTH  (32))
         dom_mem  (

          .address     ( dut__dom__address  ),
          .write_data  ( dut__dom__data     ), 
          .read_data   (                    ),
          .enable      ( dut__dom__enable   ),
          .write       ( dut__dom__write    ),

          .clock       ( clk                )
         );


  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //------------------------------
  // Testbench
  //

  //---------------------------------------------------------------------------
  //  clk
  initial 
    begin
        clk                     = 1'b0;
        forever # CLK_PHASE clk = ~clk;
    end
  
  initial 
    begin
        errorObserved = 0;
        dutRunning = 0;
        waitForFinishLow = 1;
        totalNumberOfClocks = 0;
        repeat(10) @(posedge clk);
        reset = 0;
        xxx__dut__go = 0;
        repeat(10) @(posedge clk);
        reset = 1;
        repeat(10) @(posedge clk);
        reset = 0;
        xxx__dut__msg_length = 1;
        msg_mem.memFile = $sformatf("message1.dat");
        ->msg_mem.loadMemory;
        repeat(5) @(posedge clk);
        xxx__dut__go = 1;
        repeat(1) @(posedge clk);
        xxx__dut__go = 0;
        wait(!dut__xxx__finish);
        wait(dut__xxx__finish);
        repeat(1) @(posedge clk);
        totalNumberOfClocks = totalNumberOfClocks + numberOfClocks;

        msg_mem.memFile = $sformatf("message27.dat");
        ->msg_mem.loadMemory;
        xxx__dut__msg_length = 27;
        repeat(5) @(posedge clk);
        xxx__dut__go = 1;
        repeat(1) @(posedge clk);
        xxx__dut__go = 0;
        wait(!dut__xxx__finish);
        wait(dut__xxx__finish);
        repeat(1) @(posedge clk);
        totalNumberOfClocks = totalNumberOfClocks + numberOfClocks;

        msg_mem.memFile = $sformatf("message55.dat");
        ->msg_mem.loadMemory;
        xxx__dut__msg_length = 55;
        repeat(5) @(posedge clk);
        xxx__dut__go = 1;
        repeat(1) @(posedge clk);
        xxx__dut__go = 0;
        wait(!dut__xxx__finish);
        wait(dut__xxx__finish);
        repeat(1) @(posedge clk);
        totalNumberOfClocks = totalNumberOfClocks + numberOfClocks;

        repeat(100) @(posedge clk);

        reset = 1;
        repeat(10) @(posedge clk);
        reset = 0;
        repeat(10) @(posedge clk);
        xxx__dut__go = 1;
        repeat(1) @(posedge clk);
        xxx__dut__go = 0;
        wait(!dut__xxx__finish);
        wait(dut__xxx__finish);
        compareNumberOfClocks = numberOfClocks;

        repeat(100) @(posedge clk);

        reset = 1;
        repeat(10) @(posedge clk);
        reset = 0;
        repeat(10) @(posedge clk);
        xxx__dut__go = 1;
        repeat(1) @(posedge clk);
        xxx__dut__go = 0;
        wait(!dut__xxx__finish);

        // message length of 55 ensures time should be >= 55
        // generate an additional go after 30 cycles
        repeat(30) @(posedge clk);
        $display("@%00t, Extra go during processing", $time);
        xxx__dut__go = 1;
        repeat(2) @(posedge clk);
        xxx__dut__go = 0;

        wait(dut__xxx__finish);

        repeat(100) @(posedge clk);

        // make sure extra go doesnt change behavior
        if (compareNumberOfClocks != numberOfClocks) begin
          $display("@%00t, ERROR:Extra go caused change in number of clocks : expected %0d, got %0d", $time, compareNumberOfClocks, numberOfClocks);
          errorObserved = 1;
        end
        else begin
          $display("@%00t, Extra go didnt change behavior", $time);
        end

        repeat(100) @(posedge clk);

        $readmemh("result_0.txt", resultMem);
        `ifdef ECE464
        $readmemh("message1_result_ece464.txt", comparisonMem);
        `else
        $readmemh("message1_result.txt", comparisonMem);
        `endif
        for (int i=0; i<OUTPUT_LENGTH; i=i+1) begin
          if (comparisonMem[i] != resultMem[i]) begin
            $display("@%00t, ERROR:Message length 1, result content mismatch at address %0h, expected %8h, got %8h", $time, i, comparisonMem[i], resultMem[i]);
            errorObserved = 1;
          end
        end

        $readmemh("result_1.txt", resultMem);
        `ifdef ECE464
        $readmemh("message27_result_ece464.txt", comparisonMem);
        `else
        $readmemh("message27_result.txt", comparisonMem);
        `endif
        for (int i=0; i<OUTPUT_LENGTH; i=i+1) begin
          if (comparisonMem[i] != resultMem[i]) begin
            $display("@%00t, ERROR:Message length 27, result content mismatch at address %0h, expected %8h, got %8h", $time, i, comparisonMem[i], resultMem[i]);
            errorObserved = 1;
          end
        end

        $readmemh("result_2.txt", resultMem);
        `ifdef ECE464
        $readmemh("message55_result_ece464.txt", comparisonMem);
        `else
        $readmemh("message55_result.txt", comparisonMem);
        `endif
        for (int i=0; i<OUTPUT_LENGTH; i=i+1) begin
          if (comparisonMem[i] != resultMem[i]) begin
            $display("@%00t, ERROR:Message length 55, result content mismatch at address %0h, expected %8h, got %8h", $time, i, comparisonMem[i], resultMem[i]);
            errorObserved = 1;
          end
        end

        $display("@%00t, INFO:The total number of clocks for reporting is %0d", $time, totalNumberOfClocks );

        if (errorObserved) begin
          $display("*****************");
          $display("***** ERROR *****");
          $display("*****************");
        end

        $finish;
    end

  always 
    begin
      @(posedge clk);
      if ((xxx__dut__go == 1'b1) && ~dutRunning)
        begin
          $display("@%0t, go asserted", $time);
          numberOfClocks = 0;
          dutRunning = 1;
        end
      else if ((dut__xxx__finish == 1'b0) && waitForFinishLow)
        begin
          waitForFinishLow = 0;
          numberOfClocks = numberOfClocks + 1;
        end
      else if ((dut__xxx__finish == 1'b1) && ~waitForFinishLow && dutRunning)
        begin
          $display("@%00t, dut finished, # of clocks = %0d", $time, numberOfClocks);
          dutRunning = 0;
          waitForFinishLow = 1;
        end
      else if (dutRunning)
        begin
          numberOfClocks = numberOfClocks + 1;
        end
    end


  always 
    begin
      @(posedge clk);
      if (dut__dom__enable == 1'b1)
        begin
          $display("%s[%0d] = %h", outputType, dut__dom__address, dut__dom__data);
        end
    end

  initial begin
      runId = 0;
    end

  always 
    begin
      @(posedge clk);
      if (dut__xxx__finish == 1'b1)
        begin
          $display("Store result to result_%0d.txt", runId);
          $writememh($sformatf("result_%0d.txt", runId),dom_mem.mem);
          runId = runId+1;
        end
      wait (dut__xxx__finish == 1'b0);

    end


  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  // Stimulus

  //---------------------------------------------------------------------------



//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
// DUT 
  MyDesign #(.OUTPUT_LENGTH      (OUTPUT_LENGTH     ),
             .MAX_MESSAGE_LENGTH (MAX_MESSAGE_LENGTH),
             .NUMBER_OF_Ks       (NUMBER_OF_Ks      ),
             .NUMBER_OF_Hs       (NUMBER_OF_Hs      ),
             .SYMBOL_WIDTH       (SYMBOL_WIDTH      ))

            dut(

          .xxx__dut__msg_length ( xxx__dut__msg_length ),  
          .dut__xxx__finish     ( dut__xxx__finish     ),
          .xxx__dut__go         ( xxx__dut__go         ),  
          .dut__msg__address    ( dut__msg__address    ),
          .msg__dut__data       ( msg__dut__data       ), 
          .dut__msg__enable     ( dut__msg__enable     ),
          .dut__msg__write      ( dut__msg__write      ),
                                                       
          .dut__kmem__address   ( dut__kmem__address   ),
          .kmem__dut__data      ( kmem__dut__data      ), 
          .dut__kmem__enable    ( dut__kmem__enable    ),
          .dut__kmem__write     ( dut__kmem__write     ),
                                                       
          .dut__hmem__address   ( dut__hmem__address   ),
          .hmem__dut__data      ( hmem__dut__data      ), 
          .dut__hmem__enable    ( dut__hmem__enable    ),
          .dut__hmem__write     ( dut__hmem__write     ),
                                                       
          .dut__dom__address    ( dut__dom__address    ),
          .dut__dom__data       ( dut__dom__data       ), 
          .dut__dom__enable     ( dut__dom__enable     ),
          .dut__dom__write      ( dut__dom__write      ),
                                                       
          .reset                ( reset                ),  
          .clk                  ( clk                  )
         );



endmodule

