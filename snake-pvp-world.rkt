#lang racket
(require 2htdp/universe)
(require 2htdp/image)
(require test-engine/racket-tests)

; Verbesserungsvorschläge: Anstelle von first, second und so weiter lieber aussagekräftigere Funktionen definieren.

; WorldState is (Snakes Food Score)

; Snakes is

; Food is

; Score is a Number



; Structs
(define-struct item [type x y] #:prefab)
(define-struct snake [coordinates color status direction velocity score inventory] #:prefab)
(define-struct world [snakes items timer status] #:prefab) ;status: waiting, playing, win, loose

; Startzustand der Welt
(define WORLD0 (world '() '() 300 "waiting")) ;die Werte sind potenziell irrelevant

; Spielfeldparameter
(define GRID-SIZE 15)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds
(define GRID-COLOR "black")

(define FOOD-COLOR "red") ;Food-Color muss weg, anstelle dessen müssen wir type von item nutzen

(define NUM_PLAYERS 2)


; Empfangen von Nachrichten
; Wir brauchen: Snakes (x, y, c) Food-Koordinaten, Score
#|(check-expect ((receive '('('(3 3 "blue") '(3 4 "blue")) '('(7 5 "green") '(7 6 "green"))) '( 1 1) 9)
               '('('('(3 4 "blue") '(3 5 "blue")) '('(7 6 "green") '(7 7 "green"))) '( 1 1) 9))
              '('('('(3 4 "blue") '(3 5 "blue")) '('(7 6 "green") '(7 7 "green"))) '( 1 1) 9))|#

(define (receive w m)
  (let
      ([snakes (first m)]
       [items (second m)]
       [timer (third m)]
       [world_status (fourth m)])
    (world snakes items timer world_status)))


; Funktion zum Zeichnen des Gitternetzes


(define (draw-grid scene)
  (foldl
   (lambda (i scene)
     (let ([line-x (line 0 (* HEIGHT 2) GRID-COLOR)]   ; Vertikale Linien
           [line-y (line (* WIDTH 2) 0 GRID-COLOR)])   ; Horizontale Linien
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
(define (draw-snake snake color status scene)
  (foldl
   (lambda (pos image)
     (let ([x (first pos)]
           [y (second pos)])
       (place-image (rectangle CELL-SIZE CELL-SIZE status color) 
                    (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                    (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                    image)))
   scene
   snake))

; Zeichnet das Futter und weitere Items
(define (draw-foods foods scene)
  
  (foldl
   (lambda (fruit image)
     (let ([x (item-x fruit)]
        [y (item-y fruit)]
        [type (item-type fruit)])
    (cond
      [(eq? type 'apple)  (place-image (circle (/ CELL-SIZE 2) "solid" "red")
                 (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                 (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                 image)]
      [(eq? type 'banana)  (place-image (circle (/ CELL-SIZE 2) "solid" "yellow")
                 (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                 (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                 image)]
    )))
   scene
   foods))

; Zeichnet den Punktestand
(define (draw-score score1 score2 scene)
  (place-image (text (format "Score-P1: ~a\nScore-P2: ~s" score1 score2) 20 "blue")
               (+ CELL-SIZE 25) (/ CELL-SIZE 1.5)
               scene))

; Zeichnet den gesamten Spielzustand
(define (draw-world w)
  (cond 
    [(string=? (world-status w) "playing")
     ;(= (length (world-snakes w)) NUM_PLAYERS)
     (let ([snake1 (snake-coordinates (first (world-snakes w)))]
           [snake2 (snake-coordinates (second (world-snakes w)))]
           [color1 (snake-color (first (world-snakes w)))] 
           [color2 (snake-color (second (world-snakes w)))]
           [status1 (snake-status (first (world-snakes w)))]
           [status2 (snake-status (first (world-snakes w)))]
           [score1 (snake-score (first (world-snakes w)))]
           [score2 (snake-score (second (world-snakes w)))]
           [foods (world-items w)]) ;zeichnet alle Items in der Liste, aber als roter Kreis (so)
       (draw-score score1 score2 
                   (draw-snake snake2 color2 status2 ;Schlange wird mit Farbe gezeichnet
                               (draw-snake snake1 color1 status1
                                           (draw-foods foods
                                                       (draw-grid (empty-scene WIDTH HEIGHT)))))))]
    [(string=? (world-status w) "waiting") (overlay (text "Waiting... \n\nUniverse started?" 20 "orange") (empty-scene WIDTH HEIGHT))] ;Eine bessere Methode als "string=?" finden?
    [(string=? (world-status w) "loose") (overlay (text "You have lost" 20 "red") (empty-scene WIDTH HEIGHT))]
    [(string=? (world-status w) "win") (overlay (text "You have won" 20 "green") (empty-scene WIDTH HEIGHT))]
    [else (overlay (text "rejected" 20 "blue") (empty-scene WIDTH HEIGHT))]
    ))


; Versenden der Tastatureingabe
(define (key-handler w key)
  (make-package w
  (cond
    [(string=? (world-status w) "playing") key]))) ; evtl ist Fallunterscheidung unnötig


; Starte das Spiel
(define (create-world worldname)
  (big-bang WORLD0
    [on-receive receive]
    [to-draw draw-world]
    [on-key key-handler]
    [name worldname]
    [register LOCALHOST]))

(launch-many-worlds 
 (create-world "a")
 (create-world "b"))
