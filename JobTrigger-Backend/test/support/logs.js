/**
 * §19: captures the server's structured log lines while [fn] runs, so a
 * test can assert on what the server said. The logger writes one JSON
 * object per line, so every captured line is parsed.
 *
 * The log level is raised for the duration: the suites turn it off
 * (test/setup.js) to keep the output readable.
 */
exports.captureLogs = async (fn) => {
  const lines = [];
  const originalLog = console.log;
  const originalError = console.error;
  const level = process.env.LOG_LEVEL;
  process.env.LOG_LEVEL = 'info';
  console.log = (line) => lines.push(line);
  console.error = (line) => lines.push(line);
  try {
    await fn();
  } finally {
    console.log = originalLog;
    console.error = originalError;
    process.env.LOG_LEVEL = level;
  }
  return lines
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
};

/** The captured lines with [msg], in order. */
exports.linesWith = (entries, msg) => entries.filter((entry) => entry.msg === msg);
