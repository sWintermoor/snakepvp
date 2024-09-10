#lang racket
(require 2htdp/universe)
(require 2htdp/image)

; Spielfeldparameter
(define GRID-SIZE 15)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds

; Schlange, Initialzustand
(define INITIAL-SNAKE (list (list 7 7)))  ; Startet mit nur einem Segment
(define INITIAL-DIRECTION 'right)         ; Anfangs bewegt sich die Schlange nach rechts
(define INITIAL-FOOD (list (random GRID-SIZE) (random GRID-SIZE)))  ; Das Futter wird zufällig platziert
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
    (place-image (circle GRID-SIZE "solid" "red")
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

; Hilfsfunktion: Gibt die Koordinaten der Schlange in der Konsole aus
(define (print-snake-coordinates snake)
  (for-each (lambda (segment)
              (printf "Position Schlange: ~a\n" segment))
            snake))

;Hilfsfunktion: Gibt die Koordinaten des Futters in der Konsole aus
(define (print-food-coordinates food)
  (printf "Futter gefressen an Position: ~a\n" food))

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
         [score (fourth state)]
         
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
         [new-snake (move-snake snake direction ate-food?)])  ; Schlange wächst nur, wenn Futter gegessen wurde

    ; Wenn das Futter gegessen wurde, gib seine Koordinaten aus
    (when ate-food?
      (print-food-coordinates food))
      
    (print-snake-coordinates new-snake) ; Ruft Hilfsfunktion für Konsolenausgabe auf
    (list new-snake direction new-food new-score)))

; Bewegt die Schlange basierend auf Tasteneingaben
(define (move state key)
  (let ([snake (first state)]
        [direction (second state)])
    (cond
      [(and (key=? key "up") (not (eq? direction 'down)))
       (list snake 'up (third state) (fourth state))]
      [(and (key=? key "down") (not (eq? direction 'up)))
       (list snake 'down (third state) (fourth state))]
      [(and (key=? key "left") (not (eq? direction 'right)))
       (list snake 'left (third state) (fourth state))]
      [(and (key=? key "right") (not (eq? direction 'left)))
       (list snake 'right (third state) (fourth state))]
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

; Starte das Spiel
(define (main)
  (big-bang INITIAL-STATE
    [to-draw draw-world]
    [on-tick tock 0.1]  ; Geschwindigkeit des Spiels (Ticks pro Sekunde)
    [on-key move]
    [stop-when exit]))

(main)
