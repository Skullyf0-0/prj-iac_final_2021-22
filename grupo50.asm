;#############################################################################################################################
; Grupo-50
; Bogdan Prokopiuk                              Nº104016
; Frederico André Gonçalves de Almeida Soares   Nº102861 
; Projecto 2021-22_Versão Final
;#############################################################################################################################
;Definicao de constantes 
;#############################################################################################################################
DELAY               EQU 0500H      ; controlo da velocidade de movimentação do rover
DISPLAYS            EQU 0A000H     ; endereco dos Displays de números
TEC_LIN             EQU 0C000H     ; endereco das Linhas do teclado
TEC_COL             EQU 0E000H     ; endereco das Colunas do teclado
LINHA               EQU 8          ; linha a testar (4 linha, 1000b)
MASCARA_L           EQU 0FH        ; isola os 4 bits de menor peso
DEF_REMOVE_FUNDO    EQU 6040H      ; endereço de comando de eliminação de imagem de fundo
DEF_FUNDO           EQU 6042H      ; endereço do comando de alteração de fundo
APAGA_PIXELS        EQU 6002H      ; endereço para apagar todos os pixeis do ecrã
COR_ROVER	    	EQU 0FFB0H     ;
COR_METEORO_B       EQU 0F0F0H     ;
DEF_LINHA    		EQU 600AH      ; endereço do comando para definir a linha
DEF_COLUNA   		EQU 600CH      ; endereço do comando para definir a coluna
DEF_PIXEL    		EQU 6012H      ; endereço do comando para escrever um pixel
DEF_LARGURA_L       EQU 5          ; largura objetos maiores 
ROVER_LT            EQU 28         ; linha topo rover
APAGA_PIXEL         EQU 0          ;
NUM_COLUNAS         EQU 67         ;
NUM_LINHAS          EQU 20         ;
ROVER_START         EQU 32         ;
DEF_SOM_START       EQU 605AH      ; endereço de introdução de soundeffect
DEF_SOM_LOOP        EQU 605CH      ; endereço para definição do loop do som
DEF_SOM_TERM        EQU 6066H      ; endereço para o fim de reprodução de som
DEF_SOM_SP          EQU 605EH      ; endereço para pausar o som
DEF_SOM_TP          EQU 6060H      ; endereço para o fim de pausa de som
ENERGIA_START       EQU 0069H      ; constante de valor inicial de energia do rover 
COR_MISSIL          EQU 0FF0FH     ;
ALCANCE_MISSIL      EQU 15         ;
COR_UNDIFINED       EQU 0FAAAH     ;
METEORO_BOM         EQU 000BH      ;
METEORO_MAU         EQU 0008H      ;
METEORO_INATIVO     EQU 0006H      ;      
NUM_METEOROS        EQU 6          ; a constante define o numero de meteoros no ecrã (por limitações do sistema recomenda-se um máximo de 8 meteoros)
COR_METEORO_M       EQU 0FF00H     ;
CRONOMETRO_SPAWN    EQU 2          ;
METEORO_NEXISTE     EQU 0004H      ;
COR_NUVEM           EQU 0FFFFH     ;
;#############################################################################################################################
;Tratamento de dados e incializacao da pilha
;#############################################################################################################################
	PLACE       1000H
pilha:
	STACK 200H			        ; espaço reservado para a pilha do progrma principal			     
SP_inicial_prog_princ:			; este é o endereço (1200H) com que o SP deve ser 
	
    STACK 100H                  ; espaço reservado para a pilha do processo de teclado_8
SP_inicial_teclado_8:

    STACK 100H                  ; espaço reservado para a pilha do processo de teclado_1
SP_inicial_teclado_1:

tecla_carregada_8:              ; local onde fica a variavel com a informção da tecla primida (teclado_8)
    LOCK 0
tecla_carregada_1:              ; local onde fica a variavel com a informção da tecla primida (teclado_1)
    LOCK 0
random:                         ; localização da variavel criada através do processo peseudo-random
    LOCK 0
destruction:                    ; localização da variável que temporiza o efeito de destruição
    WORD 0

PLACE 2000H

C:
    WORD ENERGIA_START          ; armazeno a constante com o valor inicial do display de números
nv_ln:                              
    WORD 0                      ; armazena o local onde está o meteoro destruído (linha)
nv_cl:
    WORD 0                      ; armazena o local onde está o meteoro destruído (coluna)
; Tabela das rotinas de interrupção
tab: 
    WORD rot_meteoro            ; rotina de atendimento da interrupção 0
    WORD rot_missil             ; rotina de atendimento da interrupção 1
    WORD rot_energia            ; rotina de atendimento da interrupção 2

estado:
    WORD 0                      ;estado energia
    WORD 0                      ;estado missil
    WORD 0                      ;estado meteoros

rover:
    word 32                     ;coluna rover

meteoros:
    	TABLE 0040H             ;Guarda tuda a informaçao dos meteoros (  linha, coluna e tipo, respetivamente)

missil:
    WORD 10                     ;Linha
    WORD 10                     ;Coluna
    WORD 0                      ;Estado

spawn_meteoros:                   
    WORD 1                      ;counter spawn
    WORD 1                      ;conta meteoros existentes
;#############################################################################################################################
;Início do programa->versão final
;#############################################################################################################################
PLACE   0H
inicio:
    MOV  SP, SP_inicial_prog_princ            ; começa a pilha com o endereço SP_inicial
    MOV BTE, tab                              ; inicializa BTE
    MOV R6, 32                                ;
    MOV [rover], R6                           ;
;#############################################################################################################################
;inicia o display do media center com a tela de introdução 
;#############################################################################################################################
start_media:
    MOV R6, 32                                ;
    MOV [rover], R6                           ;
    MOV R1, 0        
    MOV [DEF_REMOVE_FUNDO], R1                ; remove a mensagem inicial do media display
    MOV [DEF_FUNDO], R1                       ; escreve no display o ecrã de introdução
    MOV R1, ENERGIA_START
    MOV [C], R1
    CALL espera_start
    CALL teclado                              ; cria o processo teclado
    CALL teclado_1                            ; cria o processo teclado_1
    JMP start_game

;#############################################################################################################################
;Esta rotina espera até a tecla 'C' ser primida para iniciar o jogo
;#############################################################################################################################
espera_start:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R5
    PUSH R8
ciclo_start:
    MOV R1, LINHA                             ; testa a linha 4 onde está a tecla 'C'
    MOV  R2, TEC_LIN                          ; endereco do periferico das linhas
    MOV  R3, TEC_COL                          ; endereco do periferico das colunas
    MOV  R5, MASCARA_L                        ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
    MOVB [R2], R1                             ; escrever no periferico de saida (linhas)
    MOVB R0, [R3]                             ; ler do periferico de entrada (colunas)
    AND  R0, R5                               ; elimina bits para alem dos bits 0-3 por que os perifericos operam com 8 bits
    SHL  R1, 4                                ; coloca linha no nibble high (os primeiros binarios ficam a zeros)
    MOV R2, R1
    OR   R1, R0                               ; junta coluna (coloca o resultado da coluna no R1)
    MOV  R8, 0081H                            ; verifica se a tecla de inicio de jogo foi primida 
    XOR  R1, R8                               ; compara os valores e se forem iguais o resultado será 0
    JNZ ciclo_start                           ; se a tecla for primida o jogo começa 
    POP R8
    POP R5
    POP R3
    POP R2
    POP R1
    POP R0
    RET

;#############################################################################################################################
;Começa o jogo escrevendo na tela o fundo do jogo o rover e os meteoros, atualiza o display e se tiver em condição 
;de pausa ou de fim de jogo executa as rotinas de ambas as situações
;#############################################################################################################################
start_game: 
    CALL dec_display
    MOV R1, 6                     
    MOV [DEF_SOM_START], R1                   ; inicia no display a tela de fundo do jogo (vídeo em loop)
    MOV [DEF_SOM_LOOP], R1
    MOV R1, 0
    MOV [DEF_SOM_START], R1                   ; começa a reprodução da música de fundo 
    MOV [DEF_SOM_LOOP], R1                    ; a música de fundo toca em loop até ser terminada ou pausada posteriormente
    EI0                                       ; ablita as interrupções
    EI1
    EI2
    EI
    CALL desenha_rover                        ; inicia o rover e os meteoros
    CALL start_meteoros

