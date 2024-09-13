#lang racket
(require 2htdp/universe)
(require test-engine/racket-tests)

; Struct-Elemente
(define-struct item [type x y] #:prefab)
(define-struct snake [coordinates color status direction velocity score banana] #:prefab)

; Startzustand des Universe
(define LIST-WORLDS-INITIAL '())
(define LIST-SNAKES-INITIAL '())
(define LIST-FRUITS-INITIAL '())
(define TIMER-INITIAL 1080)
(define TICK-VALUE 1/6)

(define SNAKE1 (snake (list (list 1 0) (list 0 0)) "green" "solid" 'right 1 0 0))
(define SNAKE2 (snake (list (list 23 24) (list 24 24)) "blue" "solid" 'left 1 0 0))
(define FRUIT1 (item 'apple 18 17))

(define UNIVERSE (list LIST-WORLDS-INITIAL (list SNAKE1 SNAKE2) (list FRUIT1) TIMER-INITIAL))

;; Maximale Anzahl an Spieler
(define NUM_PLAYERS 2)

; Konstanten für das Spielfeld
(define GRID-SIZE 25)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds

(define PLAYING "playing")
(define WAITING "waiting")
(define WIN "win")
(define LOOSE "loose")
(define REJECTED "rejected")
(define TIE "tie")


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
  (list (current-snakes univ) (current-fruits univ) (timer univ) PLAYING))

(define (waiting-mode univ)
  (list (current-snakes univ) (current-fruits univ) (timer univ) WAITING))

(define (win-mode univ)
  (list (current-snakes univ) (current-fruits univ) (timer univ) WIN))

(define (loose-mode univ)
  (list (current-snakes univ) (current-fruits univ) (timer univ) LOOSE))

(define (tie-mode univ)
  (list (current-snakes univ) (current-fruits univ) (timer univ) TIE))

; Hilfsfunktion fürs Ausgeben der Schlangen
(define (first-snake univ)
  (first (current-snakes univ)))

(define (second-snake univ)
  (second (current-snakes univ)))

;;Fügt eine neue Welt hinzu 
(define (add-world univ wrld)
  (cond 
    ;;Maximale Anzahl an Spielern erreicht
    ;; --> Weise diese Welt ab
    [(= (length (current-worlds univ)) NUM_PLAYERS)
     (make-bundle univ
                  (list (make-mail wrld '('() '() 0 REJECTED))) ;Weltzustand mit ablehnendem Zustand
                  '())]

    ;;Maximale Anzahl an Spielern mit dieser Welt erreicht
    ;; --> Füge die Welt zu den bekannten hinzu
    ;; --> Starte das Spiel
    [(= (length (current-worlds univ)) (- NUM_PLAYERS 1))
     (local ((define UNIV (list (append (current-worlds univ) (list wrld)) (current-snakes univ) (current-fruits univ) (timer univ))))
       (make-bundle UNIV
                    (list (make-mail wrld (information-to-draw univ)))
                    '()))]

         
    ;;Maximale Anzahl an Spielern noch nicht erreicht
    ;; --> Füge die Welt zu den bekannten hinzu
    [(= (length (current-worlds univ)) (- NUM_PLAYERS 2))
     (local ((define UNIV (list (append (current-worlds univ) (list wrld)) (current-snakes univ) (current-fruits univ) (timer univ))))
       (make-bundle UNIV
                    (list (make-mail wrld (waiting-mode univ)))
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
         (snake-velocity snake-input) (snake-score snake-input) (snake-banana snake-input)))



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
         [fruits (extract-fruit-type-coordinates (current-fruits state))]  
         [score (snake-score snake-input)]
         [banana (snake-banana snake-input)]
         
         ; Berechne den neuen Kopf der Schlange, bevor die Bewegung stattfindet
         [new-head (cond
                     [(eq? direction 'up)    (list (first (first snake_coordinates)) (modulo (sub1 (second (first snake_coordinates))) GRID-SIZE))]
                     [(eq? direction 'down)  (list (first (first snake_coordinates)) (modulo (add1 (second (first snake_coordinates))) GRID-SIZE))]
                     [(eq? direction 'left)  (list (modulo (sub1 (first (first snake_coordinates))) GRID-SIZE) (second (first snake_coordinates)))]
                     [(eq? direction 'right) (list (modulo (add1 (first (first snake_coordinates))) GRID-SIZE) (second (first snake_coordinates)))])]
         
         ; Überprüfe, ob der neue Kopf auf dem Futter ist
         [ate-apple? (and (member new-head fruits) (eq? 'apple (list-ref fruits (sub1 (index-of fruits new-head)))))]
         [ate-banana? (and (member new-head fruits) (eq? 'banana (list-ref fruits (sub1 (index-of fruits new-head)))))]
         [new-score (if ate-apple? (add1 score) score)]  ; Punkte erhöhen, wenn Futter gegessen wurde
         [new-banana (if ate-banana? (add1 banana) banana)]
         [new-snake (move-snake snake-input direction ate-apple?)])  ; Schlange wächst nur, wenn Futter gegessen wurde
    (snake new-snake (snake-color snake-input) (snake-status snake-input) (snake-direction snake-input) (snake-velocity snake-input) new-score new-banana))) ;Inventory muss ausgebessert werden



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
         [fruits (extract-fruit-type-coordinates (current-fruits state))] ;fruits als Liste
         [forbidden (append (snake-coordinates snake1)
                            (snake-coordinates snake2))] ;verbietet die Felder der Schlange und das Feld direkt vor dem Kopf
         [ate-food? (or (member head1 fruits) (member head2 fruits))]
         [who-ate-food (if ate-food? (if (member head1 fruits) head1 head2) 'rejected)])
    (if ate-food?
        (new-fruit fruits-str (item (list-ref fruits (sub1 (index-of fruits who-ate-food)))
                                    (first who-ate-food)
                                    (second who-ate-food)) forbidden)
        (current-fruits state))))

; entfernt die gegessene Frucht und platziert 1-2 neue
(define (new-fruit fruits fruit forbidden-fields)
  (append (create-fruit fruits (item-type fruit) forbidden-fields) (remove fruit fruits)))
    

(define (create-fruit fruits type forbidden-fields)
  (let* ([randnum (random 4)]
         [x1 (first (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [y1 (second (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [x2 (first (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [y2 (second (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields))]
         [fruit-choices (list
                         (list (item 'apple x1 y1))
                         (list (item 'banana x1 y1))
                         (list (item 'apple x1 y1) (item 'apple x2 y2))
                         (list (item 'apple x1 y1) (item 'banana x2 y2)))])
    (list-ref fruit-choices randnum)))

; verhindert das Spawnen auf der Schlange und auf Früchten (in der World müssen Früchte zuerst gezeichnet werden)
(define (correct-random fruits coordinates forbidden-fields)
  (let ([ext (extract-fruit-type-coordinates fruits)])
    (if (or (member coordinates ext) (member coordinates forbidden-fields)) (correct-random fruits (list (random GRID-SIZE) (random GRID-SIZE)) forbidden-fields) coordinates)))


; gibt Frucht als Liste zurück
(define (extract-fruit-type-coordinates fruit-list)
  (foldl (lambda (fruit current-list)
           (append current-list (list (item-type fruit) (list (item-x fruit) (item-y fruit)))))
         '()
         fruit-list))


;TickHandler
(define (tick-handler univ)
  (cond [(= (length (current-worlds univ)) NUM_PLAYERS)

         ; Überprüfen, ob es Kollisionen gab
         (cond[(eq? (check-all-collisions (first-snake univ) (second-snake univ)) #t)
               ; Überprüfen, wer mit wem kollidiert ist
               (cond
                 [(and (check-collision (second-snake univ) (first-snake univ)) (check-collision (first-snake univ) (second-snake univ))) (make-bundle univ (list (make-mail (first(current-worlds univ)) (loose-mode univ))
                                                                                                                                                                  (make-mail (second(current-worlds univ)) (loose-mode univ))) '())]
                 [(check-collision (first-snake univ) (second-snake univ)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (loose-mode univ))
                                                                                                   (make-mail (second(current-worlds univ)) (win-mode univ))) '())]
                 [(check-collision (second-snake univ) (first-snake univ)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (win-mode univ))
                                                                                                   (make-mail (second(current-worlds univ)) (loose-mode univ))) '())]
                 [(check-self-collision (first-snake univ)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (loose-mode univ))
                                                                                    (make-mail (second(current-worlds univ)) (win-mode univ))) '())]
                 [(check-self-collision (second-snake univ)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (win-mode univ))
                                                                                     (make-mail (second(current-worlds univ)) (loose-mode univ))) '())]
                 )
               ]
              [(<= (timer univ) 6) (cond
                                     [(let*(
                                            [snakes (second univ)]
                                            [snake1 (first snakes)]
                                            [snake2 (second snakes)]
                                            [score1 (snake-score snake1)]
                                            [score2 (snake-score snake2)])
                                        (= score1 score2)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (tie-mode univ))
                                                                                   (make-mail (second(current-worlds univ)) (tie-mode univ))) '())]
                                     [(let*(
                                            [snakes (second univ)]
                                            [snake1 (first snakes)]
                                            [snake2 (second snakes)]
                                            [score1 (snake-score snake1)]
                                            [score2 (snake-score snake2)])
                                        (> score1 score2)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (win-mode univ))
                                                                                   (make-mail (second(current-worlds univ)) (loose-mode univ))) '())]
                                     [(let*(
                                            [snakes (second univ)]
                                            [snake1 (first snakes)]
                                            [snake2 (second snakes)]
                                            [score1 (snake-score snake1)]
                                            [score2 (snake-score snake2)])
                                        (< score1 score2)) (make-bundle univ (list (make-mail (first(current-worlds univ)) (loose-mode univ))
                                                                                   (make-mail (second(current-worlds univ)) (win-mode univ))) '())]
                                     )]
              [else

               ;(if (eq? (check-all-collisions (first-snake univ) (second-snake univ)) #t) (printf "Kollision") (printf "")); Konselenausgabe zum debugging
         
               (let*
                   ([snake1 (next-snake-state (first-snake univ) univ)]
                    [snake2 (next-snake-state (second-snake univ) univ)]
                    [fruits (next-fruit-state snake1 snake2 univ)]
                    [time (timer univ)]
                    [univ* (list (current-worlds univ) (list snake1 snake2) fruits (sub1 time))]) ;hier next-Funktionen implementieren, wie next-snakes, next-fruits und next-timer

                 (make-bundle univ*
                              (list (make-mail (first(current-worlds univ)) (information-to-draw univ*))
                                    (make-mail (second(current-worlds univ)) (information-to-draw univ*)))
                              '()))
               ])]
        [else univ]
        ))

;CollisionDetection
;SNAKES->Boolean
; Prüft, ob der Kopf der ersten Schlange in den Koordinaten der zweiten Schlange vorkommt
(define (check-collision snake1 snake2)
  (let ([head1 (first (snake-coordinates snake1))]   ; Kopf der ersten Schlange
        [body2 (snake-coordinates snake2)])           ; Körper der zweiten Schlange
    (not (false? (member head1 body2)))))  ; Wenn der Kopf der ersten Schlange in den Koordinaten der zweiten Schlange auftaucht, gibt es eine Kollision

; Prüft, ob die beiden Schlangen kollidieren
(define (check-snake-collisions snake1 snake2)
  (or (check-collision snake1 snake2)   ; Prüft, ob snake1 mit snake2 kollidiert
      (check-collision snake2 snake1))) ; Prüft, ob snake2 mit snake1 kollidiert

; Prüft, ob eine Schlange mit sich selbst kollidiert (Selbstkollision)
(define (check-self-collision snake)
  (let ([head (first (snake-coordinates snake))]     ; Kopf der Schlange
        [body (rest (snake-coordinates snake))])     ; Restlicher Körper der Schlange
    (not (false? (member head body)))))  ; Wenn der Kopf im Körper auftaucht, gibt es eine Selbstkollision

; Überprüft, ob eine der beiden Schlangen kollidiert (entweder mit der anderen oder mit sich selbst)
(define (check-all-collisions snake1 snake2)
  (or (check-snake-collisions snake1 snake2)  ; Kollidieren die beiden Schlangen miteinander?
      (check-self-collision snake1)           ; Kollidiert snake1 mit sich selbst?
      (check-self-collision snake2)))         ; Kollidiert snake2 mit sich selbst?




;;Erschafft ein Universum
(universe UNIVERSE
          (on-new add-world)
          (on-msg handle-messages)
          (on-tick tick-handler TICK-VALUE))



