# Match-3 Godot – Proyecto Segundo Parcial

## Por: Patricia Quisbert y Tatiana Aramayo

Este proyecto implementa un clon de juego tipo Match-3 (estilo Candy Crush) en Godot 4, con fichas especiales y dos modos de juego diferentes.

### Características implementadas
1. Ficha 4 (Vertical y Horizontal)

Cuando se forma un match de 4 fichas del mismo color:

Match vertical de 4 → se crea una ficha especial de tipo COL (rayada vertical).

Match horizontal de 4 → se crea una ficha especial de tipo ROW (rayada horizontal).

Funcionamiento especial:

Cuando una de estas fichas participa en un match de 3 o más, limpia toda su columna (si es COL) o toda su fila (si es ROW).

2. Ficha 5 (Rainbow)

Se genera al formar un match de 5 fichas:

Puede ser en línea recta (fila o columna).

O en forma de T (combinando filas y columnas).

Funcionamiento especial:

Si se combina con una ficha de color ⇒ destruye todas las fichas de ese color en el tablero.

Si se combina con otra ficha arcoíris ⇒ se limpia por completo todo el tablero.

Aquí se puede ver todas las fichas especiales:
<img width="783" height="1043" alt="image" src="https://github.com/user-attachments/assets/aaf2407d-964c-40da-a702-89c2bf69a281" />


3. Puntaje y Modos de Juego

### El juego cuenta con dos modos de partida distintos:

#### Modo por Tiempo

El jugador dispone de un tiempo límite.

Debe acumular la mayor cantidad de puntos posible antes de que el cronómetro llegue a 0.

Para ganar, es necesario alcanzar al menos un puntaje mínimo establecido.

#### Modo por Movimientos

El jugador tiene un número limitado de movimientos.

Cada movimiento exitoso (intercambio válido) descuenta uno de los movimientos disponibles.

El objetivo es llegar al mínimo de puntaje requerido antes de quedarse sin movimientos.

Si no alcanza ese puntaje, la partida se considera perdida.

<img width="828" height="1033" alt="image" src="https://github.com/user-attachments/assets/134bbae1-2a97-4e9b-8660-f5ceeb46f86e" />

Despues de perder la partida, el juego reiniciara despues de 3 segundos para volver a escoger la modalidad de juego.
### Controles

Click o touch sobre una ficha + arrastre a una adyacente para intercambiar.

El sistema detecta matches automáticamente.

Cuando las fichas son destruidas, las superiores caen y se rellenan las posiciones vacías.

Se pueden generar cadenas (cascadas) con nuevos matches automáticos.

### Checklist Implementado

 Match-3 básico (detectar, destruir, colapsar y rellenar).

 Ficha especial 4 en línea (ROW y COL).

 Ficha especial 5 en línea o en T (arcoíris).

 Efectos especiales al combinar fichas arcoíris.

 Sistema de puntaje integrado.

 Modo por Tiempo con límite de cronómetro.

 Modo por Movimientos con límite de intentos.
