#lang racket
(require 2htdp/universe)
(require test-engine/racket-tests)

; UniverseState is [Listof iworld?]
; StopMessage is 'done.
; GoMessage is 'it-is-your-turn.

; Konstanten
(define NUM_PLAYERS 2)
(define empty_board  '("" "" "" "" "" "" "" "" ""))
; Spielfeldparameter
(define GRID-SIZE 15)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds

; Schlange, Initialzustand
(define SNAKE1 (list (list (list 7 7)) 'right 'green))
(define SNAKE2 (list (list (list 14 14)) 'left 'blue))
(define INITIAL-SNAKES  (list SNAKE1 SNAKE2))  ; Startet mit nur einem Segment
;(define INITIAL-FOOD (list (random GRID-SIZE) (random GRID-SIZE)))  ; Das Futter wird zufällig platziert
(define INITIAL-FOOD (list 10 10))
(define INITIAL-SCORE 0)                  ; Initialer Punktestand
;(define INITIAL-BANANAS-EATEN 0)          ; Initiale Anzahl gegessener Bananen

; Initialer Zustand des Spiels: (Schlange, Richtung, Futter, Banane, Punktestand, Anzahl gegessener Bananen)
(define UNIVERSE0 (list INITIAL-SNAKES INITIAL-FOOD INITIAL-SCORE))
(define iworld1 UNIVERSE0) ; TESTING der WELT


;;Quick accessors for the universe
(define (current_worlds univ)
  (first univ))
(define (world1 univ)
  (first (current_worlds univ)))
(define (world2 univ)
  (second (current_worlds univ)))

(define (current_state univ)
  (second univ))

(define (current_board univ)
  (third univ))


; [Listof iworld?] iworld? -> Result
; add world iw to the universe, when server is in state u
(check-expect
 (add-world '() iworld1)
 (make-bundle (list iworld1)
              (list (make-mail iworld1 'it-is-your-turn))
              '()))

#|(define (add-world univ wrld)
  (local ((define univ* (append univ (list wrld))))
    (make-bundle univ*
                 (list (make-mail (first univ*) 'it-is-your-turn))
                 '())))
|#
; [Listof iworld?] iworld? StopMessage -> Result
; world iw sent message m when server is in state u
(check-expect
 (switch (list iworld1 iworld2) iworld1 'done)
 (make-bundle (list iworld2 iworld1)
              (list (make-mail iworld2 'it-is-your-turn))
              '()))

(define (handle-messages univ wrld m)
  (local ((define univ* (append (rest univ) (list (first univ)))))
    (make-bundle univ*
                 (list (make-mail (first univ*) 'it-is-your-turn))
                 '())))

;;Fügt eine neue Welt hinzu 
(define (add-world univ wrld)
  (cond 
    ;;Maximale Anzahl an Spielern erreicht
    ;; --> Weise diese Welt ab
    [(= (length (current_worlds univ)) NUM_PLAYERS)
     (make-bundle univ
                  (list (make-mail wrld (list 'rejected empty_board)))
                  (list wrld))]
         
    ;;Maximale Anzahl an Spielern mit dieser Welt erreicht
    ;; --> Füge die Welt zu den bekannten hinzu
    ;; --> Starte das Spiel
    [(= (length (current_worlds univ)) (- NUM_PLAYERS 1))
     (make-bundle (list
                   (append (current_worlds univ) (list wrld))
                   'play
                   empty_board)
                  (list (make-mail (world1 univ) (list 'play empty_board))
                        (make-mail wrld   (list 'wait empty_board)))
                  '())]
         
    ;;Maximale Anzahl an Spielern noch nicht erreicht
    ;; --> Füge die Welt zu den bekannten hinzu
    [else 
     (make-bundle (list 
                   (append (current_worlds univ) (list wrld))
                   'wait 
                   empty_board)
                  (list (make-mail wrld (list 'wait empty_board)))
                  '())]))


;World-GO
;(define (world-go w key) w)

; Bewegt die Schlange basierend auf Tasteneingaben
(define (receive w key)
    (change w key))

(check-expect (change UNIVERSE0 "left") '(((((7 7))) right green) ((((14 14))) left blue) (10 10) 0))
(check-expect (change iworld1 "left") '(((((7 7))) right green) ((((14 14))) left blue) (10 10) 0)) ;Test mit falscher Richtung
(check-expect (receive iworld1 "up") '(((((7 7))) up green) ((((14 14))) left blue) (10 10) 0)) ;Test mit korrekter Eingabe
;(equal? (change iworld1 "left") '(((((7 7))) right green) ((((14 14))) left blue) (10 10) 0))
;(equal? (receive iworld1 "up") '(((((7 7))) up green) ((((14 14))) left blue) (10 10) 0)) 

;KeyHandler
(define (change state a-key)
  ;(let ([snake (first(first state))]
  (let* ([snakes (first state)]
       [snake1 (first(first state))]
       [snake2 (second(first state))]
       [snake1pos (first(first(first state)))]
       [snake1dir (second(first(first state)))]
       [snake1col (third(first(first state)))]
       [snake2pos (first(second(first state)))]
       [snake2dir (second(second(first state)))]
       [snake2col (third(second(first state)))]
       [food (second state)]
       [apple1 (first(second state))]
       [apple2 (second(second state))]
       [score (third state)]
       )
    (cond
      [(and (key=? a-key "left") (not (eq? snake1dir 'right)))  (list (list(list snake1pos) 'left snake1col) (list (list snake2pos) snake2dir snake2col) (second state) (third state))]
      [(and (key=? a-key "left") (not (eq? snake2dir 'right)))  (list (list(list snake1pos) snake1dir snake1col) (list (list snake2pos) 'left snake2col) (second state) (third state))]
      [(and (key=? a-key "right") (not (eq? snake1dir 'left)))  (list (list(list snake1pos) 'right snake1col) (list (list snake2pos) snake2dir snake2col) (second state) (third state))]
      [(and (key=? a-key "right") (not (eq? snake2dir 'left)))  (list (list(list snake1pos) snake1pos snake1col) (list (list snake2pos) 'right snake2col) (second state) (third state))]
      [(and (key=? a-key "up") (not (eq? snake1dir 'down)))  (list (list(list snake1pos) 'up snake1col) (list (list snake2pos) snake2dir snake2col) (second state) (third state))]
      [(and (key=? a-key "up") (not (eq? snake2dir 'down)))  (list (list(list snake1pos) snake1dir snake1col) (list (list snake2pos) 'up snake2col) (second state) (third state))]
      [(and (key=? a-key "down") (not (eq? snake1dir 'up)))  (list (list(list snake1pos) 'downs snake1col) (list (list snake2pos) snake2dir snake2col) (second state) (third state))]
      [(and (key=? a-key "down") (not (eq? snake2dir 'up)))  (list (list(list snake1pos) snake1dir snake1col) (list (list snake2pos) 'down snake2col) (second state) (third state))]
      [else state])))

(change UNIVERSE0 "left")
#|
(cond
      [(and (key=? a-key "left") (not (eq? direction1 'right)))  (world-go iworld1 a-key)]
      [(and (key=? a-key "left") (not (eq? direction2 'right)))  (world-go iworld2 a-key)]
      [(and (key=? a-key "right") (not (eq? direction1 'left)))  (world-go iworld1 a-key)]
      [(and (key=? a-key "right") (not (eq? direction2 'left)))  (world-go iworld2 a-key)]
      [(and (key=? a-key "up") (not (eq? direction1 'down)))  (world-go iworld1 a-key)]
      [(and (key=? a-key "up") (not (eq? direction2 'down)))  (world-go iworld2 a-key)]
      [(and (key=? a-key "down") (not (eq? direction1 'up)))  (world-go iworld1 a-key)]
      [(and (key=? a-key "down") (not (eq? direction2 'up)))  (world-go iworld2 a-key)]
      [else w])))
|#

;;Erschafft ein Universum
(universe UNIVERSE0
          (on-new add-world)
          ;          (port 9092)
          (on-msg handle-messages))
;LET
#|
(let* ([snakes (first state)]
       [snake1 (first(first state))]
       [snake2 (second(first state))]
       [snake1pos (first(first(first state)))]
       [snake1dir (second(first(first state)))]
       [snake1col (third(first(first state)))]
       [snake2pos (first(second(first state)))]
       [snake2dir (second(second(first state)))]
       [snake2col (third(second(first state)))]
       [food (second state)]
       [apple1 (first(second state))]
       [apple2 (second(second state))]
       [score (third state)]
       ))
|#

; Set Universe as List

;(list (list(list snake1pos) snake1dir snake1col) (list (list snake2pos) snake2dir snake2col) (second state) (third state))
;_______________________________________________________________________________
;Funktionen

; Hilfsfunktion: Gibt die Koordinaten der Schlange in der Konsole aus
(define (print-snake-coordinates snake)
  (for-each (lambda (segment)
              (printf "Position Schlange: ~a\n" segment))
            snake))

;Hilfsfunktion: Gibt die Koordinaten des Futters in der Konsole aus
(define (print-food-coordinates food)
  (printf "Futter gefressen an Position: ~a\n" food))
;Hilfsfunktion: Gibt die Koordinaten der Bananen in der Konsole aus
(define (print-banana-coordinates banana)
  (printf "Banane gefressen an Position: ~a\n" banana))

; Bewegt die Schlange basierend auf der aktuellen Richtung
(define (move-snake snake direction grow?)
  (let ([head (first snake)])
    (let* ([new-head (cond
                       [(eq? direction 'up)    (list (first head) (modulo (sub1 (second head)) GRID-SIZE))]
                       [(eq? direction 'down)  (list (first head) (modulo (add1 (second head)) GRID-SIZE))]
                       [(eq? direction 'left)  (list (modulo (sub1 (first head)) GRID-SIZE) (second head))]
                       [(eq? direction 'right) (list (modulo (add1 (first head)) GRID-SIZE) (second head))])]
           
           ; Falls die Schlange wachsen soll, wird der neue Kopf einfach hinzugefügt,
           ; ansonsten wird der Rest entsprechend angepasst
           [new-snake (if grow?
                          (cons new-head snake)  ; Schlange wächst
                          (cons new-head (take snake (sub1 (length snake)))))])
      new-snake)))

; Berechnet den nächsten Zustand des Spiels nach einem Tick
(define (tock state)
  (let* ([snake (first state)]
         [direction (second state)]
         [food (third state)]
         [banana (fourth state)]
         [score (fifth state)]
         [bananas-eaten (sixth state)]
         
         ; Berechne den neuen Kopf der Schlange, bevor die Bewegung stattfindet
         [new-head (cond
                     [(eq? direction 'up)    (list (first (first snake)) (modulo (sub1 (second (first snake))) GRID-SIZE))]
                     [(eq? direction 'down)  (list (first (first snake)) (modulo (add1 (second (first snake))) GRID-SIZE))]
                     [(eq? direction 'left)  (list (modulo (sub1 (first (first snake))) GRID-SIZE) (second (first snake)))]
                     [(eq? direction 'right) (list (modulo (add1 (first (first snake))) GRID-SIZE) (second (first snake)))])]
         
         ; Überprüfe, ob der neue Kopf auf dem Futter ist
         [ate-food? (equal? new-head food)]
         [new-food (if ate-food?
                       (list (random GRID-SIZE) (random GRID-SIZE))
                       food)]  ; Neues Futter, wenn gegessen
         [new-score (if ate-food? (+ score 1) score)]  ; Punkte erhöhen, wenn Futter gegessen wurde
         
         ; Überprüfe, ob die Schlange die Banane isst
         [ate-banana? (equal? new-head banana)]
         [new-bananas-eaten (if ate-banana? (+ bananas-eaten 1) bananas-eaten)]
         [new-banana (if ate-banana? (list (random GRID-SIZE) (random GRID-SIZE)) banana)]
         [new-snake (move-snake snake direction ate-food?)])  ; Schlange wächst nur, wenn Futter gegessen wurde

    ; Wenn das Futter gegessen wurde, gib seine Koordinaten aus
    (when ate-food?
      (print-food-coordinates food))
    ; Wenn die Banane gegessen wurde, gib seine Koordinaten aus
    (when ate-banana?
      (print-banana-coordinates banana))

    (print-snake-coordinates new-snake) ; Ruft Hilfsfunktion für Konsolenausgabe auf
    (list new-snake direction new-food new-banana new-score new-bananas-eaten)))

; Bewegt die Schlange basierend auf Tasteneingaben
(define (move state key)
  (let ([snake (first state)]
        [direction (second state)])
    (cond
      [(and (key=? key "up") (not (eq? direction 'down)))
       (list snake 'up (third state) (fourth state) (fifth state) (sixth state))]
      [(and (key=? key "down") (not (eq? direction 'up)))
       (list snake 'down (third state) (fourth state) (fifth state) (sixth state))]
      [(and (key=? key "left") (not (eq? direction 'right)))
       (list snake 'left (third state) (fourth state) (fifth state) (sixth state))]
      [(and (key=? key "right") (not (eq? direction 'left)))
       (list snake 'right (third state) (fourth state) (fifth state) (sixth state))]
      [else state])))

; Stopp-Bedingung: Beendet das Spiel, wenn die Schlange mit sich selbst kollidiert.
(define (exit state)
  (let ([snake (first state)])
    (collision? snake)))

; Überprüft, ob die Schlange mit sich selbst kollidiert
(define (collision? snake)
  (let ([head (first snake)]
        [tail (rest snake)])
    (member head tail)))
