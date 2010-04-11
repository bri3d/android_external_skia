/*
 * Copyright 2006, The Android Open Source Project
 * Copyright (c) 2009, Code Aurora Forum.
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
	.align

	.global xfer16_arm

.macro pixel,   DREG, SRC, FB, OFFSET
    lsl    r6, \SRC, #8
    lsr    r8, \SRC, #5
    and    r7, r6, #0xf800
    and    r8, r8, #0x7e0
    orr    r8, r8, r7

.if \OFFSET
    orr    r8, r8, r6, lsr #27
    orr    \FB, \FB, r8, lsl #(\OFFSET)
.else
    orr    \FB, r8, r6, lsr #27
.endif

.endm

xfer16_arm:
    stmfd   sp!, {r4-r8}

#if __ARM_ARCH__ == 7 || defined(__ARM_NEON__)
    subs    r2, r2, #16

    blo     xfer16_less_than_16_left

    vmov.u16 q12,  #0x80
    //pld     [r1]
    //pld     [r1, #32]

xfer16_neon_loop:
    // load 64 bytes from source and 32 bytes from destination
    // note that source pixels are 4 bytes wide and
    // destination pixels are 2 bytes wide
    vld4.8  {d2, d4, d6, d8}, [r1]!
    vld4.8  {d3, d5, d7, d9}, [r1]!

    vshl.u8   q0, q2, #3

    subs    r2, r2, #16

    vsri.u8   q1, q2, #5
    vsri.u8   q0, q3, #3

    // store the rgb destination values back to memory
    vst2.8  {d0, d2}, [r0]!
    vst2.8  {d1, d3}, [r0]!

    blo     xfer16_less_than_16_left
    b       xfer16_neon_loop
#endif

xfer16_less_than_16_left:
    pld     [r1]

#if __ARM_ARCH__ == 7 || defined(__ARM_NEON__)
    adds    r2, r2, #14
#else
    subs    r2, r2, #2
#endif

    pld     [r0]
    blo     9f

    // The main loop is unrolled thrice and process 6 pixels
8:  ldmia   r1!, {r4, r5}
    // stream the source
    pld     [r1, #32]
    add     r0, r0, #4

    // load the destination
    ldr     r3, [r0, #-4]
    // stream the destination
    pld     [r0, #32]
    pixel   r3, r4, r12, 0
    pixel   r3, r5, r12, 16
    // effectively, we're getting write-combining by virtue of the
    // cpu's write-back cache.
    str     r12, [r0, #-4]

    // 2nd iteration of the loop, don't stream anything
    subs    r2, r2, #2
    blt     9f
    ldmia   r1!, {r4, r5}
    add     r0, r0, #4
    ldr     r3, [r0, #-4]
    pixel   r3, r4, r12, 0
    pixel   r3, r5, r12, 16
    str     r12, [r0, #-4]

    // 3rd iteration of the loop, don't stream anything
    subs    r2, r2, #2
    blt     9f
    ldmia   r1!, {r4, r5}
    add     r0, r0, #4
    ldr     r3, [r0, #-4]
    pixel   r3, r4, r12, 0
    pixel   r3, r5, r12, 16
    str     r12, [r0, #-4]

7:  subs    r2, r2, #2
    blo     9f
    b       8b

9:  adds    r2, r2, #1
    ldmlofd sp!, {r4-r8}        // return
    bxlo    lr

    // last pixel left
    ldr     r4, [r1], #4
    ldrh    r3, [r0]
    pixel   r3, r4, r12, 0
    strh    r12, [r0], #2
    ldmfd   sp!, {r4-r8}        // return
    bx      lr
