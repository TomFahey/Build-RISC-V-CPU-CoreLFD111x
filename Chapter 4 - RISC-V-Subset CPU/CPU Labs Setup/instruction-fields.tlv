 $reset = *reset;
   
   // Program Counter Logic
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 : ($pc + 32'd4);
   
   // Instruction Fetch
   `READONLY_MEM($pc, $$instr[31:0])
   
   // Instruction Decode Logic
   $is_i_instr = $instr[6:2] == 5'b00000 ||
                 $instr[6:2] == 5'b00001 ||
                 $instr[6:2] == 5'b00100 ||
                 $instr[6:2] == 5'b00110 ||
                 $instr[6:2] == 5'b00001 ||
                 $instr[6:2] == 5'b11000;
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_r_instr = $instr[6:2] == 5'b01011 ||
                 $instr[6:2] == 5'b01100 ||
                 $instr[6:2] == 5'b01110 ||
                 $instr[6:2] == 5'b10100;
   $is_b_instr = $instr[6:2] == 5'b11000;
   $is_j_instr = $instr[6:2] == 5'b11011;
   
   $opcode[6:0] = $instr[6:0];
   
   $funct3[2:0] = $instr[14:12];
   $funct7[6:0] = {$instr[31:25], $funct3};
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $rd[4:0] = $instr[11:7];
   
   $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $funct7_valid = $is_r_instr;
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $imm_valid = $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   
   
   
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid ...) 
