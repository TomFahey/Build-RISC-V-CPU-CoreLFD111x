   $reset = *reset;
   
   // Program Counter Logic
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 : ($pc + 32'd4);
   
   // Instruction Fetch
   `READONLY_MEM($pc, $$instr[31:0])
   
   // Instruction Decode Logic
   
   // Identify instruction type
   $is_i_instr = $instr[6:2] == 5'b00000 ||
                 $instr[6:2] == 5'b00001 ||
                 $instr[6:2] == 5'b00100 ||
                 $instr[6:2] == 5'b00110 ||
                 $instr[6:2] == 5'b11001;
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_r_instr = $instr[6:2] == 5'b01011 ||
                 $instr[6:2] == 5'b01100 ||
                 $instr[6:2] == 5'b01110 ||
                 $instr[6:2] == 5'b10100;
   $is_b_instr = $instr[6:2] == 5'b11000;
   $is_j_instr = $instr[6:2] == 5'b11011;
   
   // Decode instruction parameters
   $opcode[6:0] = $instr[6:0];
   $funct3[2:0] = $instr[14:12];
   $funct7[6:0] = {$instr[31:25], $funct3};
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $rd[4:0] = $instr[11:7];
   
   // Decode instruction immediate value
   $imm[31:0] = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :
                $is_s_instr ? { {21{$instr[31]}}, $instr[30:25], $instr[11:8], $instr[7] } :
                $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'd0 } :
                $is_u_instr ? { $instr[31], $instr[30:20], $instr[19:12], 12'd0 } :
                $is_j_instr ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:25], $instr[24:21], 1'd0} :
                              32'b0; // Default
   
   // Evaluate instruction parameter validity
   $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $funct7_valid = $is_r_instr;
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $imm_valid = $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   
   // 10-bit instruction specifier
   $dec_bits[10:0] = {$instr[30],$funct3, $opcode};
   
   // Decode specific instruction
   $is_beq = $dec_bits ==? 11'bx_000_1100011;   // Branch if Equal
   $is_bne = $dec_bits ==? 11'bx_001_1100011;   // Branch if Not Equal
   $is_blt = $dec_bits ==? 11'bx_100_1100011;   // Branch if Less Than
   $is_bge = $dec_bits ==? 11'bx_101_1100011;   // Branch if Greater Than
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;  // Branch if Less Than or Equal
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;  // Branch if Greater Than or Equal
   $is_addi = $dec_bits ==? 11'bx_000_0010011;  // Add immediate
   $is_add = $dec_bits ==? 11'b0_000_0110011;   // Add
   
   
   
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid 
      $funct3 $funct3_valid $funct7 $funct7_valid $is_beq
      $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi
      $is_add $imm) 