atualiza_display:
    CALL nuvem                                ; verifica se há nuvem de destruição para apagar
    CALL dec_display                          ; atualiza no display a energia
    CALL start_novo_meteoro                   ; começa  movimento de um meteoro novo se o número máximo não foi atingido
    CALL move_meteoros                        ; move os meteoros no display
    CALL move_missil                          ; move o missil se este tiver sido lançado
    MOV R1, [C]                   
    MOV R2, 0000H
    CMP R1, R2                                ; verifico se há energia
    JLE no_energy                             ; verifica se a energia não está a zeros ou mais baixa que zero   
disparo:
    MOV	R1, [tecla_carregada_1]	              ; bloqueia neste LOCK até uma tecla ser carregada
	MOV R2, 0012H
    XOR	R1, R2	                              ; é a tecla 1?
	JNZ	tecla_D
    CALL fire_in_the_hole                     ; se sim é disparado um missil se estiver em condições de o fazer
tecla_D:	
	MOV	R1, [tecla_carregada_8]	               
	MOV R2, 0082H
    XOR	R1, R2	                              ; é a tecla D?
	JNZ	testa_F
    CALL paused                               ; se sim o jogo é pausado
testa_F:
    MOV	R1, [tecla_carregada_8]	               
	MOV R2, 0088H
    XOR	R1, R2	                              ; é a tecla F?
	JNZ atualiza_display
no_energy:
    CALL end                                  ; se a energia for zero ou o for primida a tecla f o jogo termina (end 1)
    JMP start_media

;#############################################################################################################################
;Esta rotina processa a tecla 'D' põe o jogo em pausa e se clicar novamente
;na tecla o jogo recomeça no ponto em que foi pausado 
;#############################################################################################################################
paused:
    DI                                        ; desablito as interrupções
    PUSH R1                                   ; armazeno as variáveis na pilha 
    PUSH R2
    PUSH R4
    MOV R1, 0
    MOV [tecla_carregada_8], R1
    MOV [APAGA_PIXELS], R1                    ; apago todos os pixeis que constituem o rover e os meteoros 
    MOV [DEF_SOM_SP], R1                      ; pauso a musica de fundo e termino o replay do vídeo de fundo
    MOV R1, 6
    MOV [DEF_SOM_TERM], R1
    MOV R1, 1
    MOV [DEF_FUNDO], R1                       ; escrevo no display o fundo de pausa 
ha_tecla_paused:                              ; verifico que a tecla deixou de ser primida observando se no periferico de saída sai 0
    MOV R1, LINHA 
    MOV R2, TEC_LIN
    MOVB [R2], R1
    MOV R2, TEC_COL
    MOVB R4, [R2]
    MOV R2, MASCARA_L
    AND R4, R2
    CMP R4, 0
    JNZ ha_tecla_paused
ciclo_pausa:                                  ; verifico se a tecla de pausa foi primida outra vez
    MOV R1, LINHA
    MOV R2, TEC_LIN
    MOVB [R2], R1
    MOV R2, TEC_COL 
    MOVB R4, [R2]
    MOV R2, MASCARA_L
    AND R4, R2
    SHL R1, 4
    OR R1, R4
    MOV R2, 0082H                             ; verifico se a o valor que possuí a linha (8) e coluna (2)                    
    XOR R1, R2
    JNZ ciclo_pausa                           ; se a tecla primida não for o ciclo recomeça e espera até a tecla ser primida  
ha_tecla_paused_end:                          ; verifico que a tecla deixou de ser primida observando se no periferico de saída sai 0
    MOV R1, LINHA 
    MOV R2, TEC_LIN
    MOVB [R2], R1
    MOV R2, TEC_COL
    MOVB R4, [R2]
    MOV R2, MASCARA_L
    AND R4, R2
    CMP R4, 0
    JNZ ha_tecla_paused_end                   ; se não for zero recomeça o loop
    MOV R1, 0
    MOV [DEF_SOM_TP], R1                      ; continuo a reprodução da música se fundo
    MOV R1, 6
    MOV [DEF_SOM_START], R1                   ; recomeço a reprodução do vídeo de fundo
    MOV [DEF_SOM_LOOP], R1                     
    POP R4
    POP R2
    POP R1
    EI                                        ; ablito as interrupções novamente
    RET

;#############################################################################################################################
;Condição final de paragma é apresentada a tela de game over comum, espera que 'C' seja
;primida novamente retorna se isso acontecer e recomeça o jogo
;#############################################################################################################################
end:
    DI                                        ; desablito as interrupções
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R8
    MOV R1, 0
    MOV [missil+4], R1                        ; desativa o missil se houver
    MOV [tecla_carregada_8], R1
    MOV [APAGA_PIXELS], R1                    ; apaga todos os pixels no ecrã e termino a reprodução da música e fundo de ecrã
    MOV [DEF_SOM_TERM], R1
    MOV R1, 6
    MOV [DEF_SOM_TERM], R1
    MOV R1, 2
    MOV [DEF_FUNDO], R1                       ; escreve no ecrã a tela de game over 
    MOV R1, 2
    MOV [DEF_SOM_START], R1
ciclo_stop:
    MOV R1, LINHA
    MOV R2, TEC_LIN                           ; testar a linha 4 onde está a tecla 'C'
    MOVB [R2], R1  
    MOV R3, TEC_COL                           ; escrever no periferico de saida (linhas)
    MOVB R0, [R3]                             ; ler do periferico de entrada (colunas)
    MOV R5, MASCARA_L
    AND  R0, R5                               ; elimina bits para alem dos bits 0-3 por que os perifericos operam com 8 bits
    SHL  R1, 4                                ; coloca linha no nibble high (os primeiros binarios ficam a zeros)
    OR   R1, R0                               ; junta coluna (coloca o resultado da coluna no R1)
    MOV  R8, 0081H                            ; verifica se a tela de inicio de jogo foi primida 
    XOR  R1, R8                               ; compara os valores e se forem iguais o resultado será 0
    JNZ ciclo_stop
ha_tecla_over:                     
    MOV R1, LINHA                 
    MOV R2, TEC_LIN
    MOVB [R2], R1                             ; testo a linha 4 do teclado
    MOV R2, TEC_COL
    MOVB R4, [R2]                             ; ler do periferico de saída a coluna
    MOV R2, MASCARA_L
    AND R4, R2                                ; verificar que o mesmo esta a zeros
    CMP R4, 0                                 ; se a tecla 'C' não estiver primida então o jogo voltará ao ínicio e recomeçará
    JNZ ha_tecla_over
    POP R8
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

;#############################################################################################################################
; rotina que processa o termino do jogo quando uma nave inimiga atinge o rover
;#############################################################################################################################
end_dcrt:
    DI                                        ; disablito as interrupções 
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R8
    MOV R1, 0
    MOV [missil+4], R1                        ; desativa o missil se existir
    MOV [tecla_carregada_8], R1
    MOV [APAGA_PIXELS], R1                    ; apaga todos os pixels no ecrã e termino a execução do vídeo de fundo e música
    MOV [DEF_SOM_TERM], R1
    MOV R1, 6
    MOV [DEF_SOM_TERM], R1
    MOV R1, 3
    MOV [DEF_FUNDO], R1                       ; escreve no ecrã a tela de game over (2) 
    MOV R1, 3
    MOV [DEF_SOM_START], R1
ciclo_stop_2:
    MOV R1, LINHA
    MOV R2, TEC_LIN                           ; testa a linha 4 onde está a tecla 'C'
    MOVB [R2], R1  
    MOV R3, TEC_COL                           ; escrever no periferico de saida (linhas)
    MOVB R0, [R3]                             ; ler do periferico de entrada (colunas)
    MOV R5, MASCARA_L
    AND  R0, R5                               ; elimina bits para alem dos bits 0-3 por que os perifericos operam com 8 bits
    SHL  R1, 4                                ; coloca linha no nibble high (os primeiros binarios ficam a zeros)
    OR   R1, R0                               ; junta coluna (coloca o resultado da coluna no R1)
    MOV  R8, 0081H                            ; verifica se a tela de inicio de jogo foi primida 
    XOR  R1, R8                               ; compara os valores e se forem iguais o resultado será 0
    JNZ ciclo_stop_2
