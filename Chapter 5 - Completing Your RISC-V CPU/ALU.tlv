   
   $reset = *reset;
   
   // Program Counter Logic
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 : 
      $taken_br ? $br_tgt_pc :
      ($pc + 32'd4);
   
   // Instruction Fetch
   `READONLY_MEM($pc, $$instr[31:0])
   
   // Instruction Decode Logic
   
   // Identify instruction type
   $is_i_instr = $instr[6:2] ==? 5'b00000 ||
                 $instr[6:2] ==? 5'b00001 ||
                 $instr[6:2] ==? 5'b00100 ||
                 $instr[6:2] ==? 5'b00110 ||
                 $instr[6:2] ==? 5'b11001;
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_r_instr = $instr[6:2] ==? 5'b01011 ||
                 $instr[6:2] ==? 5'b01100 ||
                 $instr[6:2] ==? 5'b01110 ||
                 $instr[6:2] ==? 5'b10100;
   $is_b_instr = $instr[6:2] ==? 5'b11000;
   $is_j_instr = $instr[6:2] ==? 5'b11011;
   
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
   //$rd_valid = ($rd >= 5'b0) ? ($is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr) :
   //                             0;
   $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   
   // 10-bit instruction specifier
   $dec_bits[10:0] = {$instr[30],$funct3, $opcode};
   
   // Decode specific instruction
   $is_lui   = $dec_bits ==? 11'bx_xxx_0110111;   // Load Upper Immediate
   $is_auipc = $dec_bits ==? 11'bx_xxx_0010111;   // Add Upper Immediate to PC
   $is_jal   = $dec_bits ==? 11'bx_xxx_1101111;   // Jump & Link
   $is_jalr  = $dec_bits ==? 11'bx_000_1100111;   // Jump & Link Register
   $is_beq   = $dec_bits ==? 11'bx_000_1100011;   // Branch if Equal
   $is_bne   = $dec_bits ==? 11'bx_001_1100011;   // Branch if Not Equal
   $is_blt   = $dec_bits ==? 11'bx_100_1100011;   // Branch if Less Than
   $is_bge   = $dec_bits ==? 11'bx_101_1100011;   // Branch if Greater Than or Equal
   $is_bltu  = $dec_bits ==? 11'bx_110_1100011;   // Branch if Less Than, Unsigned
   $is_bgeu  = $dec_bits ==? 11'bx_111_1100011;   // Branch if Greater Than or Equal, Unsigned
   // $is_lb    = $dec_bits ==? 11'bx_000_0000011;   // Load Byte
   // $is_lh    = $dec_bits ==? 11'bx_001_0000011;   // Load Halfword
   // $is_lw    = $dec_bits ==? 11'bx_010_0000011;   // Load Word
   // $is_lbu   = $dec_bits ==? 11'bx_100_0000011;   // Load Byte, Unsigned
   // $is_lhu   = $dec_bits ==? 11'bx_101_0000011;   // Load Halfword, Unsigned
   // $is_sb    = $dec_bits ==? 11'bx_000_0100011;   // Store Byte
   // $is_sh    = $dec_bits ==? 11'bx_001_0100011;   // Store Halfword
   // $is_sw    = $dec_bits ==? 11'bx_010_0100011;   // Store Word
   $is_addi  = $dec_bits ==? 11'bx_000_0010011;   // Add immediate
   $is_slti  = $dec_bits ==? 11'bx_010_0010011;   // Set Less Than Immediate
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;   // Set < Immediate, Unsigned
   $is_xori  = $dec_bits ==? 11'bx_100_0010011;   // Logical XOR Immediate
   $is_ori   = $dec_bits ==? 11'bx_110_0010011;   // Logical OR Immediate
   $is_andi  = $dec_bits ==? 11'bx_111_0010011;   // Logical AND Immediate
   $is_slli  = $dec_bits ==? 11'b0_001_0010011;   // Logical Shift Left Immediate
   $is_srli  = $dec_bits ==? 11'b0_101_0010011;   // Logical Shift Right Immediate
   $is_srai  = $dec_bits ==? 11'b1_101_0010011;   // Arithmetic Shift Right Immediate
   $is_add   = $dec_bits ==? 11'b0_000_0110011;   // Add
   $is_sub   = $dec_bits ==? 11'b1_000_0110011;   // Subtract
   $is_sll   = $dec_bits ==? 11'b0_001_0110011;   // Logical Shift Left
   $is_slt   = $dec_bits ==? 11'b0_010_0110011;   // Set Less Than
   $is_sltu  = $dec_bits ==? 11'b0_011_0110011;   // Set Less Than, Unsigned
   $is_xor   = $dec_bits ==? 11'b0_100_0110011;   // Logical XOR
   $is_srl   = $dec_bits ==? 11'b0_101_0110011;   // Logical Shift Right
   $is_sra   = $dec_bits ==? 11'b1_101_0110011;   // Arithmetic Shift Right
   $is_or    = $dec_bits ==? 11'b0_110_0110011;   // Logical OR
   $is_and   = $dec_bits ==? 11'b0_111_0110011;   // Logical AND
   
 
   // +----------------------------------------------------------------------------------------------------
   // ALU
   
   // SLTU and SLTI (set if less than, unsigned) results:
   $sltu_rslt[31:0] = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   // SRA and SRAI (shift right, arithmetic) results:
   // sign-extended src1
   $sext_src1[63:0] = { {32{$src1_value[31]}}, $src1_value };
   // 64-bit sign-extended results, to be truncated
   $sra_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   
   $result[31:0] =
      $is_add   ? $src1_value + $src2_value       :
      $is_addi  ? $src1_value + $imm              :
      $is_and   ? $src1_value & $src2_value       :
      $is_andi  ? $src1_value & $imm              :
      $is_auipc ? $pc + $imm                      :
      $is_jal   ? $pc + 32'd4                     :
      $is_jalr  ? $pc + 32'd4                     :
      $is_lui   ? {$imm[31:12], 12'b0}            :
      $is_or    ? $src1_value | $src2_value       :
      $is_ori   ? $src1_value | $imm              :
      $is_sll   ? $src1_value << $src2_value[4:0] :
      $is_slli  ? $src1_value << $imm[5:0]        :
      $is_slt   ? ( ($src1_value[31] == $src2_value[31]) ? $sltu_rslt : {31'b0, $src1_value[31]} ) :
      $is_slti  ? ( ($src1_value[31] == $imm[31]) ? $sltiu_rslt : {31'b0, $src1_value[31]} ) :
      $is_sltu  ? $sltu_rslt                      :
      $is_sltiu ? $sltiu_rslt                     :
      $is_sra   ? $sra_rslt[31:0]                 :
      $is_srai  ? $srai_rslt[31:0]                :
      $is_srl   ? $src1_value >> $src2_value[4:0] :
      $is_srli  ? $src1_value >> $imm[5:0]        :
      $is_sub   ? $src1_value - $src2_value       :
      $is_xor   ? $src1_value ^ $src2_value       :
      $is_xori  ? $src1_value ^ $imm              :
      32'b0;
   // -----------------------------------------------------------------------------------------------------
     
   // +----------------------------------------------------------------------------------------------------
   // Branch Logic
   $taken_br = $is_b_instr ? 
      $is_beq ? $src1_value == $src2_value :
      $is_bne ? $src1_value != $src2_value :
      $is_blt ? ( ($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) ) :
      $is_bge ? ( ($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]) ) :
      $is_bltu ? $src1_value < $src2_value :
      $is_bgeu ? $src1_value >= $src2_value :
      0 : 0;
      
   $br_tgt_pc[31:0] = $pc + $imm;
   // -----------------------------------------------------------------------------------------------------
   
   // +----------------------------------------------------------------------------------------------------
   // Load and Store Logic
   // $is_load = $is_lb || $is_lh || $is_lw || $is_lbu || $is_lhu;
   // -----------------------------------------------------------------------------------------------------
   
   `BOGUS_USE($funct3_valid $funct7 $funct7_valid) 
   
   // Assert these to end simulation (before Makerchip cycle limit).
   // *passed = 1'b0;
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $rd_valid, $rd, $result, $rs1_valid, $rs1, $src1_value, $rs2_valid, $rs2, $src2_value)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
