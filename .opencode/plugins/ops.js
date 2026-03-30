import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const opsRoot = resolve(__dirname, '..', '..');
const opsSkillsDir = join(opsRoot, 'skills');
const opsAgentsDir = join(opsRoot, 'agents');
const opsScriptsDir = join(opsRoot, 'scripts');

function loadCommands() {
  const commands = {};
  const entries = readdirSync(opsSkillsDir, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const skillFile = join(opsSkillsDir, entry.name, 'SKILL.md');
    let content;
    try {
      content = readFileSync(skillFile, 'utf8');
    } catch {
      continue;
    }
    const frontmatter = content.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatter) continue;
    const props = frontmatter[1];
    if (/user-invocable:\s*false/i.test(props)) continue;
    const descMatch = props.match(/description:\s*"(.+?)"/);
    if (!descMatch) continue;
    const name = `ops-${entry.name}`;
    commands[name] = {
      template: `Load and follow the ${name} skill.`,
      description: descMatch[1],
    };
  }
  return commands;
}

function loadAgents() {
  const agents = {};
  let entries;
  try {
    entries = readdirSync(opsAgentsDir);
  } catch {
    return agents;
  }
  for (const file of entries) {
    if (!file.endsWith('.md')) continue;
    const filePath = join(opsAgentsDir, file);
    let content;
    try {
      content = readFileSync(filePath, 'utf8');
    } catch {
      continue;
    }
    const fmMatch = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
    if (!fmMatch) continue;
    const props = fmMatch[1];
    const body = fmMatch[2].trim();
    const descMatch = props.match(/description:\s*"(.+?)"/);
    const name = `ops-${file.replace(/\.md$/, '')}`;
    agents[name] = {
      description: descMatch ? descMatch[1] : name,
      mode: 'subagent',
      prompt: body,
    };
  }
  return agents;
}

const COMMANDS = loadCommands();
const AGENTS = loadAgents();

export const OpsPlugin = async () => {
  return {
    // Register skills path + slash commands
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(opsSkillsDir)) {
        config.skills.paths.push(opsSkillsDir);
      }
      config.command = config.command || {};
      for (const [name, def] of Object.entries(COMMANDS)) {
        if (!config.command[name]) {
          config.command[name] = def;
        }
      }
      config.agent = config.agent || {};
      for (const [name, def] of Object.entries(AGENTS)) {
        if (!config.agent[name]) {
          config.agent[name] = def;
        }
      }
    },

    // Inject bootstrap routing table into system prompt
    'experimental.chat.system.transform': async (_input, output) => {
      try {
        const bootstrapPath = join(opsRoot, 'data', 'bootstrap-context.md');
        const bootstrap = readFileSync(bootstrapPath, 'utf8');
        if (bootstrap) {
          (output.system ||= []).push(bootstrap);
        }
      } catch (err) {
        // Silently skip if file is missing (e.g., shallow clone)
      }
    },

    // Add scripts/ to PATH + set OPENCODE env var
    'shell.env': async (_input, output) => {
      const currentPath = output.env?.PATH || process.env.PATH || '';
      output.env = output.env || {};
      if (!currentPath.includes(opsScriptsDir)) {
        output.env.PATH = `${opsScriptsDir}:${currentPath}`;
      }
      output.env.OPENCODE = '1';
    },
  };
};
