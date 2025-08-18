const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const configPath = path.join(__dirname, 'boolean.json');

function readConfig() {
    try {
        if (fs.existsSync(configPath)) {
            const data = fs.readFileSync(configPath, 'utf8');
            return JSON.parse(data);
        } else {
            console.error('Config file not found');
        }
    } catch (error) {
        console.error('Error reading config:', error);
    }
}

function writeConfig(config) {
    try {
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
    } catch (error) {
        console.error('Error writing config:', error);
    }
}

function toggleDmenu() {
    const config = readConfig();
    config.dmenuVisible = !config.dmenuVisible;
    writeConfig(config);

    if (!config.dmenuVisible) {
        setTimeout(() => {
            execSync('bspc config left_padding 0');
        }, 100);
    }
}

function isDmenuVisible() {
    const config = readConfig();
    return config.dmenuVisible;
}

if (typeof process !== 'undefined' && process.argv) {
    const args = process.argv.slice(2);
    
    if (args.length > 0) {
        const command = args[0];
        
        switch (command) {
            case 'toggle':
                console.log(toggleDmenu());
                break;
            case 'status':
            case 'visible':
                console.log(isDmenuVisible());
                break;
            default:
                console.log('Available commands: toggle, status, visible');
        }
    }
}