ha_tecla_over_2:                     
    MOV R1, LINHA                 
    MOV R2, TEC_LIN
    MOVB [R2], R1                             ; testo a linha 4 do teclado
    MOV R2, TEC_COL
    MOVB R4, [R2]                             ; ler do periferico de saída a coluna
    MOV R2, MASCARA_L
    AND R4, R2                                ; verificar que o mesmo esta a zeros
    CMP R4, 0                                 ; se a tecla 'C' não estiver primida então o jogo voltará ao ínicio e recomeçará
    JNZ ha_tecla_over_2
    POP R8                       
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    JMP start_media
    RET

;#############################################################################################################################
;ROT_INT_ENERGIA
;#############################################################################################################################
rot_energia:
    PUSH R1
    MOV R1, [C]
    SUB R1, 0005H
    MOV [C], R1
    MOV R1, [spawn_meteoros]                  ;//                 //               //
    ADD R1, 1                                 ;//                 //               //
    MOV [spawn_meteoros], R1                  ;Aumenta o cronometro de spawn meteoros
    POP R1
    RFE

;#############################################################################################################################
; ROT_INT_MISSIL
;#############################################################################################################################
rot_missil:
    PUSH R1
    PUSH R2
    PUSH R10
    MOV R10, 1
    MOV [estado+2], R10                       
    MOV	R1, [tecla_carregada_1]	              
	MOV R2, 0011H
    XOR	R1, R2	                              ; é a tecla 0?
	JNZ	mov_d
    CALL move_rover_esquerda                  ; se sim movimenta o rover para a esquerda
mov_d:  
    MOV	R1, [tecla_carregada_1]	              
	MOV R2, 0014H
    XOR	R1, R2	                              ; é a tecla 2?
	JNZ	end_mov
    CALL move_rover_direita                   ; se sim movimenta o rover para direita
end_mov:
    POP R10
    POP R2
    POP R1                             
    RFE

;#############################################################################################################################
;ROT_METEORO
;#############################################################################################################################
rot_meteoro:
    PUSH R10
    MOV R10, 1
    MOV [estado], R10                   
    POP R10                               
    CALL desenha_rover
	RFE

;#############################################################################################################################
; Processo
;
; TECLADO_8 - Processo que deteta quando se carrega numa tecla na 4ª linha
;		      do teclado e escreve o valor da coluna e linha num LOCK.
;
;#############################################################################################################################
PROCESS SP_inicial_teclado_8	              ; indicação de que a rotina que se segue é um processo,
						                    ; com indicação do valor para inicializar o SP
teclado:					                  ; processo que implementa o comportamento do teclado
	MOV  R2, TEC_LIN		                  ; endereço do periférico das linhas
	MOV  R3, TEC_COL		                  ; endereço do periférico das colunas
	MOV  R5, MASCARA_L		                  ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	

espera_tecla_8:				                  ; neste ciclo espera-se até uma tecla ser premida

	YIELD				                      ; este ciclo é potencialmente bloqueante, pelo que tem de
						                    ; ter um ponto de fuga (aqui pode comutar para outro processo)
    MOV  R1, LINHA	                          ; testar a linha 4 
	MOVB [R2], R1			                  ; escrever no periférico de saída (linhas)
	MOVB R0, [R3]			                  ; ler do periférico de entrada (colunas)                  
	MOV R6, R0
    SHR R6, 5                                 ; cria o valor random através do algoritmo pseudo-random
    MOV [random], R6 
    AND  R0, R5			                      ; elimina bits para além dos bits 0-3 
    SHL R1, 4
    OR R0, R1
    MOV	[tecla_carregada_8], R0	              ; informa quem estiver bloqueado neste LOCK que uma tecla foi carregada

ha_tecla_8:					                  ; neste ciclo espera-se até NENHUMA tecla estar premida

	YIELD				                      ; este ciclo é potencialmente bloqueante, pelo que tem de
						                    ; ter um ponto de fuga (aqui pode comutar para outro processo)

    MOVB [R2], R1			                  ; escrever no periférico de saída (linhas)
    MOVB R0, [R3]			                  ; ler do periférico de entrada (colunas)
	AND  R0, R5			                      ; elimina bits para além dos bits 0-3
    CMP  R0, 0			                      ; há tecla premida?
    JNZ  ha_tecla_8			                  ; se ainda houver uma tecla premida, espera até não haver
 
	JMP	espera_tecla_8		                  ; esta "rotina" nunca retorna porque nunca termina

;#############################################################################################################################
; Processo
;
; TECLADO_1 - Processo que deteta quando se carrega numa tecla na 1ª linha
;		      do teclado e escreve o valor da coluna e linha num LOCK.
;
;#############################################################################################################################
PROCESS SP_inicial_teclado_1	              ; indicação de que a rotina que se segue é um processo,
						    
teclado_1:					
	MOV  R2, TEC_LIN		
	MOV  R3, TEC_COL		
	MOV  R5, MASCARA_L		
	

espera_tecla_1:				                  ; neste ciclo espera-se até uma tecla ser premida

	YIELD				                      ; este ciclo é potencialmente bloqueante, pelo que tem de
						                    ; ter um ponto de fuga (aqui pode comutar para outro processo)
    MOV  R1, 0001H	                          ; testar a linha 1 
	MOVB [R2], R1			                  ; escrever no periférico de saída (linhas)
	MOVB R0, [R3]			                  ; ler do periférico de entrada (colunas)                  
    AND  R0, R5			                      ; elimina bits para além dos bits 0-3 
    SHL R1, 4
    OR R0, R1
    MOV	[tecla_carregada_1], R0               ; informa quem estiver bloqueado neste LOCK que uma tecla foi carregada

ha_tecla_1:					                  ; neste ciclo espera-se até NENHUMA tecla estar premida

	YIELD				                      ; este ciclo é potencialmente bloqueante, pelo que tem de
						                    ; ter um ponto de fuga (aqui pode comutar para outro processo)
    MOVB [R2], R1			                  ; escrever no periférico de saída (linhas)
    MOVB R0, [R3]			                  ; ler do periférico de entrada (colunas)
	AND  R0, R5			                      ; elimina bits para além dos bits 0-3
    CMP  R0, 0			                      ; há tecla premida?
    JNZ  ha_tecla_1			                  ; se ainda houver uma tecla premida, espera até não haver
 
	JMP	espera_tecla_1		
						
;#############################################################################################################################
;esta rotina traduz valores em hexadecimal para 'decimal' e atualiza o display
;#############################################################################################################################
dec_display:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    MOV R2, 000AH
    MOV R3, 0 
    MOV R4, 1000d
ciclo_display:
    MOV R1, [C]                               ; o valor da energia encontra-se no endereço 'C'
    MOD R1, R4                                ; através do algoritmo especificado no guião do lab 7 obtenho o digito novo do número traduzido 
    DIV R4, R2
    DIV R1,R4
    SHL R3, 4
    OR R3, R1                                 ; acrescento o digito ao resultado
    CMP R4, R2
    JLT mostra                                ; este loop repete-se até o fator(R4) se menor que 10 
    JMP ciclo_display
mostra:
    MOV [DISPLAYS], R3
    POP R4
    POP R3
    POP R2
    POP R1
    RET


;!!!!!!!!!!!!!!!!!!!!TODAS AS ROTINAS DE FORMATO PARTEM DE UM PIXEL DE REFERENCIA (CANTO SUPERIOR ESQUERDO)!!!!!!!!!!!!!!!!!!!!
;#############################################################################################################################
;A rotina define o formato do meteoro 'nao defenido pequeno', pode ser usada para apagar ou escrever o meteoro
;#############################################################################################################################

formato_meteoroUDL:
    PUSH R6 
    PUSH R7                                   ; linha
    PUSH R8                                   ; coluna

    MOV R6, R7                                ; linha topo  meteoro                  
;----------------------------- primeira coluna -----------------------------
    CALL escreve_pixel
    ADD R7, 1
    CALL escreve_pixel
    ADD R8, 1

;----------------------------- segunda coluna ------------------------------
    MOV R7, R6
    CALL escreve_pixel
    ADD R7, 1
    CALL escreve_pixel

    POP R8
    POP R7
    POP R6
    RET

;#############################################################################################################################
;a rotina define o formato do 'meteoro bom grande', podendo ser usada para desenhar ou apagar o dito meteoro
;#############################################################################################################################

