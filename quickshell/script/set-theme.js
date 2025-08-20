const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const configPath = path.join(__dirname, '../utils/utils.json');

function readConfig() {
	try {
		if (fs.existsSync(configPath)) {
			const data = fs.readFileSync(configPath, 'utf8');
			return JSON.parse(data);
		}
	} catch (err) {
		console.error('Error reading config:', err.message);
	}
	// Fallback default shape to avoid breaking other scripts
	return { dmenuVisible: false, themeSwitcherVisible: false };
}

function writeConfig(cfg) {
	try {
		fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2));
	} catch (err) {
		console.error('Error writing config:', err.message);
		process.exit(2);
	}
}

function readColors(themeName) {
	const colorsPath = path.join(process.env.HOME || '/home/shui', '.config', 'themes', themeName, 'colors.txt');
	try {
		if (fs.existsSync(colorsPath)) {
			const data = fs.readFileSync(colorsPath, 'utf8');
			return data.split('\n').reduce((acc, line) => {
				const [key, value] = line.split(':').map(s => s.trim());
				if (key && value) {
					acc[key] = value;
				}
				return acc;
			}, {});
		}
	} catch (err) {
		console.error('Error reading colors:', err.message);
	}
	// Fallback default colors to avoid breaking other scripts
	return {};
}

function setWallpaper(themeName) {
	try {
		const themeDir = path.join(process.env.HOME || '/home/shui', '.config', 'themes', themeName);
		const candidates = [
			path.join(themeDir, 'wp.jpg'),
			path.join(themeDir, 'wp.png'),
			path.join(themeDir, 'wallpaper.jpg'),
			path.join(themeDir, 'wallpaper.png'),
		];
		const imagePath = candidates.find(p => {
			try { return fs.existsSync(p); } catch (_) { return false; }
		});

		if (imagePath) {
			execFileSync('feh', ['--bg-fill', imagePath], { stdio: 'ignore' });
		}
	} catch (err) {
		console.error('Error setting wallpaper with feh:', err.message);
	}
}

function setAlacrittyTheme(themeName) {
	const alacrittyConfigPath = path.join(process.env.HOME || '/home/shui', '.config', 'alacritty', 'alacritty.toml');
	try {
		const newConfig = "general.import = [\n  \"~/.config/themes/" + themeName + "/alacritty.toml\"\n]";
		fs.writeFileSync(alacrittyConfigPath, newConfig);
	} catch (err) {
		console.error('Error setting theme in alacritty:', err.message);
	}
}

function setBspwmTheme(themeName) {
	const colors = readColors(themeName);
	try {
		execFileSync('bspc', ['config', 'focused_border_color', colors.fg ], { stdio: 'ignore' });
		execFileSync('bspc', ['config', 'normal_border_color', colors.bg ], { stdio: 'ignore' });
		execFileSync('bspc', ['config', 'active_border_color', colors.desactive ], { stdio: 'ignore' });
	} catch (err) {
		console.error('Error setting theme in bspwm:', err.message);
	}
}

function setVscodeTheme(themeName) {
	try {
		execFileSync('cp', [
			path.join(process.env.HOME || '/home/shui', '.config', 'themes', themeName, 'vscode_settings.json'),
			path.join(process.env.HOME || '/home/shui', '.config', 'Code', 'User', 'settings.json')
		]);
	} catch (err) {
		console.error('Error setting theme in vscode:', err.message);
	}
}

function setDunstTheme(themeName) {
	const colors = readColors(themeName);
	try {
		execFileSync('sed', ['-i', `0,/foreground = .*/s//foreground = "${colors.fg}"/`, '/home/shui/.config/dunstrc']);
		execFileSync('sed', ['-i', `0,/frame_color = .*/s//frame_color = "${colors.desactive}"/`, '/home/shui/.config/dunstrc']);
		execFileSync('sed', ['-i', `/background = .*/s//background = "${colors.bg}"/`, '/home/shui/.config/dunstrc']);
		execFileSync('killall', ['dunst']);
	} catch (err) {
		console.error('Error setting theme in dunst:', err.message);
	}
}

function setTheme(themeName) {
	const cfg = readConfig();
	cfg.theme = themeName;
	writeConfig(cfg);

	setWallpaper(themeName);
	setAlacrittyTheme(themeName);
	setBspwmTheme(themeName);
	setVscodeTheme(themeName);
	setDunstTheme(themeName);

	return themeName;
}

if (require.main === module) {
	const themeArg = process.argv[2];
	if (!themeArg) {
		console.error('Usage: node set-theme.js <themeName>');
		process.exit(1);
	}

	const result = setTheme(themeArg.trim());
	console.log(result);
}

module.exports = { setTheme };


if (require.main === module) {
	const themeArg = process.argv[2];
	if (!themeArg) {
		console.error('Usage: node set-theme.js <themeName>');
		process.exit(1);
	}

	const result = setTheme(themeArg.trim());
	console.log(result);
}

module.exports = { setTheme };

