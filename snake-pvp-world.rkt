#lang racket
(require 2htdp/universe)
(require 2htdp/image)
(require test-engine/racket-tests)

(provide (all-defined-out))

; Eine Scene is ein Image, das grundlegend aus einem weißen Rechteck mit schwarzen Rändern besteht.
; Interpretation: Die Spielumgebung

; Ein WorldState ist eine world.
; Interpretation: Der aktuelle Spielzustand.

; Eine world ist ein Struct bestehend aus einer Liste von snakes, einer Liste von items, einem Timer und einem Status.
; Interpretation: Die Gesamtheit aller Elemente, die das Spiel ausmachen.

; Ein snake ist ein Struct bestehend aus Coordinates, Color, SnakeStatus, Direction, Velocity, Score und Banana.
; Interpretation: Die Gesamtheit aller Elemente, die eine Schlange im Spiel definieren.

; Ein item ist ein Struct aus Type, x-Coordinate und y-Coordinate.
; Interpreation: Item im Spiel.

; Timer ist eine Number.
; Interpretation: Vergangene Zeit seit Spielbeginn.

; WorldStatus ist ein String.
; Interpretation: Spielstatus, zu unterscheiden zwischen "waiting", "playing", "win" und "loose".

; ID ist eine Number.
; Interpretation: Eine eindeutige Kennung der Schlange.

; Coordinates ist eine Listof (Number, Number).
; Interpretation: Eine Liste von (x, y)-Koordinaten.

; Color ist ein String.
; Interpretation: Beschreibt eine Farbe.

; Boost-Duration ist eine Number.
; Interpretation: Beschreibt wie lange sich die Schlange im Hochgeschwindigkeitsmodus aufhalten wird.

; Direction ist ein String.
; Interpretation: Beschreibt Bewegungsrichtung der Schlange.

; Velocity ist ein String.
; Interpretation: Beschreibt Geschwindigkeit der Schlange.

; Score ist eine Number.
; Interpretaion: Gibt die länge der gegebenen Schlange wieder.

; Banana ist eine Number.
; Interpretation: Die Anzahl an gegessenen Bananen.

; Type ist ein String.
; Interpretation: Beschreibt den Typ des Items. Unterschieden wird zwischen "apple" und "banana".

; x-Coordinate ist eine Number.
; Interpretation: Die x-Koordinate im Spiel.

; y-Coordinate ist eine Number.
; Interpretation: Die y-Koordinate im Spiel.