formato_meteoroBS:
    PUSH R6
    PUSH R7                                   ; linha
    PUSH R8                                   ; coluna 
    PUSH R10                                  ;           

    MOV R6, R7
;---------------------------- primeira coluna ------------------------------     
    ADD R7, 1                                 ; primeiro pixel sem cor
    CALL escreve_pixel                        ; 
;---------------------------- segunda coluna ------------------------------    
    MOV R7, R6                                ; Linha topo meteoro
    MOV R10, 3                                ; 3 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 
;---------------------------- terceira coluna ------------------------------  
    MOV R7, R6                                ; Linha topo meteoro
    ADD R7, 1                                 ; primeiro pixel sem cor
    ADD R8, 1
    CALL escreve_pixel           

    POP R10
    POP R8
    POP R7
    POP R6  
    RET


;#############################################################################################################################
;a rotina define o formato do 'meteoro bom medio' , podendo ser usada para desenhar ou apagar o dito meteoro
;#############################################################################################################################

formato_meteoroBM:
    PUSH R6                                   ; linha
    PUSH R7
    PUSH R8                                   ; coluna 
    PUSH R10                                  ;           

    MOV R6, R7                                ; pixel referencia meteoro coluna
;---------------------------- primeira coluna ------------------------------     
    ADD R7, 1                                 ; primeiro pixel sem cor
    MOV R10, 2                                ; 2 pixeis seguidos com cor
    CALL desenha_coluna 
;---------------------------- segunda coluna ------------------------------    
    MOV R7, R6                                ; Linha topo meteoro
    MOV R10, 4                                ; 4 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 
;---------------------------- terceira coluna ------------------------------  
    MOV R7, R6                                ; Linha topo meteoro
    MOV R10, 4                                ; 4 pixeis seguidos com cor
    ADD R8, 1
    CALL desenha_coluna 
;---------------------------- quarta coluna ------------------------------  
    MOV R7, R6                                ; Linha topo meteoro
    ADD R7, 1                                 ; 1 pixel sem cor
    MOV R10, 2                                ; 2 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 

    POP R10
    POP R8
    POP R7
    POP R6  
    RET

;#############################################################################################################################
;a rotina define o formato do 'meteoro bom grande' , podendo ser usada para desenhar ou apagar o dito meteoro
;#############################################################################################################################

formato_meteoroBL:
    PUSH R6
    PUSH R7                                   ; linha
    PUSH R8                                   ; coluna 
    PUSH R10                                  ;           

    MOV R6, R7   
;---------------------------- primeira coluna ------------------------------     
    ADD R7, 1                                 ; primeiro pixel sem cor
    MOV R10, 3                                ; 3 pixeis seguidos com cor
    CALL desenha_coluna 
;---------------------------- segunda coluna ------------------------------    
    MOV R7, R6                                ; Linha topo meteoro
    MOV R10, 5                                ; 5 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 
;---------------------------- terceira coluna ------------------------------  
    MOV R7, R6                                ; Linha topo meteoro
    MOV R10, 5                                ; 5 pixeis seguidos com cor
    ADD R8, 1
    CALL desenha_coluna 
;---------------------------- quarta coluna ------------------------------  
    MOV R7, R6                                ; Linha topo meteoro
    MOV R10, 5                                ; 5 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 
;---------------------------- quinta coluna ------------------------------  
    MOV R7, R6                                ; Linha topo meteoro
    ADD R7, 1                                 ; primeiro pixel sem cor
    MOV R10, 3                                ; 3 pixeis seguidos com cor
    ADD R8, 1
    CALL desenha_coluna 

    POP R10
    POP R8
    POP R7
    POP R6   
    RET

;#############################################################################################################################
;A rotina define o formato do rover podendo ser usada para apagar ou desenhar o mesmo
;#############################################################################################################################

formato_rover:
    PUSH R7                                   ; linha
    PUSH R8                                   ; coluna 
    PUSH R10                              

    MOV R8, [rover]                           ;           
;---------------------------- primeira coluna ------------------------------     
    MOV R7, ROVER_LT                          ; Linha topo Rover
    ADD R7, 2                                 ; primeiros 2 pixel sem cor
    MOV R10, 2                                ; 2 pixeis seguidos com cor
    CALL desenha_coluna 
;---------------------------- segunda coluna ------------------------------    
    MOV R7, ROVER_LT                          ; Linha topo Rover
    ADD R7, 1                                 ; primeiro pixel sem cor
    MOV R10, 2                                ; 2 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 
;---------------------------- terceira coluna ------------------------------  
    MOV R7, ROVER_LT                          ; Linha topo Rover
    MOV R10, 4                                ; 4 pixeis seguidos com cor
    ADD R8, 1
    CALL desenha_coluna 
;---------------------------- quarta coluna ------------------------------  
    MOV R7, ROVER_LT                          ; Linha topo Rover
    ADD R7, 1                                 ; primeiro pixel sem cor
    MOV R10, 2                                ; 2 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 
;---------------------------- quinta coluna ------------------------------  
    MOV R7, ROVER_LT                          ; Linha topo Rover
    ADD R7, 2                                 ; primeiros 2 pixel sem cor
    MOV R10, 2                                ; 2 pixeis seguidos com cor
    ADD R8, 1                                 ; passa coluna seguinte
    CALL desenha_coluna 

    POP R10
    POP R8
    POP R7
    RET

;#############################################################################################################################
;A rotina define o formato do 'meteoro mau pequeno'
;#############################################################################################################################
formato_meteoroMS:
    PUSH R6
    PUSH R7                                   ; linha 
    PUSH R8                                   ; coluna
    PUSH R10
    
    MOV R6, R7                                ; linha topo meteoro 
 ;----------------------------- primeira coluna ---------------------------------
    CALL escreve_pixel                        ; primeiro pixel com cor 
    ADD R7, 2                                 ; dois pixeis sem cor
    CALL escreve_pixel
;------------------------------ segunda coluna ----------------------------------
    MOV R7, R6
    ADD R8, 1                                     
    ADD R7, 1                                 ; primeiro pixel sem cor
    CALL escreve_pixel
;------------------------------ terceira coluna --------------------------------
    MOV R7, R6
    ADD R8, 1                                 ; //         //          //
    CALL escreve_pixel                        ; //         //          //
    ADD R7, 2                                 ; simetrica primeira coluna
    CALL escreve_pixel
    POP R10 
    POP R8
    POP R7
    POP R6
    RET

;#############################################################################################################################
;A rotina define o formato do 'meteoro mau medio'
;#############################################################################################################################
formato_meteoroMM:
    PUSH R6
    PUSH R7
    PUSH R8
    PUSH R10

    MOV R6, R7                                ; linha topo meteoro
;---------------------------- primeira coluna ---------------------------------
    MOV R10, 2                                ; coluna de dois pixeis com cor
    CALL desenha_coluna
    ADD R7, 3                                 ; tres linhas sem cor
    CALL escreve_pixel                             
;---------------------------- segunda coluna ----------------------------------
    MOV R7, R6
    ADD R8, 1                                      
    ADD R7, 2                                 ; dois primeiros pixeis sem cor
    CALL escreve_pixel
;---------------------------- terceira coluna ---------------------------------
    MOV R7, R6                                ; //         //          //
    ADD R8, 1                                 ; //         //          //
    ADD R7, 2                                 ; simetrica segunda coluna 
    CALL escreve_pixel
;---------------------------- quarta coluna -----------------------------------
    MOV R7, R6
    ADD R8, 1 
    MOV R10, 2                                ; //          //         //
    CALL desenha_coluna                       ; //          //         //
    ADD R7, 3                                 ; simetrica primeira coluna
    CALL escreve_pixel
    
    POP R10 
    POP R8
    POP R7
    POP R6
    RET

;#############################################################################################################################
; A rotina define o formato do 'meteoro mau grande'
;#############################################################################################################################
formato_meteoroML:
    PUSH R6
    PUSH R7
    PUSH R8
    PUSH R10

    MOV R6, R7
;---------------------------- primeira coluna ---------------------------------
    MOV R10, 2                                ; dois pixeis com cor
    CALL desenha_coluna                       
    ADD R7, 3                                 ; espaço de tres pixeis sem cor
    MOV R10, 2                                ; dois pixeis com cor
    CALL desenha_coluna
