/*
 * Copyright (c) 2005-2008, The Android Open Source Project
 * Copyright (c) 2010, Code Aurora Forum. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

    .text
    .global S32A_Opaque_BlitRow32_neon
    .func S32A_Opaque_BlitRow32_neon
S32A_Opaque_BlitRow32_neon:
    push     {r4-r11}
    cmp      r3,#0xff
    bne      .Lto_exit
    cmp      r2,#0
    ble      .Lto_exit
    cmp      r2,#24
    blt      .Lless_than_24

    vpush    {Q4-Q7}

    vmov.i16 q14,#0xff               //;Q4.16 = 255
//prefix
    vld4.8  {d0, d1, d2, d3}, [r1]! //d0,d1,d2,d3 = sourc rgb(0,1,2,3) A(0,1,2,3)
                                    //update source ptr but not dst ptr
    vld4.8  {d4, d5, d6, d7}, [r0]  //d4,d5,d6,d7 = dst rgb(0,1,2,3) A(0,1,2,3)
    add      r3, r0, #32 // minus 16 to pretend the last round
    mov      r5, #64
    sub      r2,r2,#8
.Lloop:
    sub      r2,r2,#16
    vsubw.u8 q4,q14,d3               //Q4.16 = 255-d3
                                    //update source ptr but not dst ptr

    //It has to be 24 since we pre-load 8 word for the next rounds
    cmp      r2,#16

    vsra.u16 q4,q4,#7               //Q4 = Q4.16+Q4 >> 7 ; A(0,1,2,3)

    vmovl.u8 q6,d4                  //Q6 = vmovl.u8 d4
    vmovl.u8 q7,d5                  //Q7 = vmovl.u8 d5
    vmovl.u8 q8,d6                  //Q8 = vmovl.u8 d6
    vmovl.u8 q9,d7                  //Q9 = vmovl.u8 d7


    vmul.i16 q6,q6,q4               //Q6 = Q6 * Q4
    vmul.i16 q7,q7,q4               //Q7 = Q7 * Q4

    vld4.8  {d20, d21, d22, d23}, [r1]! //d0,d1,d2,d3 = sourc rgb(0,1,2,3) A(0,1,2,3)

    vmul.i16 q8,q8,q4               //Q8 = Q8 * Q4
    vmul.i16 q9,q9,q4               //Q9 = Q9 * Q4

    vld4.8  {d24, d25, d26, d27}, [r3]  //d4,d5,d6,d7 = dst rgb(0,1,2,3) A(0,1,2,3)

    vshrn.i16 d4,q6,#8              //d4 = Q6.16 shrn 8
    vshrn.i16 d5,q7,#8              //d5 = Q7.16 shrn 8
    vshrn.i16 d6,q8,#8              //d6 = Q8.16 shrn 8
    vshrn.i16 d7,q9,#8              //d7 = Q9.16 shrn 8

    vadd.i8  d4,d4,d0               //d4 = d4+d0
    vadd.i8  d5,d5,d1               //d5 = d5+d1
    vadd.i8  d6,d6,d2               //d6 = d6+d2
    vadd.i8  d7,d7,d3               //d7 = d7+d3

    vst4.8  {d4, d5, d6, d7}, [r0], r5 //dst rgb(0,1,2,3) A(0,1,2,3) = d4,d5,d6,d7
    //add r0, r0, r5

    //The next 4 words
//    vld4.8  {d20, d21, d22, d23}, [r1]! ;d0,d1,d2,d3 = sourc rgb(0,1,2,3) A(0,1,2,3)
//                                    ;update source ptr but not dst ptr
//    vld4.8  {d24, d25, d26, d27}, [r0]  ;d4,d5,d6,d7 = dst rgb(0,1,2,3) A(0,1,2,3)

                                    //update source ptr but not dst ptr
    vsubW.u8 q4,q14,d23               //Q4.16 = 255-d3

    vsra.u16 q4,q4,#7               //Q4 = Q4.16+Q4 >> 7 ; A(0,1,2,3)

    vmovl.u8 q6,d24                  //Q6 = vmovl.u8 d4
    vmovl.u8 q7,d25                  //Q7 = vmovl.u8 d5
    vmovl.u8 q8,d26                  //Q8 = vmovl.u8 d6
    vmovl.u8 q9,d27                  //Q9 = vmovl.u8 d7

    vmul.i16 q6,q6,q4               //Q6 = Q6 * Q4
    vmul.i16 q7,q7,q4               //Q7 = Q7 * Q4

    vld4.8  {d0, d1, d2, d3}, [r1]! //d0,d1,d2,d3 = sourc rgb(0,1,2,3) A(0,1,2,3)

    vmul.i16 q8,q8,q4               //Q8 = Q8 * Q4
    vmul.i16 q9,q9,q4               //Q9 = Q9 * Q4

    vld4.8  {d4, d5, d6, d7}, [r0]  //d4,d5,d6,d7 = dst rgb(0,1,2,3) A(0,1,2,3)
    vshrn.i16 d24,q6,#8              //d4 = Q6.16 shrn 8
    vshrn.i16 d25,q7,#8              //d5 = Q7.16 shrn 8
    vshrn.i16 d26,q8,#8              //d6 = Q8.16 shrn 8
    vshrn.i16 d27,q9,#8              //d7 = Q9.16 shrn 8

    vadd.i8  d24,d24,d20               //d4 = d4+d0
    vadd.i8  d25,d25,d21               //d5 = d5+d1
    vadd.i8  d26,d26,d22               //d6 = d6+d2
    vadd.i8  d27,d27,d23               //d7 = d7+d3

    vst4.8  {d24, d25, d26, d27}, [r3], r5 //dst rgb(0,1,2,3) A(0,1,2,3) = d4,d5,d6,d7
    //add r3, r3, r5

    bge      .Lloop

//postfix:
//There are 8 words left unprocessed from previous round
    vmov.i16 q4,#0xff               //Q4.16 = 255
    vsubw.u8 q4,q4,d3               //Q4.16 = 255-d3

    cmp      r2,#8

    vshr.u16 q5,q4,#7               //Q5.16 = Q4 >> 7
    vadd.i16 q4,q4,q5               //Q4 = Q4.16+Q5.16 ; A(0,1,2,3)

    vmovl.u8 q6,d4                  //Q6 = vmovl.u8 d4
    vmovl.u8 q7,d5                  //Q7 = vmovl.u8 d5
    vmovl.u8 q8,d6                  //Q8 = vmovl.u8 d6
    vmovl.u8 q9,d7                  //Q9 = vmovl.u8 d7

    vmul.i16 q6,q6,q4               //Q6 = Q6 * Q4
    vmul.i16 q7,q7,q4               //Q7 = Q7 * Q4
    vmul.i16 q8,q8,q4               //Q8 = Q8 * Q4
    vmul.i16 q9,q9,q4               //Q9 = Q9 * Q4

    vshrn.i16 d4,q6,#8              //d4 = Q6.16 shrn 8
    vshrn.i16 d5,q7,#8              //d5 = Q7.16 shrn 8
    vshrn.i16 d6,q8,#8              //d6 = Q8.16 shrn 8
    vshrn.i16 d7,q9,#8              //d7 = Q9.16 shrn 8

    vadd.i8  d4,d4,d0               //d4 = d4+d0
    vadd.i8  d5,d5,d1               //d5 = d5+d1
    vadd.i8  d6,d6,d2               //d6 = d6+d2
    vadd.i8  d7,d7,d3               //d7 = d7+d3

    vst4.8  {d4, d5, d6, d7}, [r0]! //dst rgb(0,1,2,3) A(0,1,2,3) = d4,d5,d6,d7

.Lless_than_16:
    cmp      r2,#8
    blt      .Lless_than_8

    sub      r2,r2,#8

    vld4.8  {d0, d1, d2, d3}, [r1]! //d0,d1,d2,d3 = sourc rgb(0,1,2,3) A(0,1,2,3)
                                    //update source ptr but not dst ptr
    vld4.8  {d4, d5, d6, d7}, [r0]  //d4,d5,d6,d7 = dst rgb(0,1,2,3) A(0,1,2,3)

    vmov.i16 q4,#0xff               //Q4.16 = 255
    vsubw.u8 q4,q4,d3               //Q4.16 = 255-d3

    cmp      r2,#8

    vshr.u16 q5,q4,#7               //Q5.16 = Q4 >> 7
    vadd.i16 q4,q4,q5               //Q4 = Q4.16+Q5.16 ; A(0,1,2,3)

    vmovl.u8 q6,d4                  //Q6 = vmovl.u8 d4
    vmovl.u8 q7,d5                  //Q7 = vmovl.u8 d5
    vmovl.u8 q8,d6                  //Q8 = vmovl.u8 d6
    vmovl.u8 q9,d7                  //Q9 = vmovl.u8 d7

    vmul.i16 q6,q6,q4               //Q6 = Q6 * Q4
    vmul.i16 q7,q7,q4               //Q7 = Q7 * Q4
    vmul.i16 q8,q8,q4               //Q8 = Q8 * Q4
    vmul.i16 q9,q9,q4               //Q9 = Q9 * Q4

    vshrn.i16 d4,q6,#8              //d4 = Q6.16 shrn 8
    vshrn.i16 d5,q7,#8              //d5 = Q7.16 shrn 8
    vshrn.i16 d6,q8,#8              //d6 = Q8.16 shrn 8
    vshrn.i16 d7,q9,#8              //d7 = Q9.16 shrn 8

    vadd.i8  d4,d4,d0               //d4 = d4+d0
    vadd.i8  d5,d5,d1               //d5 = d5+d1
    vadd.i8  d6,d6,d2               //d6 = d6+d2
    vadd.i8  d7,d7,d3               //d7 = d7+d3

    vst4.8  {d4, d5, d6, d7}, [r0]! //dst rgb(0,1,2,3) A(0,1,2,3) = d4,d5,d6,d7

    //It will be guaranteed to be less than 8
    //bge      loop
.Lless_than_8:
    vpop     {Q4-Q7}

.Lless_than_4:
    subs     r4,r2,#1
    bmi      .Lto_exit  // S32A_Opaque_BlitRow32_neon + 268
    mov      r8,#0xff
    mvn      r10,#0xff00
    orr      r9,r8,r8,lsl #16
    lsl      r11,r9,#8
.Lresidual_loop:
    ldr      r3,[r1,#0]
    ldr      r12,[r0,#0]
    add      r1,r1,#4
    sub      r2,r8,r3,lsr #24
    and      r5,r12,r9
    cmp      r2,r2
    add      r2,r2,#1
    and      r12,r10,r12,lsr #8
    strne    r6,[r7,#0xeef]
    mul      r5,r5,r2
    mul      r2,r12,r2
    strne    r6,[r7,#0xeef]
    subs     r4,r4,#1
    and      r12,r9,r5,lsr #8
    and      r2,r2,r11
    orr      r2,r2,r12
    add      r2,r2,r3
    str      r2,[r0],#4
    bpl      .Lresidual_loop  // S32A_Opaque_BlitRow32_neon + 192

.Lto_exit:
    pop      {r4-r11}
    bx       lr

.Lless_than_24:
    cmp      r2,#8
    blt      .Lless_than_4

.Lloop_8:
    sub      r2,r2,#8
    // We already read the 8 words from the previous pipe line
    vld4.8  {d0, d1, d2, d3}, [r1]! //d0,d1,d2,d3 = sourc rgb(0,1,2,3) A(0,1,2,3)
                                    //update source ptr but not dst ptr
    vld4.8  {d4, d5, d6, d7}, [r0]  //d4,d5,d6,d7 = dst rgb(0,1,2,3) A(0,1,2,3)

    vmov.i16 q10,#0xff               //Q4.16 = 255
    vsubW.u8 q10,q10,d3               //Q4.16 = 255-d3

    cmp      r2,#8

    vshr.u16 q11,q10,#7               //Q5.16 = Q4 >> 7
    vadd.i16 q10,q10,q11               //Q4 = Q4.16+Q5.16 ; A(0,1,2,3)

    vmovl.u8 q12,d4                  //Q6 = vmovl.u8 d4
    vmovl.u8 q13,d5                  //Q7 = vmovl.u8 d5
    vmovl.u8 q8,d6                  //Q8 = vmovl.u8 d6
    vmovl.u8 q9,d7                  //Q9 = vmovl.u8 d7

    vmul.i16 q12,q12,q10               //Q6 = Q6 * Q4
    vmul.i16 q13,q13,q10               //Q7 = Q7 * Q4
    vmul.i16 q8,q8,q10               //Q8 = Q8 * Q4
    vmul.i16 q9,q9,q10               //Q9 = Q9 * Q4

    vshrn.i16 d4,q12,#8              //d4 = Q6.16 shrn 8
    vshrn.i16 d5,q13,#8              //d5 = Q7.16 shrn 8
    vshrn.i16 d6,q8,#8              //d6 = Q8.16 shrn 8
    vshrn.i16 d7,q9,#8              //d7 = Q9.16 shrn 8

    vadd.i8  d4,d4,d0               //d4 = d4+d0
    vadd.i8  d5,d5,d1               //d5 = d5+d1
    vadd.i8  d6,d6,d2               //d6 = d6+d2
    vadd.i8  d7,d7,d3               //d7 = d7+d3

    vst4.8  {d4, d5, d6, d7}, [r0]! //dst rgb(0,1,2,3) A(0,1,2,3) = d4,d5,d6,d7

    bge      .Lloop_8
    b        .Lless_than_4
.endfunc
.size S32A_Opaque_BlitRow32_neon, .-S32A_Opaque_BlitRow32_neon






