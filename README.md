# fichar-factorial

Skill para rellenar tus fichajes de Factorial desde tu agente de IA (Claude Code u otro que lea skills), con un horario fijo o aleatorio dentro de una franja. Usa por debajo [`factorial-cli`](https://github.com/DanielRamosAcosta/factorial-cli), de Daniel Ramos.

**Documentación: https://carloscasteher.github.io/fichar-factorial/**

## Instalación rápida

Requisitos: Node.js 18 o superior, pnpm o npm, y una contraseña de Factorial (el login es con email y contraseña, no con Google).

```bash
git clone https://github.com/carloscasteher/fichar-factorial.git
cd fichar-factorial
./install.sh
```

Después, dile a tu agente «ficha este mes».

> [!WARNING]
> El CLI **borra todos los fichajes del mes** antes de volver a rellenarlo, también los que hayas metido a mano. Lee [A tener en cuenta](https://carloscasteher.github.io/fichar-factorial/a-tener-en-cuenta) antes de fichar por primera vez.

## Documentación en local

```bash
pnpm install
pnpm docs:dev
```

## Licencia

Dominio público ([The Unlicense](LICENSE)). `factorial-cli` no está incluido en este repo y mantiene su propia licencia (MIT).
