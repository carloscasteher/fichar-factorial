# Seguridad

- **El agente nunca ve tu contraseña.** Las credenciales se guardan desde tu terminal y el script las lee dentro del propio comando.
- **La contraseña no se pasa nunca por argumento.** Se le da al CLI como variable de entorno, así que no aparece en la lista de procesos.
- **El fichero de configuración no guarda secretos.** `~/.config/fichar-factorial/config` solo tiene el horario, el proyecto y dónde están las credenciales, y tiene permisos `600`.
- **Solo habla con Factorial.** El script no envía nada a ningún otro sitio: `id.factorialhr.com` para el login y `api.factorialhr.com` para los fichajes, a través del CLI.

## Dónde se guardan las credenciales

| Opción | Dónde | En texto plano |
|---|---|---|
| Llavero de macOS | Servicio `factorial-cli`; cuenta = tu email | No |
| zsh | Bloque `# >>> fichar-factorial >>>` en `~/.zshrc` | Sí |

Para borrarlas:

```bash
security delete-generic-password -s factorial-cli
```

En el caso de zsh, borra el bloque entre `# >>> fichar-factorial >>>` y `# <<< fichar-factorial <<<` de tu `~/.zshrc`.
