# tutorial-godot

Tutorial de Godot del canal de Brackeys de youtube.

## Controles

- Flechas o A/D: moverse.
- Espacio: saltar. Pulsa otra vez en el aire para hacer un doble salto.
- Shift o X: dash.
- Z: atacar con la espada.
- Mantén la dirección hacia una pared para quedarte pegado a ella y deslizarte despacio; pulsa Espacio para hacer un salto normal.

## Mecánicas del jugador

- Doble salto.
- Coyote time: puedes saltar durante un instante después de salir de una plataforma.
- Jump buffer: si pulsas salto justo antes de aterrizar, el salto se ejecuta al tocar el suelo.
- Salto de altura variable: si sueltas Espacio antes, el salto es más corto.
- Dash con cooldown y un dash aéreo por salto.
- Wall slide y wall jump: mantente pegado a una pared para deslizarte despacio y salta con un salto normal.
- Ataque con espada (Z): muestra una espada, elimina a los slimes verdes.
- Fantasma azul invencible: flota y se mueve aleatoriamente por todo el mapa; no se puede matar y te elimina al tocarlo.
- Consigue las 15 monedas para ganar la partida.

Puedes ajustar velocidades, tiempos y cooldowns en las constantes de `scripts/player.gd`. La velocidad de los slimes está en `scripts/slime.gd` y la del fantasma en `scripts/ghost_enemy.gd`.
