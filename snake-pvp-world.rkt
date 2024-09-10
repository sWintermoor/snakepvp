#lang racket
(require 2htdp/universe)
(require 2htdp/image)
(require test-engine/racket-tests)
; world

(define WORLD0 '())

; Spielfeldparameter
(define GRID-SIZE 15)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds


; Empfangen von Nachrichten
(define (receive w m)
  )





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


; Versenden der Tastatureingabe
(define (key-handler w key)
  (make-package w key))


; Starte das Spiel
(define (create-world worldname)
  (big-bang WORLD0
    [on-receive receive]
    [to-draw draw-world]
    [on-key key-handler]
    [name worldname]
    [register LOCALHOST]))

(launch-many-worlds 
  (create-world "blue")
  (create-world "green")
  )