;---------------------------- segunda coluna ----------------------------------
    MOV R7, R6
    ADD R8, 1 
    ADD R7, 2                                 ; dois pixeis sem cor
    CALL escreve_pixel
;---------------------------- terceira coluna ---------------------------------
    MOV R7, R6
    ADD R8, 1
    ADD R7, 1                                 ; um pixel sem cor
    MOV R10, 3                                ; tres pixeis com cor   
    CALL desenha_coluna 
;---------------------------- quarta coluna -----------------------------------
    MOV R7, R6
    ADD R8, 1                                 ; simetrica segunda coluna 
    ADD R7, 2                                 
    CALL escreve_pixel
;---------------------------- quinta coluna -----------------------------------
    MOV R7, R6
    ADD R8, 1
    MOV R10, 2
    CALL desenha_coluna                      ; simetrica primeira coluna 
    ADD R7, 3
    MOV R10, 2
    CALL desenha_coluna
    
    POP R10 
    POP R8
    POP R7
    POP R6
    RET

;#############################################################################################################################
; A rotina desenha o formato de uma nuvem
;#############################################################################################################################

formato_nuvem:
    PUSH R6
    PUSH R7
    PUSH R8
    PUSH R10

    MOV R6, R7
;---------------------------- primeira coluna ---------------------------------
    ADD R7,1
    CALL escreve_pixel
    ADD R7, 2
    CALL escreve_pixel
;---------------------------- segunda coluna ----------------------------------
    MOV R7, R6
    ADD R8, 1
    CALL escreve_pixel
    ADD R7, 2 
    CALL escreve_pixel
    ADD R7, 2
    CALL escreve_pixel
;---------------------------- terceira coluna ---------------------------------
    MOV R7, R6
    ADD R8, 1
    ADD R7, 1 
    CALL escreve_pixel
    ADD R7, 2 
    CALL escreve_pixel
;---------------------------- quarta coluna -----------------------------------
    MOV R7, R6
    ADD R8, 1
    CALL escreve_pixel
    ADD R7, 2 
    CALL escreve_pixel
    ADD R7, 2 
    CALL escreve_pixel
;---------------------------- quinta coluna -----------------------------------
    MOV R7, R6
    ADD R8, 1
    ADD R7, 1
    CALL escreve_pixel
    ADD R7, 2 
    CALL escreve_pixel
    POP R10 
    POP R8
    POP R7
    POP R6
    RET

;#############################################################################################################################
;A rotina desenha o Rover na sua posicao atual considerando o pixel de referencia atualmente guardado em memoria
;#############################################################################################################################

desenha_rover:
    PUSH R9                                   ; cor pixeis
    MOV R9, COR_ROVER
    CALL formato_rover                        ;
    POP R9
    RET

;#############################################################################################################################
;A rotina apaga o Rover na posicao atualmente refente ao pixel guardado em memoria que refere o Rover
;#############################################################################################################################

apaga_rover:
    PUSH R9                                   ; cor pixeis
    MOV R9, APAGA_PIXEL                       ;
    CALL formato_rover                        ;
    POP R9
    RET

;#############################################################################################################################
;A funçao obtem os formatos dos meteoros nao defenidos quansoante a posiçao em que o meteoros se encrontra no ecran
;#############################################################################################################################

get_meteoroUD:
    PUSH R6
    PUSH R7
    PUSH R8
    MOV R6, 2                                 ; //                                     //                                  //
    CMP R7, R6                                ; //                                     //                                  //
    JGT size_2_gmud                           ; caso o meteoro se encontr nas duas primeiras linhas desenha o meteoro pequeno
    CALL escreve_pixel                        ; 'meteoro nao defenido pequeno'
    JMP end_gmud
size_2_gmud:
    CALL formato_meteoroUDL                   ; 'meteoro nao defenido grande'
end_gmud:
    POP R8
    POP R7
    POP R6
    RET
;#############################################################################################################################
;A funçao obtem os formatos dos meteoros maus quansoante a posiçao em que o meteoros se encrontra no ecran
;#############################################################################################################################

get_meteoroM:
    PUSH R6
    PUSH R7              
    PUSH R8                                   ; //                                     //                                      //
    MOV R6, 8                                 ; //                                     //                                      //
    CMP R6, R7                                ; caso o meteor se encontre nas 7 primeiras linhas o formato é 'meteoro mau pequeno'
    JLE size_2_gmm
    CALL formato_meteoroMS
    JMP end_gmm
size_2_gmm:
    ADD R6, 3                                 ; //                                     //                                      //
    CMP R6, R7                                ; //                                     //                                      //
    JLE size_3_gmm                            ; caso o meteoro se encontre nas 10 primeiras linhas o formato é 'meteoro mau medio'
    CALL formato_meteoroMM
    JMP end_gmm
size_3_gmm:
    CALL formato_meteoroML                    ; nos restantes casos o formato é 'meteopro mau grande'
end_gmm:
    POP R8
    POP R7
    POP R6
    RET


;#############################################################################################################################
;A funçao obtem os formatos do meteoros bons consoante a sua posiçao no ecran
;#############################################################################################################################

get_meteoroB:
    PUSH R6
    PUSH R7
    PUSH R8                                   ; //                                     //                                      //
    MOV R6, 8                                 ; //                                     //                                      //
    CMP R6, R7                                ; caso o meteor se encontre nas 7 primeiras linhas o formato é 'meteoro bom pequeno'
    JLE size_2_gmb
    CALL formato_meteoroBS
    JMP end_gmb
size_2_gmb:
    ADD R6, 3                                 ; //                                     //                                      //
    CMP R6, R7                                ; //                                     //                                      //
    JLE size_3_gmb                            ; caso o meteoro se encontre nas 10 primeiras linhas o formato é 'meteoro bom medio'
    CALL formato_meteoroBM
    JMP end_gmb
size_3_gmb:
    CALL formato_meteoroBL                    ; nos restantes casos o formato é 'meteopro bom grande'              
end_gmb:
    POP R8
    POP R7
    POP R6
    RET


;#############################################################################################################################
;A rotina desenha desenha os meteoros bons consoante a sua posição no ecran 
;#############################################################################################################################
desenha_meteoroB:
    PUSH R6
    PUSH R9
    PUSH R11                               
    MOV R9, 5
    CMP R7, R9 
    JGE pre_end_dmb                                                           
    MOV R9, COR_UNDIFINED                     ; //                 //                   //
    CALL get_meteoroUD                        ; cor indefenida se o meteoro for indefenido
    JMP end_dmb
pre_end_dmb:
    MOV R9, COR_METEORO_B                     ; //               //              //
    CALL get_meteoroB                         ; cor meteoro bom nos restantes casos
end_dmb:    
    POP R11
    POP R9
    POP R6
    RET

;#############################################################################################################################
;A rotina desenha os meteoros maus consoante a sua posiçao no ecran
;#############################################################################################################################
desenha_meteoroM:
    PUSH R6
    PUSH R9
    PUSH R11                                  ; cor pixeis
    MOV R9, [R6+4]                            ; tipo meteoro
    MOV R11, METEORO_INATIVO
    CMP R9, R11                               ; //                 //                    //
    JZ end_dmm                                ; apenas desenha o meteoro se for do tipo mau
    MOV R9, 5
    CMP R7, R9 
    JGE pre_end_dmm                           ; //                  //                  //
    MOV R9, COR_UNDIFINED                     ; cor indefenida se o meteoro for indefenido
    CALL get_meteoroUD                     
    JMP end_dmm
pre_end_dmm:
    MOV R9, COR_METEORO_M
    CALL get_meteoroM                         ; cor meteoro bom nos restantes casos
end_dmm:    
    POP R11
    POP R9
    POP R6
    RET

;#############################################################################################################################
;A rotina apaga um meteoro bom, semelhnate a desenha meteoro bom mas apenas com a cor apaga pixel
;#############################################################################################################################

apaga_meteoroB:
    PUSH R9                                   ; cor pixeis
    MOV R9, 5
    CMP R7, R9 
    JGE pre_end_amb
    MOV R9, APAGA_PIXEL
    CALL get_meteoroUD                        ; para meteoros nao defenidos(linha inferior a 5)
    JMP end_amb
pre_end_amb:
    CALL get_meteoroB                         ; para meteoros defenidos
end_amb:    
    POP R9
    RET

;#############################################################################################################################
;A rotina apaga o meteoro mau
;#############################################################################################################################

