import { createInterface } from "node:readline";

const [year, month, entry, exit, random, project, color] = process.argv.slice(2);
const y = Number(year);
const m = Number(month);
const randomMinutes = Number(random);
const useColor = color === "1";

const paint = (code) => (text) => (useColor ? `\x1b[${code}m${text}\x1b[0m` : text);
const bold = paint("1");
const dim = paint("2");
const green = paint("32");
const red = paint("31");
const yellow = paint("33");
const cyan = paint("36");

const MONTHS = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
const WEEKDAYS = ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"];
const monthName = MONTHS[m - 1];

const pad = (n) => String(n).padStart(2, "0");
const weekday = (day) => new Date(y, m - 1, day).getDay();
const dayLabel = (day) => `${WEEKDAYS[weekday(day)]} ${pad(day)}`;
const weekOf = (day) => day - ((weekday(day) + 6) % 7);
const write = (text) => process.stdout.write(text);

const now = new Date();
const isCurrentMonth = now.getFullYear() === y && now.getMonth() + 1 === m;
const lastDay = isCurrentMonth ? now.getDate() : new Date(y, m, 0).getDate();

const mode = randomMinutes > 0 ? `aleatorio, hasta ${randomMinutes} min dentro de la franja` : "fijo";
const schedule = [`${pad(entry)}:00 – ${pad(exit)}:00`, mode, project].filter(Boolean).join(" · ");

write(`\n${bold(`fichar-factorial · ${monthName} ${y}`)}\n\n`);
write(`  ${dim("Horario")}   ${schedule}\n`);
write(`  ${dim("Días")}      del 1 al ${lastDay}\n\n`);

const filled = [];
const unknown = [];
let cleared = false;
let printedBody = false;
let currentWeek = null;
let known = null;
let exitCode = 1;

const KNOWN_ERRORS = [
  {
    pattern: /Project (?!\$\{)(.+) not found/,
    message: (match) => `El proyecto «${match[1]}» no existe en Factorial`,
    hints: ["Revisa el nombre exacto (tildes, mayúsculas…) y guárdalo con: factorial.sh configure --project \"<nombre>\""],
  },
  {
    pattern: /Invalid email or password/,
    message: () => "Email o contraseña incorrectos",
    hints: ["Vuelve a guardarlas con: factorial.sh save-credentials keychain (o zsh)"],
  },
  {
    pattern: /There should only be one current employee/,
    message: () => "Factorial devuelve más de un empleado activo para tu cuenta",
    hints: ["Es un problema de la cuenta en Factorial; no se puede arreglar desde aquí."],
  },
];

for await (const line of createInterface({ input: process.stdin })) {
  const exitMatch = line.match(/^__EXIT__:(\d+)$/);
  if (exitMatch) {
    exitCode = Number(exitMatch[1]);
    continue;
  }
  if (/^Filling shifts for \d{4}-\d+$/.test(line) || /^Employee id:/.test(line)) {
    continue;
  }
  if (line === "Clearing previous shifts") {
    cleared = true;
    printedBody = true;
    write(`  ${cyan("›")} Borrando los fichajes de ${monthName}…\n`);
    continue;
  }
  const dayMatch = line.match(/^Filling shifts for (\d+)$/);
  if (dayMatch) {
    const day = Number(dayMatch[1]);
    const item = `${green("✔")} ${dayLabel(day)}`;
    if (currentWeek === null) {
      write(`  ${cyan("›")} Fichando\n    ${item}`);
    } else if (weekOf(day) !== currentWeek) {
      write(`\n    ${item}`);
    } else {
      write(`   ${item}`);
    }
    currentWeek = weekOf(day);
    filled.push(day);
    printedBody = true;
    continue;
  }
  const error = KNOWN_ERRORS.map((candidate) => ({ candidate, match: line.match(candidate.pattern) })).find(({ match }) => match);
  if (error && !known) {
    known = { message: error.candidate.message(error.match), hints: error.candidate.hints };
    continue;
  }
  if (line.trim()) {
    unknown.push(line);
  }
}

if (currentWeek !== null) {
  write("\n");
}
if (printedBody) {
  write("\n");
}

if (exitCode === 0) {
  write(`${green("✔")} ${filled.length} ${filled.length === 1 ? "día fichado" : "días fichados"}\n`);
  const skipped = [];
  for (let day = 1; day <= lastDay; day++) {
    const dow = weekday(day);
    if (dow >= 1 && dow <= 5 && !filled.includes(day)) {
      skipped.push(dayLabel(day));
    }
  }
  if (skipped.length > 0) {
    write(`  ${dim("Saltados entre semana:")} ${skipped.join(", ")} ${dim("(festivo o ausencia en Factorial)")}\n`);
  }
} else {
  if (known) {
    write(`${red("✖")} ${known.message}\n`);
    for (const text of known.hints) {
      write(`  ${dim(text)}\n`);
    }
  } else {
    write(`${red("✖")} El CLI de Factorial ha fallado (código ${exitCode})\n`);
    for (const text of unknown.slice(-15)) {
      write(`  ${dim(text)}\n`);
    }
  }
  if (cleared) {
    write(`${yellow("!")} El mes puede haber quedado a medias (borrado y en parte rellenado): vuelve a lanzarlo.\n`);
  }
  process.exitCode = exitCode || 1;
}
