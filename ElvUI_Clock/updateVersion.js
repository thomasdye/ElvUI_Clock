const fs = require('fs');
const readline = require('readline');

// Function to read the TOC file and get the current version number
function getCurrentVersion(tocFilePath) {
    const fileContent = fs.readFileSync(tocFilePath, 'utf-8');
    const versionLine = fileContent.split('\n').find(line => line.startsWith('## Version:'));
    const currentVersion = versionLine.split(':')[1].trim();
    return currentVersion;
}

// Function to prompt the user for the new version number
function promptNewVersion(currentVersion) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    return new Promise((resolve) => {
        const askVersion = () => {
            rl.question(`Current version is ${currentVersion}.\n\nEnter the new version: `, (newVersion) => {
                if (isNewVersionHigher(currentVersion, newVersion)) {
                    rl.close();
                    resolve(newVersion);
                } else {
                    console.log(`\nThe new version (${newVersion}) must be higher than the current version (${currentVersion}). Please try again.`);
                    askVersion();
                }
            });
        };
        askVersion();
    });
}

// Function to update the TOC file with the new version number
function updateVersion(tocFilePath, newVersion) {
    let fileContent = fs.readFileSync(tocFilePath, 'utf-8');
    fileContent = fileContent.replace(/## Version: .*/, `## Version: ${newVersion}`);
    fs.writeFileSync(tocFilePath, fileContent, 'utf-8');
}

// Function to compare the current and new version numbers
function isNewVersionHigher(currentVersion, newVersion) {
    const currentVersionNumber = parseInt(currentVersion.replace(/\./g, ''), 10);
    const newVersionNumber = parseInt(newVersion.replace(/\./g, ''), 10);
    return newVersionNumber > currentVersionNumber;
}

// Main function to orchestrate the version update
async function main() {
    const tocFilePath = './ElvUI_Clock.toc';

    try {
        const currentVersion = getCurrentVersion(tocFilePath);
        const newVersion = await promptNewVersion(currentVersion);
        updateVersion(tocFilePath, newVersion);
        console.log(`Updated version from ${currentVersion} to ${newVersion} in ${tocFilePath}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
    }
}

main();
