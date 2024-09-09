#lang racket
(require 2htdp/universe)
(require 2htdp/image)

; Spielfeldparameter
(define GRID-SIZE 15)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds

; Schlange, Initialzustand
(define INITIAL-SNAKE (list (list 7 7)))  ; Startet in der Mitte
(define INITIAL-DIRECTION 'right)         ; Anfangs bewegt sich die Schlange nach rechts
(define INITIAL-FOOD (list (random GRID-SIZE) (random GRID-SIZE)))        ; Das Futter wird zufällig platziert
(define INITIAL-SCORE 0)                  ; Initialer Punktestand

; Initialer Zustand des Spiels: (Schlange, Richtung, Futter, Punktestand)
(define INITIAL-STATE (list INITIAL-SNAKE INITIAL-DIRECTION INITIAL-FOOD INITIAL-SCORE))

; Funktion zum Zeichnen des Gitternetzes
(define (draw-grid scene)
  (foldl
   (lambda (i scene)
     (let ([line-x (line 0 (* HEIGHT 2) "black")]   ; Vertikale Linien
           [line-y (line (* WIDTH 2) 0 "black")])   ; Horizontale Linien
       (place-image line-x (* i CELL-SIZE) 0
                    (place-image line-y 0 (* i CELL-SIZE) scene))))
   scene
   (range (+ 1 GRID-SIZE))))  ; Zeichnet das Gitter inklusive der Randlinien

; Zeichnet eine Zelle mit einer bestimmten Farbe
(define (draw-cell x y color)
  (place-image (rectangle CELL-SIZE CELL-SIZE "solid" color)
               (* x CELL-SIZE)
               (* y CELL-SIZE)
               (empty-scene WIDTH HEIGHT)))

; Zeichnet die Schlange
(define (draw-snake snake scene)
  (foldl
   (lambda (pos image)
     (let ([x (first pos)]
           [y (second pos)])
       (place-image (rectangle CELL-SIZE CELL-SIZE "solid" "green") 
                    (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                    (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                    image)))
   scene
   snake))

; Zeichnet das Futter
(define (draw-food food scene)
  (let ([x (first food)]
        [y (second food)])
    (place-image (rectangle CELL-SIZE CELL-SIZE "solid" "red")
                 (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                 (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                 scene)))

; Zeichnet den Punktestand
(define (draw-score score scene)
  (place-image (text (format "Score: ~a" score) 20 "blue")
               (+ CELL-SIZE 10) (/ CELL-SIZE 2)
               scene))

; Zeichnet den gesamten Spielzustand
(define (draw-world state)
  (let ([snake (first state)]
        [food (third state)]
        [score (fourth state)])
    (draw-score score
                (draw-food food
                           (draw-snake snake
                                       (draw-grid (empty-scene WIDTH HEIGHT)))))))

; Bewegt die Schlange basierend auf der aktuellen Richtung
(define (move-snake snake direction)
  (let ([head (first snake)])
    (let* ([new-head (cond
                       [(eq? direction 'up)    (list (first head) (sub1 (second head)))]
                       [(eq? direction 'down)  (list (first head) (add1 (second head)))]
                       [(eq? direction 'left)  (list (sub1 (first head)) (second head))]
                       [(eq? direction 'right) (list (add1 (first head)) (second head))])]
           [new-snake (cons new-head (take snake (sub1 (length snake))))])
      new-snake)))

; Hilfsfunktion: Gibt die Koordinaten der Schlange in der Konsole aus
(define (print-snake-coordinates snake)
  (for-each (lambda (segment)
              (printf "Position Schlange: ~a\n" segment))
            snake))

; Berechnet den nächsten Zustand des Spiels nach einem Tick
(define (tock state)
  (let* ([snake (first state)]
         [direction (second state)]
         [food (third state)]
         [score (fourth state)]
         [new-snake (move-snake snake direction)]
         [new-food (if (equal? (first new-snake) food)
                       (list (random GRID-SIZE) (random GRID-SIZE))
                       food)]
         [new-score (if (equal? (first new-snake) food)
                        (+ score 1)
                        score)])
    ; Ruft die Hilfsfunktion auf, um die Koordinaten auszugeben
    (print-snake-coordinates new-snake)
    (list new-snake direction new-food new-score)))

; Bewegt die Schlange basierend auf Tasteneingaben
(define (move state key)
  (let ([snake (first state)]
        [direction (second state)])
    (cond
      [(key=? key "up")    (list snake 'up (third state) (fourth state))]
      [(key=? key "down")  (list snake 'down (third state) (fourth state))]
      [(key=? key "left")  (list snake 'left (third state) (fourth state))]
      [(key=? key "right") (list snake 'right (third state) (fourth state))]
      [else state])))

; Stopp-Bedingung: Beendet das Spiel, wenn die Schlange aus dem Spielfeld läuft,
; sich selbst berührt oder 10 Punkte erreicht wurden.
(define (exit state)
  (let ([snake (first state)]
        [score (fourth state)])
    (or (out-of-bounds? (first snake))  ; Schlange außerhalb des Spielfelds
        (collision? snake)              ; Schlange kollidiert mit sich selbst
        (>= score 10))))                ; Punktestand erreicht oder überschritten 10 Punkte


; Überprüft, ob die Schlange außerhalb des Spielfelds ist
(define (out-of-bounds? pos)
  (or (< (first pos) 0)
      (>= (first pos) GRID-SIZE)
      (< (second pos) 0)
      (>= (second pos) GRID-SIZE)))

; Überprüft, ob die Schlange mit sich selbst kollidiert
(define (collision? snake)
  (let ([head (first snake)]
        [tail (rest snake)])
    (member head tail)))

; Starte das Spiel
(define (main)
  (big-bang INITIAL-STATE
    [to-draw draw-world]
    [on-tick tock 0.5]  ; Geschwindigkeit des Spiels (Ticks pro Sekunde)
    [on-key move]
    [stop-when exit]))

(main)
