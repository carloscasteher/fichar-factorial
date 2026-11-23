# Uso

## Pídeselo a tu agente

Dile a tu agente cosas como:

- «ficha» o «ficha este mes»
- «ficha noviembre»
- «ficha el mes pasado»

Si no dices el mes, usa el actual, o el anterior si hoy es día 1 a 5.

## Antes de fichar

El agente te enseña un resumen y espera a que digas que sí:

- El mes y los días que va a rellenar: del 1 a hoy, o hasta fin de mes si es un mes pasado.
- La franja, el modo (fijo o aleatorio) y el proyecto.
- El aviso de que **se borrarán todos los fichajes de ese mes** y se volverán a crear.

Si quieres otro horario o quitar el proyecto **solo esa vez**, díselo en ese momento: no cambia tu configuración.

## Qué verás

```text
fichar-factorial · noviembre 2026

  Horario   07:00 – 15:00 · fijo · Mi proyecto
  Días      del 1 al 23

  › Borrando los fichajes de noviembre…
  › Fichando
    ✔ mar 03   ✔ mié 04   ✔ jue 05   ✔ vie 06
    ✔ lun 09   ✔ mar 10   ✔ mié 11   ✔ jue 12   ✔ vie 13
    ✔ lun 16   ✔ mar 17   ✔ mié 18   ✔ jue 19   ✔ vie 20
    ✔ lun 23

✔ 15 días fichados
  Saltados entre semana: lun 02 (festivo o ausencia en Factorial)
```

La última línea te dice qué días entre semana no se han fichado. Si alguno debería haberse fichado, o al revés, alguno que se ha fichado era una ausencia, revisa tu calendario en Factorial.

## Cambiar el horario

Pídeselo al agente («cambia mi horario», «ponlo aleatorio») o vuelve a ejecutar `./install.sh`. También puedes hacerlo a mano con [`configure`](/comandos#configure).

### Fijo o aleatorio

- **Fijo**: todos los días exactamente a la hora de entrada y de salida.
- **Aleatorio**: cada día la entrada se retrasa y la salida se adelanta hasta N minutos al azar (1–59), sin salirse nunca de la franja.

::: info
En modo aleatorio la jornada puede quedar hasta 2N minutos más corta que la franja. Si necesitas la jornada completa, amplía la franja o usa el modo fijo.
:::
