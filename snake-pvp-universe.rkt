#lang racket
(require 2htdp/universe)
(require test-engine/racket-tests)

; Struct-Elemente
(define-struct item [type x y] #:prefab)
(define-struct snake [coordinates color status direction velocity score inventory] #:prefab)

; Startzustand des Universe
(define LIST-WORLDS-INITIAL '())
(define LIST-SNAKES-INITIAL '())
(define LIST-FRUITS-INITIAL '())
(define TIMER-INITIAL 300)

(define SNAKE1 (snake (list (list 2 1) (list 2 2)) "green" "solid" 'right 1 0 '(0 0)))
(define SNAKE2 (snake (list (list 13 14) (list 14 14)) "blue" "solid" 'left 1 0 '(0 0)))
(define FRUIT1 (item 'apple 10 10))

(define UNIVERSE (list LIST-WORLDS-INITIAL (list SNAKE1 SNAKE2) (list FRUIT1) TIMER-INITIAL))

;; Maximale Anzahl an Spieler
(define NUM_PLAYERS 2)

; Konstanten für das Spielfeld
(define GRID-SIZE 15)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds


; Gibt eine Liste der iWorlds aus
(define (current-worlds univ)
  (first univ))

; Gibt eine Liste der Schlangen aus
(define (current-snakes univ)
  (second univ))

; Gibt eine Liste der Früchte aus
(define (current-fruits univ)
  (third univ))

; Gibt den Timer aus
(define (timer univ)
  (fourth univ))


; Hilfsfunktion, die alle nötigen Informationen für die Welten in eine Liste verpackt (Snakes, Fruits, Timer)
(define (information-to-draw univ)
  (list (current-snakes univ) (current-fruits univ) (timer univ)))


;(define UNIVERSE (myUniverse (list SNAKE1 SNAKE2) '() 300 'play))

  
;(define UNIV (myUniverse (append (myUniverse-snakes univ) (list WORLD0))))



#|
(define (add-world univ wrld)
  (local ((define UNIV (myUniverse (append (myUniverse-worlds univ) (list wrld)) (myUniverse-items univ) (myUniverse-timer univ))))
    (make-bundle UNIV
                 (list (make-mail (first(myUniverse-worlds UNIV)) 'myMessage))
                 '())))

|#

;;Fügt eine neue Welt hinzu 
(define (add-world univ wrld)
  (cond 
    ;;Maximale Anzahl an Spielern erreicht
    ;; --> Weise diese Welt ab
    [(= (length (current-worlds univ)) NUM_PLAYERS)
     (make-bundle univ
                  (list (make-mail wrld 'rejected))
                  '())]

    #|;;Maximale Anzahl an Spielern mit dieser Welt erreicht
    ;; --> Füge die Welt zu den bekannten hinzu
    ;; --> Starte das Spiel
    [(= (length (current-worlds univ)) (- NUM_PLAYERS 1))
     (local ((define UNIV (list (append (current-worlds univ) (list wrld)) (current-snakes univ) (current-fruits univ) (timer univ))))
       (make-bundle UNIV
                    (list (make-mail wrld (information-to-draw univ)))
                    '()))]|#

         
    ;;Maximale Anzahl an Spielern noch nicht erreicht
    ;; --> Füge die Welt zu den bekannten hinzu
    [(< (length (current-worlds univ)) NUM_PLAYERS)
     (local ((define UNIV (list (append (current-worlds univ) (list wrld)) (current-snakes univ) (current-fruits univ) (timer univ))))
       (make-bundle UNIV
                    (list (make-mail wrld (information-to-draw univ)))
                    '()))]
    ))


; Hilfsfunktion: Gibt die Empfangenden Daten des Keyhandlers aus Konsole aus
(define (print-received-key world key)
  (printf "Debug: Received WorldData: ~a\n Key:~s \n" world key)
  world)

(define (detect-key snake-input a-key snake_direction)
  (snake (snake-coordinates snake-input) (snake-color snake-input) (snake-status snake-input)
         (cond
           [(and (key=? a-key "left") (not (eq? snake_direction 'right))) 'left]
           [(and (key=? a-key "right") (not (eq? snake_direction 'left))) 'right]
           [(and (key=? a-key "up") (not (eq? snake_direction 'down))) 'up]
           [(and (key=? a-key "down") (not (eq? snake_direction 'up))) 'down]
           [else snake_direction]
          )
         (snake-velocity snake-input) (snake-score snake-input) (snake-inventory snake-input)))

;KeyHandler

(define (change univ wrld a-key)
  (let* (
         [worldname (iworld-name wrld)]
         [snakes (second univ)]
         [snake1 (first snakes)]
         [snake2 (second snakes)]
         [direction1 (snake-direction snake1)]
         [direction2 (snake-direction snake2)]
         [food (third univ)])
         
    (cond
      [(eq? worldname (iworld-name (first (current-worlds univ))))
       (let ([new-univ (list (current-worlds univ) (list (detect-key snake1 a-key direction1) snake2) (current-fruits univ) (timer univ))])
         (printf "list1change ~a  \n" new-univ)
         new-univ)]
      [(eq? worldname (iworld-name (second (current-worlds univ))))
       (let ([new-univ (list (current-worlds univ) (list snake1 (detect-key snake2 a-key direction2)) (current-fruits univ) (timer univ))])
         (printf "list2change ~a \n" new-univ)
         new-univ)]
      [else
       (printf "skip ~a \n" univ)
       univ])))


; Message-Handler
(define (handle-messages univ wrld m)
  (print-received-key wrld m)
  (change univ wrld m))


; Berechnet den nächsten Zustand einer Schlange
(define (next-snake-state snake-input state)
  (let* ([snake_coordinates (snake-coordinates snake-input)]
         [direction (snake-direction snake-input)]
         [fruits (extract-fruit-type-coordinates state)]  
         [score (snake-score snake-input)]
         
         ; Berechne den neuen Kopf der Schlange, bevor die Bewegung stattfindet
         [new-head (cond
                     [(eq? direction 'up)    (list (first (first snake_coordinates)) (modulo (sub1 (second (first snake_coordinates))) GRID-SIZE))]
                     [(eq? direction 'down)  (list (first (first snake_coordinates)) (modulo (add1 (second (first snake_coordinates))) GRID-SIZE))]
                     [(eq? direction 'left)  (list (modulo (sub1 (first (first snake_coordinates))) GRID-SIZE) (second (first snake_coordinates)))]
                     [(eq? direction 'right) (list (modulo (add1 (first (first snake_coordinates))) GRID-SIZE) (second (first snake_coordinates)))])]
         
         ; Überprüfe, ob der neue Kopf auf dem Futter ist
         [ate-apple? (and (member new-head fruits) (eq? 'apple (list-ref fruits (sub1 (index-of fruits new-head)))))]
         [new-score (if ate-apple? (+ score 1) score)]  ; Punkte erhöhen, wenn Futter gegessen wurde
         [new-snake (move-snake snake-input direction ate-apple?)])  ; Schlange wächst nur, wenn Futter gegessen wurde
    (snake new-snake (snake-color snake-input) (snake-status snake-input) (snake-direction snake-input) (snake-velocity snake-input) new-score (snake-inventory snake-input)))) ;Inventory muss ausgebessert werden



; Bewegt die Schlange basierend auf der aktuellen Richtung
(define (move-snake snake-input direction grow?)
  (let ([head (first (snake-coordinates snake-input))])
    (let* ([new-head (cond
                       [(eq? direction 'up)    (list (first head) (modulo (sub1 (second head)) GRID-SIZE))]
                       [(eq? direction 'down)  (list (first head) (modulo (add1 (second head)) GRID-SIZE))]
                       [(eq? direction 'left)  (list (modulo (sub1 (first head)) GRID-SIZE) (second head))]
                       [(eq? direction 'right) (list (modulo (add1 (first head)) GRID-SIZE) (second head))])]
           
           ; Falls die Schlange wachsen soll, wird der neue Kopf einfach hinzugefügt,
           ; ansonsten wird der Rest entsprechend angepasst
           [new-snake (if grow?
                          (cons new-head (snake-coordinates snake-input))  ; Schlange wächst
                          (cons new-head (take (snake-coordinates snake-input) (sub1 (length (snake-coordinates snake-input))))))])
      new-snake)))


;Berechnet den nächsten Zustand eines Items
(define (next-fruit-state snake1 snake2 state)
  (let* ([head1 (first (snake-coordinates snake1))]
         [head2 (first (snake-coordinates snake2))]
         [fruits-str (current-fruits state)]
         [fruits (extract-fruit-type-coordinates state)]
         [ate-food? (or (member head1 fruits) (member head2 fruits))]
         [who-ate-food (if ate-food? (if (member head1 fruits) head1 head2) 'rejected)])
    (if ate-food?
        (new-fruit fruits-str (item (list-ref fruits (sub1 (index-of fruits who-ate-food))) (first who-ate-food) (second who-ate-food)))
        (current-fruits state))))

; entfernt die gegessene Frucht und platziert 1-2 neue
(define (new-fruit fruits fruit)
  (append (create-fruit (item-type fruit)) (remove fruit fruits)))
    

(define (create-fruit type)
  (let ([randnum (random 3)]) ; Zufallszahl 1 oder 0 (k.A. wie)
    (if (= randnum 1) (list (item type (random GRID-SIZE) (random GRID-SIZE))) (list (item type (random GRID-SIZE) (random GRID-SIZE)) (item type (random GRID-SIZE) (random GRID-SIZE))))))

; gibt Frucht als Liste zurück
(define (extract-fruit-type-coordinates univ)
  (let ([fruit-list (current-fruits univ)])
    (foldl (lambda (fruit current-list)
             (append current-list (list (item-type fruit) (list (item-x fruit) (item-y fruit)))))
           '()
           fruit-list)))

;TickHandler
(define (tick-handler univ)
  (cond [(= (length (current-worlds univ)) NUM_PLAYERS)
         (let*
            ([snake1 (next-snake-state (first (current-snakes univ)) univ)]
             [snake2 (next-snake-state (second (current-snakes univ)) univ)]
             [fruits (next-fruit-state snake1 snake2 univ)]
             [univ* (list (current-worlds univ) (list snake1 snake2) fruits (timer univ))]) ;hier next-Funktionen implementieren, wie next-snakes, next-fruits und next-timer
         (make-bundle univ*
                      (list (make-mail (first(current-worlds univ)) (information-to-draw univ*))
                            (make-mail (second(current-worlds univ)) (information-to-draw univ*)))
                      '()))
         ]
        [else univ]
        ))


;;Erschafft ein Universum
(universe UNIVERSE
          (on-new add-world)
          (on-msg handle-messages)
          (on-tick tick-handler 0.3))

#|
; UniverseState is [Listof iworld?]
; StopMessage is 'done.
; GoMessage is 'it-is-your-turn.

; Konstanten
(define NUM_PLAYERS 2)
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

(define empty_board UNIVERSE0)

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


|#

;_______________________________________________________________________________
;Funktionen

#|
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
|#

