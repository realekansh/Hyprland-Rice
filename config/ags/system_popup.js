const SystemTray = await Service.import('systemtray');
const Network = await Service.import('network');

const Utils = await import('resource:///com/github/Aylur/ags/utils.js');

let lastCpuIdle = 0;
let lastCpuTotal = 0;

const cpu = Variable(0, {
    poll: [2000, 'cat /proc/stat', out => {
        try {
            const fields = out.split('\n')[0].split(/\s+/).slice(1).map(Number);
            const idle = fields[3];
            const total = fields.reduce((a, b) => a + b, 0);
            const diffIdle = idle - lastCpuIdle;
            const diffTotal = total - lastCpuTotal;
            lastCpuIdle = idle;
            lastCpuTotal = total;
            return diffTotal > 0 ? (100 * (1 - diffIdle / diffTotal)) : 0;
        } catch(e) { return 0; }
    }],
});

const ram = Variable(0, {
    poll: [2000, 'cat /proc/meminfo', out => {
        try {
            const lines = out.split('\n');
            const total = parseInt(lines.find(l => l.startsWith('MemTotal:')).split(/\s+/)[1]);
            const free = parseInt(lines.find(l => l.startsWith('MemFree:')).split(/\s+/)[1]);
            const buffers = parseInt(lines.find(l => l.startsWith('Buffers:')).split(/\s+/)[1]);
            const cached = parseInt(lines.find(l => l.startsWith('Cached:')).split(/\s+/)[1]);
            const used = total - free - buffers - cached;
            return { used: (used / 1024 / 1024).toFixed(1), total: (total / 1024 / 1024).toFixed(1) };
        } catch(e) { return {used: 0, total: 0}; }
    }],
});

const gpu = Variable('N/A', {
    poll: [2000, 'bash -c "cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo N/A"', out => out.trim()]
});

const disk = Variable('0%', {
    poll: [10000, 'bash -c "df -h / | awk \'NR==2 {print $5}\'"', out => out.trim()]
});

const temp = Variable('0', {
    poll: [2000, 'bash -c "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0"', out => (parseInt(out) / 1000).toFixed(0)]
});

const updates = Variable('0', {
    poll: [3600000, 'bash -c "$HOME/.config/waybar/scripts/getupdates.sh"', out => {
        try { return JSON.parse(out).text; } catch(e) { return '0'; }
    }]
});

const github = Variable('0', {
    poll: [3600000, 'bash -c "$HOME/.config/waybar/scripts/github.sh"', out => {
        try { return JSON.parse(out).text; } catch(e) { return '0'; }
    }]
});

const SysTray = () => Widget.Box({
    class_name: 'tray-container',
    spacing: 8,
    children: SystemTray.bind('items').as(i => i.map(item => Widget.Button({
        class_name: 'tray-btn',
        child: Widget.Icon({ icon: item.bind('icon') }),
        on_primary_click: (_, event) => item.activate(event),
        on_secondary_click: (_, event) => item.openMenu(event),
        tooltip_markup: item.bind('tooltip_markup'),
    }))),
});

const Metric = (icon, name, valueBind, onClick = null) => Widget.Button({
    class_name: 'metric-box',
    on_clicked: onClick,
    child: Widget.Box({
        spacing: 15,
        children: [
            Widget.Label({ class_name: 'metric-icon', label: icon }),
            Widget.Box({
                vertical: true,
                vpack: 'center',
                children: [
                    Widget.Label({ class_name: 'metric-name', label: name, xalign: 0 }),
                    Widget.Label({ class_name: 'metric-val', label: valueBind, xalign: 0 }),
                ]
            })
        ]
    })
});

const SystemPopup = () => Widget.Box({
    class_name: 'system-popup-main',
    vertical: true,
    spacing: 20,
    children: [
        Widget.Box({
            hpack: 'end',
            child: SysTray()
        }),
        Widget.Box({
            spacing: 20,
            children: [
                Widget.Box({
                    vertical: true,
                    spacing: 10,
                    children: [
                        Metric('', 'CPU', cpu.bind().as(v => `${v.toFixed(1)}%`)),
                        Metric('', 'RAM', ram.bind().as(v => `${v.used} GB`)),
                        Metric('', 'GPU', gpu.bind().as(v => `${v}%`)),
                        Metric('', 'Disk', disk.bind()),
                    ]
                }),
                Widget.Box({
                    vertical: true,
                    spacing: 10,
                    children: [
                        Metric('', 'Temp', temp.bind().as(v => `${v}°C`)),
                        Metric('', 'Network', Network.wifi.bind('internet').as(i => i === 'connected' ? 'Online' : 'Offline')),
                        Metric('', 'Updates', updates.bind(), () => Utils.execAsync('bash -c "$HOME/.config/waybar/scripts/installupdates.sh"')),
                        Metric('', 'GitHub', github.bind()),
                    ]
                })
            ]
        })
    ]
});

export const SystemPopupWindow = Widget.Window({
    name: 'system_popup',
    class_name: 'system-window',
    anchor: ['top', 'bottom', 'left', 'right'],
    exclusivity: 'ignore',
    visible: false,
    keymode: "on-demand",
    setup: self => self.keybind("Escape", () => App.closeWindow('system_popup')),
    child: Widget.EventBox({
        class_name: 'popup-bg',
        on_primary_click: () => App.closeWindow('system_popup'),
        on_secondary_click: () => App.closeWindow('system_popup'),
        child: Widget.Box({
            vertical: true,
            hpack: 'end',
            vpack: 'start',
            css: 'margin-top: 60px; margin-right: 400px;', // Position it below the gear icon
            child: Widget.EventBox({
                on_primary_click: () => true, // Stop clicks from bubbling to the background
                on_secondary_click: () => true,
                child: SystemPopup(),
            })
        })
    })
}).hook(App, (self, windowName, visible) => {
    if (windowName === 'system_popup') {
        Utils.execAsync(`bash -c "echo ${visible ? 1 : 0} > /tmp/popup_state; pkill -RTMIN+10 -x waybar"`).catch(print);
    }
}, 'window-toggled');
