---
layout: home

hero:
  name: fichar-factorial
  text: Ficha en Factorial desde tu agente de IA
  tagline: Una skill para Claude Code (u otro agente que lea skills) que rellena tus fichajes con un horario fijo o aleatorio dentro de una franja.
  actions:
    - theme: brand
      text: Empezar
      link: /instalacion
    - theme: alt
      text: Ver en GitHub
      link: https://github.com/carloscasteher/fichar-factorial

features:
  - title: Te guía la primera vez
    details: El instalador te pide dónde guardar las credenciales, las comprueba con un login y te pregunta el horario.
  - title: Fijo o aleatorio
    details: Todos los días a la misma hora, o con unos minutos al azar sin salirse nunca de tu franja.
  - title: El agente no ve tu contraseña
    details: Las credenciales se guardan desde tu terminal, en el llavero de macOS o en zsh, y se leen dentro del propio comando.
  - title: Confirma antes de fichar
    details: Te enseña el mes, los días y el horario, y al terminar te dice qué días entre semana se ha saltado.
---

## Cómo funciona

Por debajo usa [`factorial-cli`](https://github.com/DanielRamosAcosta/factorial-cli), de Daniel Ramos, fijado a la versión 1.0.18. Este proyecto añade tres piezas:

- Una **skill** que pide confirmación antes de fichar y, si hace falta, te guía para guardar las credenciales y elegir el horario.
- Un **script** (`factorial.sh`) que guarda tu configuración, lee las credenciales sin exponerlas y lanza el CLI. También se puede usar a mano, sin agente.
- Un **instalador** (`install.sh`) que enlaza la skill y te configura credenciales y horario.

::: warning Antes de empezar
El CLI **borra todos los fichajes del mes** antes de volver a rellenarlo. Lee [A tener en cuenta](/a-tener-en-cuenta) antes de fichar por primera vez.
:::

## Licencia

Es de dominio público ([The Unlicense](https://github.com/carloscasteher/fichar-factorial/blob/main/LICENSE)): no tiene copyright ni se reserva ningún derecho. Cualquiera puede usarlo, copiarlo, modificarlo y redistribuirlo para lo que quiera, sin necesidad de citar a nadie. `factorial-cli` no está incluido en el repo: se descarga al fichar y mantiene su propia licencia (MIT).
