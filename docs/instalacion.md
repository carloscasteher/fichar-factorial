# Instalación

## Requisitos

- **Node.js 18** o superior.
- **pnpm** (recomendado) o npm. El script usa `pnpm dlx` y, si no hay pnpm, `npx`.
- Una **contraseña de Factorial**. El CLI entra con email y contraseña, no con Google.
- **macOS** para guardar las credenciales en el llavero. En Linux, usa la opción de zsh.

::: tip ¿Solo entras con Google?
Créate una contraseña en Factorial antes de instalar. Sin ella el login no funcionará.
:::

## Instalar

```bash
git clone https://github.com/carloscasteher/fichar-factorial.git
cd fichar-factorial
./install.sh
```

## Qué hace el instalador

```text
fichar-factorial · instalación

[1/4] Skill
  ✔ Enlazada en ~/.claude/skills/fichar-factorial

[2/4] Credenciales
  ? ¿Dónde guardo tu email y tu contraseña de Factorial?
    1) Llavero de macOS   recomendado en Mac; no quedan en texto plano
    2) ~/.zshrc           la contraseña queda en texto plano
    3) Ya las tengo en zsh FACTORIAL_USER_EMAIL y FACTORIAL_USER_PASSWORD

[3/4] Comprobación
  ✔ Credenciales válidas
    Solo se ha hecho login; no se ha tocado ningún fichaje.

[4/4] Horario
  ? Hora de entrada [8]: 7
  ? Hora de salida [15]:
  ? Modo [1]:
  ? Proyecto de Factorial, con el nombre exacto (vacío si no usas proyectos):
  ✔ Horario guardado · 07:00 – 15:00 · fijo · sin proyecto
```

1. **Skill.** La enlaza en `~/.claude/skills/fichar-factorial`. Es un enlace simbólico al repo, así que para actualizar basta con `git pull`. Si ya tenías una carpeta con ese nombre, te pregunta y la mueve a `~/.claude/backups/`, fuera de `skills/` para que el agente no la cargue como otra skill.
2. **Credenciales.** Te pregunta dónde guardar tu email y tu contraseña de Factorial, o si ya los tienes en zsh:
   - **Llavero de macOS** (recomendado): servicio `factorial-cli`.
   - **`~/.zshrc`**: un bloque entre `# >>> fichar-factorial >>>` y `# <<< fichar-factorial <<<`. La contraseña queda en texto plano.
   - **Ya las tengo en zsh**: usa `FACTORIAL_USER_EMAIL` y `FACTORIAL_USER_PASSWORD`.
3. **Comprobación.** Hace login en Factorial para validar las credenciales. No toca ningún fichaje.
4. **Horario.** Entrada y salida (horas en punto), modo fijo o aleatorio, y el proyecto de Factorial (opcional). Se guarda en `~/.config/fichar-factorial/config`.

Puedes volver a ejecutar `./install.sh` cuando quieras para cambiar las credenciales o el horario. Si ya están guardados, te pregunta antes de cambiarlos.

## Opciones

| Opción | Qué hace |
|---|---|
| `--dir DIRECTORIO` | Enlaza la skill en el directorio de skills de otro agente, en vez de `~/.claude/skills`. |
| `--no-configure` | Solo enlaza la skill; las credenciales y el horario te los pedirá el agente la primera vez. |

Si lo ejecutas sin una terminal interactiva, solo enlaza la skill, igual que con `--no-configure`.

## Actualizar

```bash
cd fichar-factorial
git pull
```

No hace falta volver a instalar: la skill es un enlace al repo.
