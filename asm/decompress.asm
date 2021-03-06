; ===============================================================
; Dec 2012 by Einar Saukas, Antonio Villena & Metalbrain
; "Standard" version (70 bytes)
; ===============================================================
; 
; void dzx7_standard(void *src, void *dst)
;
; Decompress the compressed block at address src to address dst.
;
; ===============================================================

	.assume ADL=1

   ; enter : hl = void *src
   ;         de = void *dst
   ;
   ; exit  : hl = & following uncompressed block
   ;
   ; uses  : af, bc, de, hl

_dzx7_Standard:
        ld      a, 128
       
dzx7s_copy_byte_loop:

        ldi                              ; copy literal byte
        
dzx7s_main_loop:

        call    dzx7s_next_bit
        jr      nc, dzx7s_copy_byte_loop ; next bit indicates either literal or sequence

; determine number of bits used for length (Elias gamma coding)

        push    de
        ld      de, 0
        ld      bc, 0
        
dzx7s_len_size_loop:

        inc     d
        call    dzx7s_next_bit
        jr      nc, dzx7s_len_size_loop

; determine length

dzx7s_len_value_loop:

        call    nc, dzx7s_next_bit
        rl      c
        rl      b
        jr      c, dzx7s_exit           ; check end marker
        dec     d
        jr      nz, dzx7s_len_value_loop
        inc     bc                      ; adjust length

; determine offset

        ld      e, (hl)                 ; load offset flag (1 bit) + offset value (7 bits)
        inc     hl

        sla     e
        inc     e

        jr      nc, dzx7s_offset_end    ; if offset flag is set, load 4 extra bits
        ld      d, 16                   ; bit marker to load 4 bits
        
dzx7s_rld_next_bit:

        call    dzx7s_next_bit
        rl      d                       ; insert next bit into D
        jr      nc, dzx7s_rld_next_bit  ; repeat 4 times, until bit marker is out
        inc     d                       ; add 128 to DE
        srl     d                       ; retrieve fourth bit from D
        
dzx7s_offset_end:

        rr      e                       ; insert fourth bit into E

; copy previous sequence

        ex      (sp), hl                ; store source, restore destination
        push    hl                      ; store destination
        sbc     hl, de                  ; HL = destination - offset - 1
        pop     de                      ; DE = destination
        ldir

dzx7s_exit:

        pop     hl                      ; restore source address (compressed data)
        jr      nc, dzx7s_main_loop
        
dzx7s_next_bit:

        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