apaga_meteoroM:
    PUSH R9                                   ; cor pixeis
    MOV R9, 5
    CMP R7, R9 
    JGE pre_end_amm
    MOV R9, APAGA_PIXEL
    CALL get_meteoroUD                        ; para meteoros nao defenidos (linha inferior a 5)
    JMP end_amm
pre_end_amm:
    CALL get_meteoroM
end_amm:    
    POP R9
    RET

;#############################################################################################################################
;A rotina recebe um endereço de um meteoro e desenha o no ecran
;#############################################################################################################################

desenha_meteoro:
    PUSH R6                                   ; recebe no reguisto 6 o endereço do meteoro
    PUSH R10
    PUSH R11
    MOV R7, [R6]                              ; linha
    MOV R8, [R6+2]                            ; coluna
    MOV R11, [R6+4]                           ; tipo
    MOV R10, METEORO_BOM
    CMP R10, R11
    JZ bom_dm                                 ; se o meteoro é bom
    MOV R10, METEORO_MAU
    CMP R10, R11
    JZ mau_dm                                 ; se o meteoro é mau
    JMP end_dm
bom_dm:
    CALL desenha_meteoroB                     ; formato meteoro bom
    JMP end_dm
mau_dm:
    CALL desenha_meteoroM                     ; formato meteoro mau
end_dm: 
    POP R11
    POP R10
    POP R6
    RET

;#############################################################################################################################
;A rotina recebe um endereço de um meteoro e apaga o do ecran
;#############################################################################################################################

apaga_meteoro:
    PUSH R6                                   ;  endereço meteoro                             
    PUSH R10
    PUSH R11
    MOV R11, [R6+4]                           ; tipo meteoro
    MOV R10, METEORO_BOM
    CMP R10, R11
    JZ bom_am                                 ; meteoro bom
    MOV R10, METEORO_MAU
    CMP R10, R11
    JZ mau_am                                 ; meteoro mau
    JMP end_am
bom_am:
    CALL apaga_meteoroB                       ; formato meteoro bom
    JMP end_am
mau_am:
    CALL apaga_meteoroM                       ; formato meteoro mau
end_am: 
    POP R11
    POP R10
    POP R6
    RET


;#############################################################################################################################
;A rotina move o rover um pixel para a esquerda desde que este nao saia fora das margens do ecran
;#############################################################################################################################

move_rover_esquerda:
    PUSH R6                               
    MOV R6, [rover]                           ; pixel referencia Rover
    CMP R6, 0                                 ;
    JZ stop_mre                               ; se pixel igual a 0, nao faz nada
    CALL apaga_rover                          ; apaga o atual desenhoi do rover
    SUB R6, 1                                 ; move o um pixel para a esquerda
    MOV [rover], R6                           ;
    CALL desenha_rover                        ; desenha o Rover na nova posicao 
stop_mre:
    POP R6                                
    RET                                   

;#############################################################################################################################
;A rotina move o rover um pixel para a direita desde que este nao saia fora das margens do ecran
;#############################################################################################################################

move_rover_direita:
    PUSH R6                               
    PUSH R7                               
    MOV R6, [rover]                           ; obtem o pixel atual do rover
    MOV R7, NUM_COLUNAS                       ; define o limite maximo do ecran
    SUB R7, 4                                 ; //         //                //
    SUB R7, 4                                 ; //         //                //
    CMP R6, R7                                ;
    JZ stop_mrd                               ; pixel fim ecran, nao faz nada  
    CALL apaga_rover                          ; apaga a posicao atual Rover
    ADD R6, 1                                 ; move o Rover um pixel para a direita
    MOV [rover], R6                           ;
    CALL desenha_rover                        ; desenha o Rover na nova posicao 
stop_mrd:
    POP R7                                
    POP R6
    RET                                   

;#############################################################################################################################
;Move o meteoro um pixel para baixo, caso o proximo movimento retire o meteoro totalmente do ecran entao o meteoro 
;passa para o topo do ecran 
;#############################################################################################################################

movimento_meteoro:
    PUSH R7
    PUSH R8
    PUSH R10
    PUSH R11
    MOV R7, [R6]                              ; linha meteoro a mover
    MOV R8, [R6+2]                            ; coluna metero  a mover
    CALL apaga_meteoro                        ; apaga meteoro atual
    ADD R7, 1                                 ; meteoro desce um pixel
    MOV [R6], R7                              ;
    MOV R8, NUM_LINHAS                        ;
    CMP R7, R8                                ;
    JGE volta_mv                              ; caso o meteoro saia do ecran cria um novo meteoro
    JMP end_mv
volta_mv:
    MOV R10, METEORO_INATIVO                  ;
    MOV [R6+4], R10                           ; desativa o meteoro para nao o desenhar
    CALL novo_meteoro                         ; cria um novo meteoro para substiruir o atual
end_mv:
    CALL desenha_meteoro                      ; desenha meteoro nova posicao  
    POP R11
    POP R10
    POP R8
    POP R7
    RET

;#############################################################################################################################
;desenha uma coluna da cor indicada (R9) recebendo um pixel (R7,R8) de partida e quantos pixeis ira desenhar para baixo (R10)
;#############################################################################################################################

desenha_coluna:
    PUSH R7                                   ; linha
    PUSH R8                                   ; coluna
    PUSH R9                                   ; cor
    PUSH R10                                  ; numero pixeis
ciclo_dl:    
    CALL escreve_pixel                        ;
    ADD R7, 1                                 ; passa para o pixel imediatamente abaixo
    SUB R10, 1                                ; reduz a contagem de pixes restantes em um
    CMP R10, 0                                ;
    JNZ ciclo_dl                              ; repete o ciclo enqaunto a conmtagem de pixeis restantes for maior que 0
    POP R10
    POP R9
    POP R8
    POP R7
    RET

;#############################################################################################################################
;Move missil um pixel para cima segundo o cronometro e verificando colisoes, tbm desativa o missil se este chegar ao 
;limite do alcance deste
;#############################################################################################################################

move_missil:
    PUSH R10
    PUSH R11
    MOV R11, [estado+2]                       ; obtem o estado cronometro do missil
    CMP R11, 0                                ;
    JZ end_mm                                 ; se o estado cronometro desativo ignora rotina
    MOV R11, 0                                ; //                 //               //
    MOV [estado+2], R11                       ; reseta estado cronometro missil para 1
    MOV R11, [missil+4]                       ; estado missil
    CMP R11, 1                                ; se ativo(1)
    JNZ end_mm 
checka_missil:
    CALL apaga_missil                    
    MOV R11, ALCANCE_MISSIL          
    MOV R10, [missil]               
    CMP R10, R11                              ; se o missil atinge o alcance maximo
    JNZ nova_pos_missil                  
    MOV R10, 0                                ; //      //      //
    MOV [missil+4], R10                       ; desativa missil(0)
    JMP end_mm
nova_pos_missil:
    MOV R10, [missil]
    SUB R10, 1
    MOV [missil], R10                 
    CALL desenha_missil                       ; desenha o missil na nova posição
    CALL deteta_colisao_missil                ; deteta colisoes
end_mm:
    POP R11
    POP R10
    RET

;#############################################################################################################################
;A rotina desenha o missil na posição que tem guadada na memoria
;#############################################################################################################################

desenha_missil:
    PUSH R9
    MOV R9, [missil+4]                        ;
    CMP R9, 1                                 ;
    JNZ end_dm2
    MOV R9, COR_MISSIL                        ;
    CALL get_missil                           ; devolve formato missil
end_dm2:
    POP R9
    RET

;#############################################################################################################################
;A rotina apaga o missil na posição que tem guardada na memoria
;#############################################################################################################################

apaga_missil:
    PUSH R9
    MOV R9, APAGA_PIXEL                       ;
    CALL get_missil                           ; devolve formato missil
    POP R9
    RET

;#############################################################################################################################
;Obtem o formato do missil
;#############################################################################################################################

get_missil:
    PUSH R6                               
    PUSH R7                               
    PUSH R8                               
    MOV R6, missil                        
    MOV R7, [R6]                              ; linha 
    ADD R6, 2                                 ; coluna
    MOV R8, [R6]                          
    CALL escreve_pixel                        
    POP R8
    POP R7 
    POP R6
    RET 