; Structs: Definition der Strukturen für Items (Futter), Schlangen und den Weltzustand
(define-struct item [type x-coordinate y-coordinate] #:prefab)   ; item repräsentiert Futter- oder andere Objekte
(define-struct snake [id coordinates color boost-duration direction velocity score banana] #:prefab) ; Schlange mit ihren Eigenschaften
(define-struct world [id snakes items timer status] #:prefab) ; Weltzustand mit Schlangen, Items, Timer und Spielstatus (waiting, playing, win, loose)

; Startzustand der Welt
(define WORLD (world 0 '() '() "0:00" "waiting")) ; Leerer Startzustand, initiale Werte sind irrelevant

; Spielgeschwindigkeit
(define GAME-SPEED 18)

; Spielfeldparameter
(define GAME-SIZE 5)                          ; Spielgröße
(define GRID-SIZE (* GAME-SIZE 5))            ; Spielfeldgröße: 25x25 Zellen
(define CELL-SIZE (* GAME-SIZE 6))            ; Jede Zelle ist 30x30 Pixel groß
(define WIDTH (* GRID-SIZE CELL-SIZE))  ; Gesamtbreite des Spielfelds in Pixeln
(define HEIGHT (* GRID-SIZE CELL-SIZE)) ; Gesamthöhe des Spielfelds in Pixeln
(define EXTRA-HEIGHT (* GAME-SIZE 15))         ; Extra Platz für Timer, Banana-Counter und Scores unter dem Spielfeld
(define TOTAL-HEIGHT (+ HEIGHT EXTRA-HEIGHT)) ; Gesamthöhe inklusive extra Platz

; receive: WorldState S-expression -> WorldState
; Empfangen von Nachrichten (Weltstatus aktualisieren)
(define (receive w m)
  (let ([id (first m)]                       ; ID-Zuweisung
        [snakes (second m)]                  ; Neue Schlangenpositionen
        [items (third m)]                  ; Neue Items (Futter)
        [timer (seconds-to-minutes (floor (/ (fourth m) GAME-SPEED)))] ; Konvertiere Timer in Minuten
        [world-status (fifth m)])          ; Aktualisiere den Spielstatus
    (world id snakes items timer world-status)))

; seconds-to-minutes: Number -> String 
; Funktion zur Umwandlung von Sekunden in Minuten. Ausgabe in "Minuten:Sekunden" Format
(define (seconds-to-minutes seconds)
  (let ([minutes (quotient seconds 60)]     ; Berechne Minuten
        [remaining-seconds (modulo seconds 60)]) ; Berechne verbleibende Sekunden
        (cond                                      ; Formatierung der Ausgabe im "Minuten:Sekunden" Format
             [(> remaining-seconds 9) (format "~a:~s" minutes remaining-seconds)]
             [else (format "~a:0~s" minutes remaining-seconds)]))) 
    
; draw-grid: Scene -> Scene  
; Funktion zum Zeichnen des Gitternetzes auf eine gegebene Szene 
(define (draw-grid scene)
  (foldl
   (lambda (i scene)
     (let ([line-x (line 0 (* HEIGHT 2) "black")]  ; Vertikale Linien des Gitternetzes
           [line-y (line (* WIDTH 2) 0 "black")]) ; Horizontale Linien des Gitternetzes
       (place-image line-x (* i CELL-SIZE) 0
                    (place-image line-y 0 (* i CELL-SIZE) scene))))
   scene
   (range (+ 1 GRID-SIZE))))  ; Zeichnet das Gitter mit allen Linien inklusive Rand

; draw-snake: Coordinates Color Status Scene -> Scene
; Zeichnet die Schlange auf das Spielfeld
(define (draw-snake snake-input-coordinates color scene)
  (foldl
   (lambda (pos image)
     (let ([x (first pos)]                     ; X-Koordinate des Schlangenkörpers
           [y (second pos)])                   ; Y-Koordinate des Schlangenkörpers
       (place-image (rectangle CELL-SIZE CELL-SIZE "solid" color) ; Zeichne Rechteck für die Schlangensegmente
                    (+ (/ CELL-SIZE 2) (* x CELL-SIZE))          ; Zentriere in der Zelle
                    (+ (/ CELL-SIZE 2) (* y CELL-SIZE))
                    image)))
   scene
   snake-input-coordinates))

; draw-foods: [Listof String] Scene -> Scene
; Zeichnet die Futteritems auf das Spielfeld
(define (draw-foods foods scene)
  (foldl
   (lambda (fruit image)
     (let ([x (item-x-coordinate fruit)]                  ; X-Position des Items
           [y (item-y-coordinate fruit)]                  ; Y-Position des Items
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

; draw-timer: Number Scene -> Scene
; Zeichnet den Timer (links oben unter dem Spielfeld)
(define (draw-timer timer scene)
  (place-image (text (format "Remaining Playtime: ~a" timer) (* 4 GAME-SIZE) "black") ; Text für den Timer
               (/ WIDTH 2)                     ; Zentriert auf dem Spielfeld
               (- TOTAL-HEIGHT (* 12 GAME-SIZE))             ; Positioniert unter dem Spielfeld
               scene))

; draw-score: Number Number Number Number Scene -> Scene
; Zeichnet die Spieler-Scores und den Banana-Counter unter dem Timer
(define (draw-score score1 score2 bananacount1 bananacount2 scene)
  (place-image (text (format "     Score-P1: ~a  |  Score-P2: ~a\nBananen-P1: ~a  |  Bananen-P2: ~a" score1 score2 bananacount1 bananacount2) (* 4 GAME-SIZE) "blue")
               (/ WIDTH 2)                     ; Zentriert unter dem Timer
               (- TOTAL-HEIGHT (* 5 GAME-SIZE))             ; Position direkt unter dem Timer
               scene))

(define (draw-player id snake1 snake2 scene)
  (place-image (text (format "Player-P~a" id) (* 6 GAME-SIZE) (cond
                                                  [(= id (snake-id snake1)) (snake-color snake1)]
                                                  [(= id (snake-id snake2)) (snake-color snake2)]))
               (/ WIDTH 8)                     ; Zentriert unter dem Timer
               (- TOTAL-HEIGHT (* 5 GAME-SIZE))             ; Position direkt unter dem Timer
               scene))

; draw-world: WorldState -> Scene
; Zeichnet den gesamten Spielzustand
(define (draw-world w)
  (cond 
    [(string=? (world-status w) "playing")     ; Wenn der Spielstatus "playing" ist
     (let* ([id (world-id w)]
           [snake1 (first (world-snakes w))]
           [snake2 (second (world-snakes w))]
           [snake1-coordinates (snake-coordinates snake1)] ; Koordinaten der ersten Schlange
           [snake2-coordinates (snake-coordinates snake2)] ; Koordinaten der zweiten Schlange
           [color1 (snake-color snake1)] ; Farbe der ersten Schlange
           [color2 (snake-color snake2)] ; Farbe der zweiten Schlange
           [score1 (snake-score snake1)] ; Länge der ersten Schlange
           [score2 (snake-score snake2)] ;Länge der zweiten Schlange
           [timer (world-timer w)] ; übrige Zeit
           [foods (world-items w)] ; Fressen für die Schlange
           [bananacount1 (snake-banana snake1)] ; Zähler Bananen der ersten Schlange
           [bananacount2 (snake-banana snake2)]) ; Zähler Bananen der zweiten Schlange
(draw-player id snake1 snake2
       (draw-score score1 score2 bananacount1 bananacount2
                   (draw-timer timer
                               (draw-snake snake2-coordinates color2
                                           (draw-snake snake1-coordinates color1
                                                       (draw-foods foods
                                                                   (draw-grid (empty-scene WIDTH TOTAL-HEIGHT)))))))))]
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

; key-handler: WorldState KeyEvent -> WorldState
; Funktion zur Verarbeitung der Tastatureingabe
(define (key-handler w key)
  (make-package w key))

; create-world: String -> WorldState
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