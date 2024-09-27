#lang racket
(require 2htdp/universe)
(require "snake-pvp-world.rkt")

; Startet mehrere Welten (für Multiplayer)
(launch-many-worlds 
 (create-world "Player A")
 (create-world "Player B"))