;#############################################################################################################################
;A rotina dispara um novo missil se nao houver nenhum atualmente  ativo e diminui a energia em 5 
;#############################################################################################################################

fire_in_the_hole:
    PUSH R1
    PUSH R7 
    PUSH R10
    MOV R10, [missil+4]                       ; estado missil
    MOV R7, ALCANCE_MISSIL                    ; //              //             // 
    CMP R10, 1                                ; missil esta ativo(1)
    JZ end_fith  
    MOV R7, [rover]                           ; //                //               //
    ADD R7, 2                                 ; obtem a coluna central do rover atual
    MOV R10, missil                       
    ADD R10, 2                            
    MOV [R10], R7                         
    MOV R7, 27                                ; obtem a linha inicial do missil
    MOV [missil], R7                     
    MOV R7, 1                            
    MOV [missil+4], R7
    MOV R1, 1
    MOV [DEF_SOM_START], R1                    
    CALL desenha_missil                   
    MOV R10, [C]                              ; //       //         //
    SUB R10, 5                                ; //       //         //
    MOV [C], R10                              ; diminui a energia em 5

end_fith:
    POP R10
    POP R7
    POP R1
    RET

;#############################################################################################################################
;Inicia os valores em memoria dos meteoros para evitar conflitos
;#############################################################################################################################

start_meteoros:
    PUSH R6
    PUSH R7
    PUSH R8
    MOV R7, NUM_METEOROS
    MOV R6, meteoros
ciclo_sm:
    MOV R8, 1                                 ;
    MOV [R6+2], R8                            ;
    MOV R8, METEORO_NEXISTE                   ; define as colunas em 1 e o estado em nao existente
    MOV [R6+4], R8
    SUB R7, 1
    ADD R6, 6
    CMP R7, 0                                 ; repete o ciclo para todos os meteoros
    JNZ ciclo_sm
    POP R8
    POP R7
    POP R6
    RET


;#############################################################################################################################
;Começa um novo meteoro com um novo tipo (bom ou mau) e numa posição livre
;#############################################################################################################################


start_novo_meteoro:
    PUSH R6 
    PUSH R10
    PUSH R11
    MOV R10, [spawn_meteoros+2]               ; numero meteoros ativados
    MOV R11, NUM_METEOROS                     ; //                 //                 //
    CMP R10, R11                              ; se ja foram todos ativados ignora rotina
    JZ end_snm

    MOV R10, [spawn_meteoros]                 ; cronometro cria meteoros
    MOV R11, CRONOMETRO_SPAWN                 ; temporização do cronometro
    CMP R10, R11                              ; //                    //                        //    
    JLT end_snm                               ; se a temporização foi atingida cria um novo meteoro 
true_snm: ;cria novo meteoro
    MOV R6, meteoros                          ; endereço memoria meteoros
    MOV R11, [spawn_meteoros+2]               ; numero atual de meteoros existentes
    MOV R10, 6
    MUL R11, R10                              ; //                     //                   //          
    ADD R6, R11                               ; move o ponteiro para a memoria do novo meteoro
    CALL novo_meteoro                         ; cria um novo meteoro na posicao atual
    MOV R11, [spawn_meteoros+2]
    ADD R11, 1
    MOV [spawn_meteoros+2], R11
    MOV R11, 0                                ; //            //          //
    MOV [spawn_meteoros], R11                 ; reseta o cronometro meteoros
end_snm:
    POP R11
    POP R10
    POP R6
    RET
   
;#############################################################################################################################
;A rotina obtem de forma pseudo_aleatoria o tipo do meteoro (75% mau, 25% bom) e guarda o valor obtido em R8
;#############################################################################################################################

get_meteoro_tipo:
    PUSH R7
    MOV R7, [random]
    CMP R7, 1                                
    JLE tipo_b
tipo_m:
    MOV R8, METEORO_MAU
    JMP end_gmt
tipo_b:
    MOV R8, METEORO_BOM
end_gmt:
    POP R7
    RET

;#############################################################################################################################
;A rotina cria um novo meteoro no endereço que recebe, numa posição livre, na linha 0 e com um novo tipo random
;#############################################################################################################################
novo_meteoro:
    PUSH R6                                   ; endereço meteoro
    PUSH R8                              
    MOV R8, 0
    MOV [R6], R8
    CALL get_nova_pos
    MOV [R6+2], R8
    CALL get_meteoro_tipo
    MOV [R6+4], R8
    POP R8
    POP R6
    RET


;#############################################################################################################################
;A rotina move o meteoro, caso este sai do ecran destroi o e cria um novo, a rotina tbm verifica colisoes meteoro-rover
;#############################################################################################################################

move_meteoros:
    PUSH R6
    PUSH R11
    MOV R6, [estado]                          ; verifiva o estado do cronometro meteoros 
    CMP R6, 0                                 ; //                           //                         // 
    JZ stop_mm                                ; se o cronometro nao deu uma volta completa ignora a rotina
    MOV R6, 0                                       
    MOV [estado], R6                          ; reseta o estado
    MOV R6, meteoros                          ; obtem o endereço dos meteoros
    MOV R11, [spawn_meteoros+2]               ; obtem o numero atual de meteoros ativos
ciclo_mm:
    CALL movimento_meteoro
    CALL deteta_colisao_rover                 ; procura por colisoes com o rover
    ADD R6, 6
    SUB R11, 1
    CMP R11, 0
    JNZ ciclo_mm
stop_mm:    
    POP R11
    POP R6
    RET

;#############################################################################################################################
;A rotina devolve, em R8, uma das 11 posiçoes posiveis desde que tenha espaço livre
;#############################################################################################################################

get_nova_pos:
    PUSH R7
    PUSH R9
    PUSH R10                                  ; numero final
    PUSH R11
get_random_pos:;obtem um numero random entre 0-10
    MOV R9, meteoros
    MOV R10, [random]                         ; //             //              //                  
    MOV R11, [random]                         ; obtendo dois numeros random entre 0-7
    ADD R10, R11                              ; a sua soma da um numero entre 0-14 (maior que o limite)      
    MOV R11, 10                               ; //                //                 //
    CMP R10, R11                              ; Sse o numero rebentar(>10) executa se GT_grp para obter um numero menor
    JLT get_pos_gnp                           ;
    JZ excessao_gnp                           ; excessao(10)
GT_gnp:;se o numero é maior que o limite(10)
    MOV R11, [random]                         ; obtem se outro numero random 0-7
    SUB R10, R11                              ; remove random a numero ficando com um valor entre (7-14)
    MOV R11, 10                               ;   
    CMP R10, R11                              ;
    JGT GT_gnp                                ; se numero ainda é maior retorna a GT_grp
    JZ excessao_gnp                           ;
get_pos_gnp:
    MOV R11, 6                                ;
    MUL R10, R11                              ; multiplica random num (0-9) por 6 para obter posicao
    JMP pre_check_empty
excessao_gnp:
    MOV R10, 59                               ; por limitaçoes de tamanho de ecran a excessao(9) assume a coluna 54
pre_check_empty:
    MOV R11, NUM_METEOROS                     ; numero meteoros a verificar
    MOV R7, meteoros
check_empty_colum:;verifica se a coluna ja tem meteoro
    MOV R9, [R7+2]                            ; meteoro a ser verificado                    
    CMP R9, R10                          
    JZ check_space_colum                      ; obtem novo random se posicao ja ocupada
    JMP check_next
check_space_colum:                            ; enquanto nao verificar todos os meteoros repete ciclo
    MOV R10, [R7+4]                           ;   
    MOV R9, 12
    CMP R10, R9                                           
    JLT get_random_pos                                               
check_next:
    ADD R7, 6                                 ; passa proximo meteoro
    SUB R11, 1                                ;
    CMP R11, 0                                ; //                            //                                 //
    JNZ check_empty_colum                     ; enquanto nao verificar todso os meteoros crepete check_empty_coluna
end_grp:
    MOV R8, R10 
    POP R11
    POP R10
    POP R9
    POP R7
    RET

;#############################################################################################################################
;A rotina procura por colisoes de missil-meteoros
;#############################################################################################################################

deteta_colisao_missil:
    PUSH R6
    PUSH R7 
    PUSH R10
    PUSH R11
    MOV R11, [missil+4]                       ; //                    //                    //
    CMP R11, 1                                ; apenas executa a rotina se o missil esta ativo
    JNZ end_dcm
    MOV R6, meteoros                          ;
    SUB R6, 6
    MOV R10, [spawn_meteoros+2]               ;
    ADD R10, 1
