#lang racket
(require 2htdp/universe)
(require 2htdp/image)
(require test-engine/racket-tests)

; WorldState is (Snakes Food Score)
; Verbesserungsvorschläge: Anstelle von first, second und so weiter lieber aussagekräftigere Funktionen definieren.

; Structs
(define-struct item [type x y] #:prefab)
(define-struct snake [coordinates color status direction velocity score banana] #:prefab)
(define-struct world [snakes items timer status] #:prefab) ; status: waiting, playing, win, loose

; Startzustand der Welt
(define WORLD0 (world '() '() 300 "waiting")) ; Startzustand, Werte sind potenziell irrelevant

; Spielfeldparameter
(define GRID-SIZE 35)            ; 15x15 Felder
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds
(define EXTRA-HEIGHT 75)        ; Extra Platz für Timer, Banana-Counter und Scores
(define TOTAL-HEIGHT (+ HEIGHT EXTRA-HEIGHT)) ; Gesamthöhe inklusive zusätzlichem Platz

; Empfangen von Nachrichten
(define (receive w m)
  (let ([snakes (first m)]
        [items (second m)]
        [timer (seconds-to-minutes (floor (/ (third m) 6)))]
        [world_status (fourth m)])
    (world snakes items timer world_status)))

(define (seconds-to-minutes seconds)
  (let ([minutes (quotient seconds 60)]
        [remaining-seconds (modulo seconds 60)])
    (format "~a:~s" minutes remaining-seconds)))
    
    

; Funktion zum Zeichnen des Gitternetzes
(define (draw-grid scene)
  (foldl
   (lambda (i scene)
     (let ([line-x (line 0 (* HEIGHT 2) "black")]  ; Vertikale Linien
           [line-y (line (* WIDTH 2) 0 "black")]) ; Horizontale Linien
       (place-image line-x (* i CELL-SIZE) 0
                    (place-image line-y 0 (* i CELL-SIZE) scene))))
   scene
   (range (+ 1 GRID-SIZE))))  ; Zeichnet das Gitter inklusive Randlinien

; Zeichnet eine Zelle mit einer bestimmten Farbe
(define (draw-cell x y color)
  (place-image (rectangle CELL-SIZE CELL-SIZE "solid" color)
               (* x CELL-SIZE) (* y CELL-SIZE)
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
         [(eq? type 'apple) (place-image (underlay/xy (ellipse CELL-SIZE (- CELL-SIZE (/ CELL-SIZE 3)) "solid" "crimson")
                                                      (/ CELL-SIZE 2) (- 0 (/ CELL-SIZE 5))
                                                      (rotate 160 (isosceles-triangle (/ CELL-SIZE 2) CELL-SIZE "solid" "brown")))
                                         (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                                         (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                                         scene)
                            ]
         [(eq? type 'banana) (place-image
                              (overlay/xy
                               (overlay/xy (rotate -50 (ellipse (/ CELL-SIZE 2) CELL-SIZE "solid" "gold"))
                                           0
                                           0
                                           (rotate -50 (ellipse (/ CELL-SIZE 2) CELL-SIZE "outline" "black")))
                               (/ CELL-SIZE 2)
                               (- 0 (/ CELL-SIZE 5))
                               (rotate -40 (rectangle 5 15 "solid" "brown")))
                              (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                              (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                              scene)
                             ])))
   scene
   foods))

; Zeichnet den Timer (links oben unter dem Spielfeld)
(define (draw-timer timer scene)
  (place-image (text (format "Remaining Playtime: ~a" timer) 20 "black")
               (/ WIDTH 2) ; Zentriert
               (- TOTAL-HEIGHT 60) ; Position unter dem Spielfeld
               scene))

; Zeichnet die Spieler-Scores (zentriert unter dem Timer und dem Bananen-Zähler)
(define (draw-score score1 score2 bananacount1 bananacount2 scene)
  (place-image (text (format "     Score-P1: ~a  |  Score-P2: ~a\nBananen-P1: ~a  |  Bananen-P2: ~a" score1 score2 bananacount1 bananacount2) 20 "blue")
               (/ WIDTH 2) ; Zentriert
               (- TOTAL-HEIGHT 25) ; Position unter dem Timer und Bananen-Zähler
               scene))

; Zeichnet den gesamten Spielzustand
(define (draw-world w)
  (cond 
    [(string=? (world-status w) "playing")
     (let ([snake1 (snake-coordinates (first (world-snakes w)))]
           [snake2 (snake-coordinates (second (world-snakes w)))]
           [color1 (snake-color (first (world-snakes w)))] 
           [color2 (snake-color (second (world-snakes w)))]
           [status1 (snake-status (first (world-snakes w)))]
           [status2 (snake-status (second (world-snakes w)))]
           [score1 (snake-score (first (world-snakes w)))]
           [score2 (snake-score (second (world-snakes w)))]
           [timer (world-timer w)]
           [foods (world-items w)]
           [bananacount1 (snake-banana (first (world-snakes w)))]
           [bananacount2 (snake-banana (second (world-snakes w)))])
       (draw-score score1 score2 bananacount1 bananacount2
                   (draw-timer timer
                               (draw-snake snake2 color2 status2
                                           (draw-snake snake1 color1 status1
                                                       (draw-foods foods
                                                                   (draw-grid (empty-scene WIDTH TOTAL-HEIGHT))))))))]
    [(string=? (world-status w) "waiting")
     (overlay (text "Waiting... \n\nUniverse started?" 20 "orange") (empty-scene WIDTH TOTAL-HEIGHT))]
    [(string=? (world-status w) "loose")
     (overlay (text "You have lost" 20 "red") (empty-scene WIDTH TOTAL-HEIGHT))]
    [(string=? (world-status w) "win")
     (overlay (text "You have won" 20 "green") (empty-scene WIDTH TOTAL-HEIGHT))]
    [(string=? (world-status w) "tie")
     (overlay (text "Its a Tie!" 20 "orange") (empty-scene WIDTH TOTAL-HEIGHT))]
    [else
     (overlay (text "rejected" 20 "blue") (empty-scene WIDTH TOTAL-HEIGHT))]))

; Tastatureingabe
(define (key-handler w key)
  (make-package w
                (cond
                  [(string=? (world-status w) "playing") key])))

; Starte das Spiel
(define (create-world worldname)
  (big-bang WORLD0
    [on-receive receive]
    [to-draw draw-world]
    [on-key key-handler]
    [name worldname]
    [register LOCALHOST]))

; Mehrere Welten starten
(launch-many-worlds 
 (create-world "a")
 (create-world "b"))
