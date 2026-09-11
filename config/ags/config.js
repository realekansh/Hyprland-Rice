const mpris = await Service.import('mpris');


const WINDOW_NAME = 'media_popup';

function lengthStr(length) {
    const min = Math.floor(length / 60);
    const sec = Math.floor(length % 60);
    const sec0 = sec < 10 ? '0' : '';
    return `${min}:${sec0}${sec}`;
}

const PlayerPopup = () => Widget.Box({
    class_name: "player-popup",
    children: [
        Widget.Box({
            setup: self => {
                const update = () => {
                    const player = mpris.getPlayer();
                    if (!player) {
                        self.children = [Widget.Label("No media playing")];
                        return;
                    }

                    const cover = Widget.Box({
                        class_name: "cover",
                        css: `background-image: url('${player.cover_path}');`
                    });

                    const title = Widget.Label({
                        class_name: "title",
                        label: player.track_title || "Unknown Title",
                        justification: "left",
                        truncate: "end",
                        xalign: 0,
                        maxWidthChars: 30,
                    });

                    const artist = Widget.Label({
                        class_name: "artist",
                        label: player.track_artists.join(", ") || "Unknown Artist",
                        justification: "left",
                        truncate: "end",
                        xalign: 0,
                        maxWidthChars: 30,
                    });

                    const positionLabel = Widget.Label({
                        class_name: "position",
                        label: lengthStr(player.position),
                    });
                    
                    const lengthLabel = Widget.Label({
                        class_name: "length",
                        label: lengthStr(player.length),
                    });

                    const slider = Widget.Slider({
                        class_name: "slider",
                        hexpand: true,
                        draw_value: false,
                        on_change: ({ value }) => player.position = value * player.length,
                        setup: slider => {
                            const updateSlider = () => {
                                if (player.length > 0) {
                                    slider.value = player.position / player.length;
                                }
                            };
                            slider.hook(player, updateSlider, "position");
                            slider.poll(1000, updateSlider);
                        }
                    });

                    positionLabel.hook(player, () => {
                        positionLabel.label = lengthStr(player.position);
                    }, "position");
                    positionLabel.poll(1000, () => {
                        positionLabel.label = lengthStr(player.position);
                    });

                    const progressBox = Widget.Box({
                        class_name: "progress-box",
                        children: [positionLabel, slider, lengthLabel],
                    });

                    const btnPrev = Widget.Button({
                        class_name: "btn-prev",
                        child: Widget.Icon("media-skip-backward-symbolic"),
                        on_clicked: () => player.previous(),
                    });

                    const btnPlay = Widget.Button({
                        class_name: "btn-play",
                        child: Widget.Icon({
                            icon: player.bind('play_back_status').transform(s => {
                                switch (s) {
                                    case "Playing": return "media-playback-pause-symbolic";
                                    case "Paused":
                                    case "Stopped": return "media-playback-start-symbolic";
                                }
                            })
                        }),
                        on_clicked: () => player.playPause(),
                    });

                    const btnNext = Widget.Button({
                        class_name: "btn-next",
                        child: Widget.Icon("media-skip-forward-symbolic"),
                        on_clicked: () => player.next(),
                    });

                    const controls = Widget.Box({
                        class_name: "controls",
                        hpack: "center",
                        children: [btnPrev, btnPlay, btnNext]
                    });

                    const info = Widget.Box({
                        vertical: true,
                        children: [title, artist, progressBox, controls]
                    });

                    self.children = [cover, info];
                };

                self.hook(mpris, update, "player-changed");
                self.hook(mpris, update, "player-added");
                self.hook(mpris, update, "player-closed");
                update();
            }
        })
    ]
});

const MediaWindow = Widget.Window({
    name: WINDOW_NAME,
    class_name: "media-window",
    anchor: ["top", "left"],
    margins: [10, 10, 10, 200], // Adjust these margins to place it near the Waybar module

    visible: false,
    child: PlayerPopup(),
    keymode: "on-demand",
    setup: self => {
        // Close on clicking outside since it's a popup window
        self.keybind("Escape", () => App.closeWindow(WINDOW_NAME));
    }
});

import { SystemPopupWindow } from './system_popup.js';

App.config({
    style: "./style.css",
    windows: [MediaWindow, SystemPopupWindow],
});
