#!/usr/bin/env node
const readline = require('readline');
const fs = require('fs');
const path = require('path');
const slog = require('single-line-log').stdout;

const MODE = {
    stat: 0,
    data: 1,
    result: 2,
    noout: 3
}
let mode = MODE.stat;
let filename = process.argv[3];
switch (process.argv[2]) {
    case '-d':
    case '--data':
        mode = MODE.data;
        break;
    case '-r':
    case '--result':
        mode = MODE.result;
        break;
    case '-n':
    case '--noout':
        mode = MODE.noout;
        break;
    default:
        filename = process.argv[2];
}

const rl = readline.createInterface({
    input: filename ?
        fs.createReadStream(path.join(process.cwd(), filename)) :
        process.stdin,
});

let stat = {
    succeed: 0,
    failed: 0,
    x_slide: {
        succeed: 0,
        failed: 0
    },
    xy_slide: {
        succeed: 0,
        failed: 0
    },
    result: {
        score51: 0,
        error: 0,
        banip: 0,
        others: 0
    }
}

rl.on('line', (line) => {
    let m = line.match(/^.*BR_DEBUG[^{]*({.*})$/)
    if (!m) {
        return;
    }

    data = JSON.parse(m[1]);
    if (data.success || data.succeed) {
        stat.succeed++;
        if (data.xy_slide || data['xy-slide']) {
            stat.xy_slide.succeed++;
        } else {
            stat.x_slide.succeed++;
        }
    } else {
        stat.failed++;
        if (data.xy_slide || data['xy-slide']) {
            stat.xy_slide.failed++;
        } else {
            stat.x_slide.failed++;
        }
        if (mode == MODE.data) {
            console.log(JSON.stringify(data.val_data));
        } else if (mode == MODE.result) {
            console.log(data.result);
        }
        if (data.result == '{"score":51,"success":false}') {
            stat.result.score51++;
        } else if (data.result == '{"error":"error","success":false}') {
            stat.result.error++;
        } else if (/Oops! your page is missing!!!/.test(data.result)) {
            stat.result.banip++;
        } else {
            stat.result.others++;
        }
    }
    if (!filename && mode == MODE.stat) {
        calculate(stat);
        calculate(stat.x_slide);
        calculate(stat.xy_slide);
        slog('success rate: ' + stat.rate +
            '    xy_success: ' + stat.xy_slide.rate +
            '    x_success: ' + stat.x_slide.rate +
            '    count: ' + (stat.succeed + stat.failed));
    }
});

rl.on('close', () => {
    stop();
});

function stop() {
    if (mode == MODE.stat) {
        if (!filename) {
            slog('')
        }
        calculate(stat);
        calculate(stat.x_slide);
        calculate(stat.xy_slide);
        console.log(stat);
    }
}

function calculate(data) {
    data.rate = data.succeed / (data.succeed + data.failed);
    data.rate = Math.round(data.rate * 100) + '%';
}
