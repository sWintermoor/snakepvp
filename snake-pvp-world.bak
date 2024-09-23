#lang racket
(require 2htdp/universe)
(require 2htdp/image)
(require test-engine/racket-tests)

; WorldState is (Snakes Food Score)
; Verbesserungsvorschläge: Anstelle von first, second und so weiter lieber aussagekräftigere Funktionen definieren.

; Structs: Definition der Strukturen für Items (Futter), Schlangen und den Weltzustand
(define-struct item [type x y] #:prefab)   ; item repräsentiert Futter- oder andere Objekte
(define-struct snake [coordinates color status direction velocity score banana] #:prefab) ; Schlange mit ihren Eigenschaften
(define-struct world [snakes items timer status] #:prefab) ; Weltzustand mit Schlangen, Items, Timer und Spielstatus (waiting, playing, win, loose)

; Startzustand der Welt
(define WORLD (world '() '() 300 "waiting")) ; Leerer Startzustand, initiale Werte sind potenziell irrelevant

; Spielfeldparameter
(define GRID-SIZE 25)            ; Spielfeldgröße: 25x25 Zellen
(define CELL-SIZE 30)            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds in Pixeln
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds in Pixeln
(define EXTRA-HEIGHT 75)         ; Extra Platz für Timer, Banana-Counter und Scores unter dem Spielfeld
(define TOTAL-HEIGHT (+ HEIGHT EXTRA-HEIGHT)) ; Gesamthöhe inklusive extra Platz

; Empfangen von Nachrichten (Weltstatus aktualisieren)
(define (receive w m)
  (let ([snakes (first m)]                  ; Neue Schlangenpositionen
        [items (second m)]                  ; Neue Items (Futter)
        [timer (seconds-to-minutes (floor (/ (third m) 6)))] ; Konvertiere Timer in Minuten
        [world_status (fourth m)])          ; Aktualisiere den Spielstatus
    (world snakes items timer world_status)))

; Funktion zur Umwandlung von Sekunden in Minuten
(define (seconds-to-minutes seconds)
  (let ([minutes (quotient seconds 60)]     ; Berechne Minuten
        [remaining-seconds (modulo seconds 60)]) ; Berechne verbleibende Sekunden
    (format "~a:~s" minutes remaining-seconds))) ; Formatierung der Ausgabe im "Minuten:Sekunden" Format
    

; Funktion zum Zeichnen des Gitternetzes
(define (draw-grid scene)
  (foldl
   (lambda (i scene)
     (let ([line-x (line 0 (* HEIGHT 2) "black")]  ; Vertikale Linien des Gitternetzes
           [line-y (line (* WIDTH 2) 0 "black")]) ; Horizontale Linien des Gitternetzes
       (place-image line-x (* i CELL-SIZE) 0
                    (place-image line-y 0 (* i CELL-SIZE) scene))))
   scene
   (range (+ 1 GRID-SIZE))))  ; Zeichnet das Gitter mit allen Linien inklusive Rand

; Zeichnet eine Zelle mit einer bestimmten Farbe
(define (draw-cell x y color)
  (place-image (rectangle CELL-SIZE CELL-SIZE "solid" color) ; Rechteck für die Zelle
               (* x CELL-SIZE) (* y CELL-SIZE)               ; Position auf dem Spielfeld
               (empty-scene WIDTH HEIGHT)))                  ; Leerbildschirm als Hintergrund

; Zeichnet die Schlange auf das Spielfeld
(define (draw-snake snake color status scene)
  (foldl
   (lambda (pos image)
     (let ([x (first pos)]                     ; X-Koordinate des Schlangenkörpers
           [y (second pos)])                   ; Y-Koordinate des Schlangenkörpers
       (place-image (rectangle CELL-SIZE CELL-SIZE status color) ; Zeichne Rechteck für die Schlangensegmente
                    (+ (/ CELL-SIZE 2) (* x CELL-SIZE))          ; Zentriere in der Zelle
                    (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                    image)))
   scene
   snake))

; Zeichnet die Futteritems auf das Spielfeld
(define (draw-foods foods scene)
  (foldl
   (lambda (fruit image)
     (let ([x (item-x fruit)]                  ; X-Position des Items
           [y (item-y fruit)]                  ; Y-Position des Items
           [type (item-type fruit)])           ; Typ des Items (z.B. Apfel oder Banane)
       (cond
         [(eq? type 'apple)                    ; Zeichne Apfel-Item
          (place-image (underlay/xy (ellipse CELL-SIZE (- CELL-SIZE (/ CELL-SIZE 3)) "solid" "crimson") ; Apfel als Ellipse
                                    (/ CELL-SIZE 2) (- 0 (/ CELL-SIZE 5))
                                    (rotate 160 (isosceles-triangle (/ CELL-SIZE 2) CELL-SIZE "solid" "brown"))) ; Stiel des Apfels
                       (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
                       (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                       image)]
         [(eq? type 'banana)                   ; Zeichne Bananen-Item
          (place-image
           (overlay/xy
            (overlay/xy (rotate -50 (ellipse (/ CELL-SIZE 2) CELL-SIZE "solid" "gold")) ; Zeichne Banane als Ellipse
                        0
                        0
                        (rotate -50 (ellipse (/ CELL-SIZE 2) CELL-SIZE "outline" "black"))) ; Banane umranden
            (/ CELL-SIZE 2)
            (- 0 (/ CELL-SIZE 5))
            (rotate -40 (rectangle 5 15 "solid" "brown"))) ; Stiel der Banane
           (+ (/ CELL-SIZE 2) (* x CELL-SIZE))
           (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
           image)
          ])))
   scene
   foods))

; Zeichnet den Timer (links oben unter dem Spielfeld)
(define (draw-timer timer scene)
  (place-image (text (format "Remaining Playtime: ~a" timer) 20 "black") ; Text für den Timer
               (/ WIDTH 2)                     ; Zentriert auf dem Spielfeld
               (- TOTAL-HEIGHT 60)             ; Positioniert unter dem Spielfeld
               scene))

; Zeichnet die Spieler-Scores und den Banana-Counter unter dem Timer
(define (draw-score score1 score2 bananacount1 bananacount2 scene)
  (place-image (text (format "     Score-P1: ~a  |  Score-P2: ~a\nBananen-P1: ~a  |  Bananen-P2: ~a" score1 score2 bananacount1 bananacount2) 20 "blue")
               (/ WIDTH 2)                     ; Zentriert unter dem Timer
               (- TOTAL-HEIGHT 25)             ; Position direkt unter dem Timer
               scene))

; Zeichnet den gesamten Spielzustand
(define (draw-world w)
  (cond 
    [(string=? (world-status w) "playing")     ; Wenn der Spielstatus "playing" ist
     (let ([snake1 (snake-coordinates (first (world-snakes w)))] ; Erste Schlange
           [snake2 (snake-coordinates (second (world-snakes w)))] ; Zweite Schlange
           [color1 (snake-color (first (world-snakes w)))] ; Farbe der ersten Schlange
           [color2 (snake-color (second (world-snakes w)))] ; Farbe der zweiten Schlange
           [status1 (snake-status (first (world-snakes w)))] ;
           [status2 (snake-status (second (world-snakes w)))] ;
           [score1 (snake-score (first (world-snakes w)))] ; Länge der ersten Schlange
           [score2 (snake-score (second (world-snakes w)))] ;Länge der zweiten Schlange
           [timer (world-timer w)] ; übrige Zeit
           [foods (world-items w)] ; Fressen für die Schlange
           [bananacount1 (snake-banana (first (world-snakes w)))] ; Zähler Bananen der ersten Schlange
           [bananacount2 (snake-banana (second (world-snakes w)))]) ; Zähler Bananen der zweiten Schlange
       (draw-score score1 score2 bananacount1 bananacount2
                   (draw-timer timer
                               (draw-snake snake2 color2 status2
                                           (draw-snake snake1 color1 status1
                                                       (draw-foods foods
                                                                   (draw-grid (empty-scene WIDTH TOTAL-HEIGHT))))))))]
    [(string=? (world-status w) "waiting")     ; Wenn der Status "waiting" ist
     (overlay (text "Waiting... \n\nUniverse started?" 30 "orange") (empty-scene WIDTH TOTAL-HEIGHT))]
    [(string=? (world-status w) "loose")       ; Wenn der Status "loose" ist
     (overlay (text "You have lost" 30 "crimson") (empty-scene WIDTH TOTAL-HEIGHT))]
    [(string=? (world-status w) "win")         ; Wenn der Status "win" ist
     (overlay (text "You have won" 30 "lime green") (empty-scene WIDTH TOTAL-HEIGHT))]
    [(string=? (world-status w) "tie")         ; Wenn der Status "tie" ist
     (overlay (text "Its a Tie!" 30 "orange") (empty-scene WIDTH TOTAL-HEIGHT))]
    [else                                      ; Wenn der Status unbekannt ist
     (overlay (text "rejected" 30 "blue") (empty-scene WIDTH TOTAL-HEIGHT))]))

; Funktion zur Verarbeitung der Tastatureingabe
(define (key-handler w key)
  (make-package w
                (cond
                  [(string=? (world-status w) "playing") key]))) ; Verarbeite Tastatureingaben nur, wenn das Spiel läuft

; Funktion zum Starten des Spiels
(define (create-world worldname)
  (big-bang WORLD
    [on-receive receive]                      ; Empfängt Nachrichten und aktualisiert den Weltzustand
    [to-draw draw-world]                      ; Zeichnet den aktuellen Weltzustand
    [on-key key-handler]                      ; Verarbeitet Tastatureingaben
    [name worldname]                          ; Name der Welt
    ;   [state #t]                                ; Optionaler Zustand (deaktiviert)
    ;   [register "192.168.1.15"]                 ; Optionaler Register
    ;   [port 9092]                               ; Optionaler Port
    [register LOCALHOST]))                    ; Lokalhost als Standard

; Startet mehrere Welten (für Multiplayer)
(launch-many-worlds 
 (create-world "Player A")
 (create-world "Player B"))
