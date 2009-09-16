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


/*
 * This file is derived from libpixelflinger version of BLIT routine.
 * Algorithm used for BLIT operation here is equivalent to the one in
 * C function, S32A_D565_Opaque. This asm routine combines two 16-bit writes
 * into one 32-bit write to destination, uses destination and source pre-loads,
 * and unrolls the main loop thrice. These changes contribute to an additional
 * 2 FPS improvement (measured from launcher open/close usecase) over the
 * s32a_d565_opaque_arm ASM routine.
 */
	.text
	.align

	.global scanline_t32cb16blend_arm

// uses r6, r7, r8, r9, r10, lr

.macro pixel,   DREG, SRC, FB, OFFSET

    // SRC = AABBGGRR
    subs   r7, r10, \SRC, lsr #24           // sAA = 255 - sAA
    beq    1f

.if \OFFSET

    // red
    mov     lr, \DREG, lsr #(\OFFSET + 6 + 5)
    smlabb  lr, r7, lr, r8
    add     lr, lr, lr, lsr #5
    and     r6, \SRC, r10
    add     lr, r6, lr, lsr #5
    lsr     lr, #3
    orr     \FB, lr, lsl #(\OFFSET + 11)

        // green
        and     r6, \DREG, #(0x3F<<(\OFFSET + 5))
        lsr     r6, #5
        smlabt  r6, r7, r6, r9
        add     r6, r6, r6, lsr #6
        and     lr, r10, \SRC, lsr #(8)
        add     r6, lr, r6, lsr #6
        lsr     r6, #2
        orr     \FB, \FB, r6, lsl #(\OFFSET + 5)

            // blue
            and     lr, \DREG, #(0x1F << \OFFSET)
            smlabt  lr, r7, lr, r8
            add     lr, lr, lr, lsr #5
            and     r6, r10, \SRC, lsr #(8+8)
            add     lr, r6, lr, lsr #5
            lsr     lr, #3
            orr     \FB, \FB, lr, lsl #\OFFSET

.else

    // red
    mov     lr, \DREG, lsr #(6+5)
    and     lr, lr, #0x1F
    smlabb  lr, r7, lr, r8
    add     lr, lr, lr, lsr #5
    and     r6, \SRC, r10
    add     lr, r6, lr, lsr #5
    lsr     lr, #3
    mov     \FB, lr, lsl #11

        // green
        and     r6, \DREG, #(0x3F<<5)
        lsr     r6, #5
        smlabb  r6, r7, r6, r9
        add     r6, r6, r6, lsr #6
        and     lr, r10, \SRC, lsr #(8)
        add     r6, lr, r6, lsr #6
        lsr     r6, #2
        orr     \FB, \FB, r6, lsl #5

            // blue
            and     lr, \DREG, #0x1F
            smlabb  lr, r7, lr, r8
            add     lr, lr, lr, lsr #5
            and     r6, r10, \SRC, lsr #(8+8)
            add     lr, r6, lr, lsr #5
            orr     \FB, \FB, lr, lsr #3

.endif
   b      2f

   /*
    * When alpha = 255, down scale the source RGB pixel (24 bits)
    * to 16 bits(RGB565)
    */
1:
    lsl    r6, \SRC, #8
    lsr    lr, \SRC, #5
    and    r7, r6, #0xf800
    and    lr, lr, #0x7e0
    orr    lr, lr, r7

.if \OFFSET
    orr    lr, lr, r6, lsr #27
    orr    \FB, \FB, lr, lsl #(\OFFSET)
.else
    orr    \FB, lr, r6, lsr #27
.endif

2:
    .endm


// r0:  dst ptr
// r1:  src ptr
// r2:  count
// r3:  d
// r4:  s0
// r5:  s1
// r6:  pixel
// r7:  pixel
// r8:  0x10
// r9:  0x20
// r10: 0xFF
// r11: free
// r12: scratch
// r14: pixel

scanline_t32cb16blend_arm:
    stmfd	sp!, {r4-r10, lr}

    pld     [r0]
    pld     [r1]
    mov     r8, #0x10
    mov     r9, #0x20
    mov     r10, #0xFF

    // align DST to 32 bits
    tst     r0, #0x3
    beq     aligned
    subs    r2, r2, #1
    ldmlofd	sp!, {r4-r10, lr}        // return
    bxlo    lr

last:
    ldr     r4, [r1], #4
    ldrh    r3, [r0]
    pixel   r3, r4, r12, 0
    strh    r12, [r0], #2

aligned:
    subs    r2, r2, #2
    blo     9f

    // The main loop is unrolled thrice and process 6 pixels
8:  ldmia   r1!, {r4, r5}
    // stream the source
    pld     [r1, #32]
    add     r0, r0, #4
    // it's all zero, skip this pixel
    orrs    r3, r4, r5
    beq     7f

    // load the destination
    ldr     r3, [r0, #-4]
    // stream the destination
    pld     [r0, #32]
    pixel   r3, r4, r12, 0
    pixel   r3, r5, r12, 16
    // effectively, we're getting write-combining by virtue of the
    // cpu's write-back cache.
    str     r12, [r0, #-4]

    // 2nd iterration of the loop, don't stream anything
    subs    r2, r2, #2
    blt     9f
    ldmia   r1!, {r4, r5}
    add     r0, r0, #4
    orrs    r3, r4, r5
    beq     7f
    ldr     r3, [r0, #-4]
    pixel   r3, r4, r12, 0
    pixel   r3, r5, r12, 16
    str     r12, [r0, #-4]

    // 3rd iteration of the loop, don't stream anything
    subs    r2, r2, #2
    blt     9f
    ldmia   r1!, {r4, r5}
    add     r0, r0, #4
    orrs    r3, r4, r5
    beq     7f
    ldr     r3, [r0, #-4]
    pixel   r3, r4, r12, 0
    pixel   r3, r5, r12, 16
    str     r12, [r0, #-4]

7:  subs    r2, r2, #2
    blo     9f
    b       8b

9:  adds    r2, r2, #1
    bhs     last
    ldmfd sp!, {r4-r10, lr}        // return
    bx      lr