next_ciclo:
    SUB R10, 1                                ; //           //             //
    CMP R10, 0                                ; Numero de meteoros por checkar
    JZ end_dcm
    ADD R6, 6                                 ; Passa ao endereço do proximo meteoro
ciclo_dcm:
    MOV R7, [missil]                          ; linha missil
    MOV R11, [R6]                             ;
    CMP R7, R11                               ; //                   //                       // 
    JZ check_coluna_1_dcm                     ; se a linha do meteoro atual é igual a do missil
    JGT check_linha_2_dcm                     ; se a linha é maior que a do missil
    JMP next_ciclo
check_linha_2_dcm:
    ADD R11, 4
    CMP R7, R11                               ; se a o missil esta numa linha dentro do meteoro
    JLE check_coluna_1_dcm                    ;
    JMP next_ciclo
check_coluna_1_dcm:
    MOV R7, [missil+2]                        ; linha missil
    MOV R11, [R6+2]                           ;
    CMP R7, R11                               ; //                   //                       // 
    JZ check_coluna_2_dcm                     ; se a linha do meteoro atual é igual a do missil
    JGT check_coluna_2_dcm                    ; se a linha é maior que a do missil
    JMP next_ciclo
check_coluna_2_dcm:
    ADD R11, 4
    CMP R7, R11                               ; se o missil esta numa linha dentro do meteoro
    JLE check_meteoro_dcm                     ;
    JMP next_ciclo
check_meteoro_dcm:
    MOV R11, 0 
    CALL apaga_missil
    CALL colisao_missil
    MOV R8, 0                                 ; 
    MOV [missil+4], R8                        ; desativa missil(0)
end_dcm:
    POP R11
    POP R10
    POP R7
    POP R6
    RET 

;#############################################################################################################################
;A rotina decide o que fazer na colisao ocorrida
;#############################################################################################################################

colisao_missil:
    PUSH R1
    PUSH R7
    PUSH R8
    MOV R7, [R6]
    MOV R8, [R6+2]
    CALL inverse_dst
    MOV [nv_ln], R7                           ; armazenamento das variáveis de referencia da localização do item destruido
    MOV [nv_cl], R8                           ; 
    CALL apaga_meteoro                        ; apaga o meteoro atual
    MOV R7, [R6+4]                            ; obtem tipo meteoro atual
    MOV R8, METEORO_BOM            
    CMP R7, R8          
    JZ meteoro_bom_dm
    MOV R8, METEORO_MAU
    CMP R7, R8
    JZ meteoro_mau_dm
    JMP end_dm3
meteoro_bom_dm:;se colide com meteoro bom
    CALL novo_meteoro                         ; substitui esse meteoro por um novo
    MOV R1, 0500H                             ; valor para comporação futura (temporização do efeito de destruição)
    MOV R7, [nv_ln]                           ; valores de referncia para desenho da destruição
    MOV R8, [nv_cl]                           ; 
    MOV [destruction], R1                     
    MOV R1, 4                                 ; reprodução do efeito de som da destruição
    MOV [DEF_SOM_START], R1
    CALL desennha_nuvem
    JMP end_dm3
meteoro_mau_dm:
    MOV R7, [C]                               ; //          //          //
    MOV R8, 5                                 ; //          //          //
    ADD R7, R8                                ; //          //          //
    MOV [C], R7                               ; Incrementa a energia em 25
    CALL novo_meteoro                         ; cira um novo meteoro
    MOV R1, 0500H                             ; //          //          //
    MOV R7, [nv_ln]                           ; //          //          //
    MOV R8, [nv_cl]                           ; //          //          //        
    MOV [destruction], R1                     
    MOV R1, 4                                 ; //          //          //
    MOV [DEF_SOM_START], R1
    CALL desennha_nuvem
end_dm3:
    POP R8
    POP R7
    POP R1
    RET

;#############################################################################################################################
;A rotina deteta colisoes com o rover-meteoros
;#############################################################################################################################

deteta_colisao_rover:
    PUSH R1
    PUSH R7
    PUSH R8
    PUSH R10
    PUSH R11
    MOV R10, [R6]
    MOV R11, 23                               ; //                                   //                                       //
    CMP R10, R11                              ; //                                   //                                       //                   
    JLT end_dcr                               ; apenas executa a rotina se o meteoro esta nas linhas em que partilha com o rover
    MOV R10, [R6+2]                           ; coluna
    MOV R11, [rover]                         
    SUB R11, 4                                ;
    CMP R10, R11                              ;
    JLT end_dcr                               ;
    ADD R11, 7                                ;
    ADD R11, 1                                ; 
    CMP R10,R11                               ;
    JGT end_dcr                               ; verifica se esse meteoro se encontra numa margem de 4 pixeis para a frente ou para tras do rover
    MOV R10,[R6+4]
    MOV R11, METEORO_BOM
    CMP R10, R11
    JZ meteoro_bom_dcr
    MOV R11, METEORO_MAU
    CMP R10, R11
    JZ meteoro_mau_dcr
    JMP end_dcr  
meteoro_bom_dcr:; se a colisao for com um meteoro bom
    MOV R7, [R6]
    MOV R8, [R6+2]
    CALL apaga_meteoro                        ; //              //             //
    MOV R1, 5
    MOV [DEF_SOM_START], R1
    CALL novo_meteoro                         ; apaga esse meteoro e cira um novo
    MOV R10, [C]                              ; //         //          //
    MOV R11, 10                               ; //         //          //
    ADD R10, R11                              ; //         //          //
    MOV [C], R10                              ; incrementa a enrgia em 10
    JMP end_dcr
meteoro_mau_dcr:; caso a colisao seja com um mau meteoro
    CALL end_dcrt                             ; termina o programa com a mensagem game over
end_dcr:
    POP R11
    POP R10
    POP R8
    POP R7
    POP R1
    RET

;#############################################################################################################################
;A rotina escreve o pixel com os seguintes parametros:
;#############################################################################################################################


escreve_pixel:
	MOV  [DEF_LINHA], R7		              ; seleciona a linha
	MOV  [DEF_COLUNA], R8		              ; seleciona a coluna
	MOV  [DEF_PIXEL], R9		              ; altera a cor do pixel na linha e coluna já selecionadas
	RET

;#############################################################################################################################
;A rotina que escreve a nuvem após uma colisão e apaga-a com um atraso criado pela variavel armazenada em destruction
;#############################################################################################################################

nuvem:
    PUSH R1
    PUSH R7
    PUSH R8
    MOV R1, [destruction]                     ; se a variável de temporização for nula não há nuvem por isso salta a rotina
    CMP R1, 0
    JZ acaba_nv                               ; se a mesma variável for superior a 0 então subtrai a mesma 1 
    SUB R1, 1
    MOV [destruction], R1
    CMP R1, 0                                 ; se a subtração tiver resultado 0 então apago a nuvem
    JNZ acaba_nv
    MOV R7, [nv_ln]                           ; coordenadas de localização da nuvem 
    MOV R8, [nv_cl]                           ;
    CALL apaga_nuvem
acaba_nv:
    POP R8
    POP R7
    POP R1
    RET

;##############################################################################################################################
;Desenha/Apaga-> são duas rotinas que tem com função respetivamente apagar e desenhar a nuvem
;###############################################################################################################################

desennha_nuvem:
    PUSH R9
    MOV R9, COR_NUVEM                         ; cor da nuvem
    CALL formato_nuvem
    POP R9
    RET

apaga_nuvem:
    PUSH R9
    MOV R9, APAGA_PIXEL                       ; se cor para apagar a mesma
    CALL formato_nuvem
    POP R9
    RET

;###############################################################################################################################
;esta rotina apaga a nuvem de destruição se esta não tiver sido apagada antes de ser criada outra seguinte 
;###############################################################################################################################

inverse_dst:
    PUSH R1
    PUSH R7
    PUSH R8
    MOV R1, [destruction]                     ; verifica se há nuvem de destruição
    CMP R1, 0
    JZ end_inv
    MOV R7, [nv_ln]                           ; se existir apaga a mesma
    MOV R8, [nv_cl]
    CALL apaga_nuvem
end_inv:
    POP R8
    POP R7
    POP R1
    RET