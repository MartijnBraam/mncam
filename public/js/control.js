class MisirkaSlider {
    constructor(client, topic, label, formatter) {
        this.client = client;
        this.topic = topic;
        this.label = label;
        this.formatter = formatter;

        this.node = undefined;
        this.value = undefined;
        this.level = undefined;

        this.handle = undefined;

        // Slider state
        this._val = undefined;
        this._min = 0;
        this._max = 100;
        this._scale = 1;
        this._dx = 0;
        this._dv = 0;
        this._ev_move = undefined;
        this._ev_up = undefined;

        const self = this;
        client.on_alive(() => {
            client.subscribe_unsafe([topic, topic + "-min", topic + "-max"], (key, value) => {
                self._on_message(key, value)
            });
            this.node.disabled = false;
        });
        client.on_dead(() => {
            this.node.disabled = true;
        });
    }

    _on_message(key, value) {
        if (this.node === undefined) {
            return;
        }
        switch (key) {
            case this.topic:
                this._val = value;
                this.value.innerText = this.formatter(value);
                break;
            case this.topic + "-min":
                this._min = value;
                this.node.value = this._val;
                break;
            case this.topic + "-max":
                this._max = value;
                this.node.value = this._val;
                break;
        }
        this._update_handle();
    }

    _update_handle() {
        const size = this.handle.offsetWidth;
        const length = this.node.offsetWidth;
        const fraction = (this._val - this._min) / (this._max - this._min);
        const pos = fraction * (length - size);
        this.handle.style.left = pos + "px";
        this.level.style.width = (fraction * 100) + "%";
        this._scale = (this._max - this._min) / (length - size);
    }

    _mouse_move(event) {
        let speed = 1;
        if (event.getModifierState("Control")) {
            speed = 0.1;
        }
        const offset = event.clientX - this._dx;
        const val = (offset * this._scale * speed) + this._dv;
        const clamped = Math.min(Math.max(val, this._min), this._max);
        this.client.call_unsafe("set-" + this.topic, {"value": clamped});
    }

    _mouse_up(event) {
        document.removeEventListener("mousemove", this._ev_move);
        document.removeEventListener("mouseup", this._ev_up);
    }

    dom() {
        const group = document.createElement("group");
        group.dataset.topic = this.topic;

        const label = document.createElement("label");
        label.htmlFor = this.topic;
        label.innerText = this.label;
        group.appendChild(label);

        const slider = document.createElement("slider");
        const track = document.createElement("track");
        const level = document.createElement("level");
        track.appendChild(level);
        const handle = document.createElement("handle");
        slider.appendChild(track);
        slider.appendChild(handle);
        this.node = slider;
        this.handle = handle;
        this.level = level;
        group.appendChild(slider);

        handle.addEventListener("mousedown", (event) => {
            event.preventDefault();
            this._dx = event.pageX;
            this._dv = this._val;

            this._ev_move = this._mouse_move.bind(this);
            this._ev_up = this._mouse_up.bind(this);
            document.addEventListener("mousemove", this._ev_move);
            document.addEventListener("mouseup", this._ev_up);
        });
        handle.addEventListener("click", (event) => {
            event.stopPropagation()
        });

        slider.addEventListener("click", (event) => {
            const size = this.handle.offsetWidth;
            const val = (event.offsetX - (size / 2)) * this._scale + this._min;
            const clamped = Math.min(Math.max(val, this._min), this._max);
            this.client.call_unsafe("set-" + this.topic, {"value": clamped});
        });

        const val = document.createElement("span");
        this.value = val;
        group.appendChild(val);

        return group;
    }
}

class MisirkaToggle {
    constructor(client, topic, label) {
        this.client = client;
        this.topic = topic;
        this.label = label;

        this.node = undefined;
        this.value = undefined;

        const self = this;
        client.on_alive(function () {
            client.subscribe_unsafe([topic], (key, value) => {
                self._on_message(key, value)
            });
        });
    }

    _on_message(key, value) {
        if (this.node === undefined) {
            return;
        }
        if (value) {
            this.node.classList.add("active");
        } else {
            this.node.classList.remove("active");
        }
    }

    dom() {
        const group = document.createElement("group");
        group.dataset.topic = this.topic;

        const label = document.createElement("label");
        label.innerText = this.label;
        group.appendChild(label);

        const button = document.createElement("button");
        this.node = button;
        button.innerText = this.topic;
        button.addEventListener("click", (event) => {
            event.preventDefault();
            const state = button.classList.contains("active");
            this.client.call_unsafe("set-" + this.topic, {"value": !state});
        });
        group.appendChild(button);
        return group;
    }
}

class MisirkaRadio {
    constructor(client, topic, label, choices) {
        this.client = client;
        this.topic = topic;
        this.label = label;
        this.choices = choices;

        this.node = undefined;
        this.value = undefined;
        this.numeric = true;

        for (let key of Object.keys(this.choices)) {
            if (!isNaN(key) && !isNaN(parseFloat(key))) {
                // Key is a number
            } else {
                // Key is a string
                this.numeric = false;
            }
        }

        const self = this;
        client.on_alive(function () {
            client.subscribe_unsafe([topic], (key, value) => {
                self._on_message(key, value)
            });
        });
    }

    _on_message(key, value) {
        if (this.node === undefined) {
            return;
        }
        this.node[this.topic].value = value;
    }

    dom() {
        const group = document.createElement("group");
        group.dataset.topic = this.topic;

        const label = document.createElement("label");
        label.innerText = this.label;
        group.appendChild(label);

        const form = document.createElement("form");
        form.classList.add("button-group");

        for (let key of Object.keys(this.choices)) {
            let label = document.createElement("label");
            let radio = document.createElement("input");
            radio.type = "radio";
            radio.value = key;
            radio.name = this.topic;
            radio.addEventListener("click", (event) => {
                event.preventDefault();
                let val = key;
                if (this.numeric) {
                    val = parseInt(key, 10);
                }
                this.client.call_unsafe("set-" + this.topic, {"value": val});
            });
            label.appendChild(radio);
            label.append(this.choices[key]);
            label.dataset.option = key;
            label.dataset.topic = this.topic;
            form.appendChild(label);
        }
        group.appendChild(form);
        this.node = form;
        return group;
    }
}

function fmt(template, ...args) {
    const re = /(\{.*})/g;
    const parts = template.toString().split(re).filter(Boolean);
    for (let i = 0; i < parts.length; i++) {
        if (parts[i].startsWith('{')) {
            let args = parts[i].replace('{', '').replace('}', '');
            if (args.length === 0) {
                parts[i] = function (val) {
                    return val;
                }
            } else if (args.endsWith('f')) {
                args = args.replace('f', '');
                const precision = parseInt(args, 10);
                parts[i] = function (val) {
                    return val.toFixed(precision);
                }
            }
        }
    }

    return function (val) {
        let result = '';
        for (let i = 0; i < parts.length; i++) {
            if (typeof parts[i] === 'function') {
                result += parts[i](val);
            } else {
                result += parts[i];
            }
        }
        return result;
    }
}

document.addEventListener("DOMContentLoaded", function () {
    const misirka = new Misirka.WSClient({"ws_url": "/api/ws"});
    const controls = document.getElementById("controls");

    // Exposure controls
    let section = document.createElement("section");
    let label = document.createElement("label");
    label.innerText = "Exposure";
    section.appendChild(label);
    controls.appendChild(section);
    section.appendChild(new MisirkaToggle(misirka, "auto-exposure", "Auto Exposure").dom());
    section.appendChild(new MisirkaSlider(misirka, "auto-exposure-compensation", "Auto Exposure Compensation", fmt`{0f} EV`).dom());
    section.appendChild(new MisirkaSlider(misirka, "gain", "Gain", fmt`{0f} dB`).dom());
    section.appendChild(new MisirkaSlider(misirka, "shutter", "Shutter", fmt`1/{}`).dom());

    section = document.createElement("section");
    label = document.createElement("label");
    label.innerText = "Whitebalance";
    section.appendChild(label);
    controls.appendChild(section);
    section.appendChild(new MisirkaToggle(misirka, "awb", "Auto Whitebalance").dom());
    section.appendChild(new MisirkaSlider(misirka, "temperature", "Temperature", fmt`{}K`).dom());
    section.appendChild(new MisirkaRadio(misirka, "awb-mode", "Mode", {
        auto: "Auto",
        tungsten: "Tungsten",
        fluorescent: "Fluorescent",
        indoor: "Indoor",
        daylight: "Daylight",
        cloudy: "Cloudy",
    }).dom());

    section = document.createElement("section");
    let reset = document.createElement("button");
    reset.innerText = "\u238C";
    reset.classList.add("reset");
    reset.title = "Reset Primary Corrector";
    reset.addEventListener("click", (event) => {
        event.preventDefault();
        misirka.call_unsafe("cc-reset", {});
    })
    section.appendChild(reset)

    label = document.createElement("label");
    label.innerText = "Primary Corrector";
    section.appendChild(label);
    controls.appendChild(section);
    section.appendChild(new MisirkaSlider(misirka, "cc-lift", "Lift", fmt`{3f}`).dom());
    section.appendChild(new MisirkaSlider(misirka, "cc-gamma", "Gamma", fmt`{3f}`).dom());
    section.appendChild(new MisirkaSlider(misirka, "cc-gain", "Gain", fmt`{3f}`).dom());
    section.appendChild(new MisirkaSlider(misirka, "cc-offset", "Offset", fmt`{3f}`).dom());

    section = document.createElement("section");
    label = document.createElement("label");
    label.innerText = "Secondary Corrector";
    section.appendChild(label);
    controls.appendChild(section);
    section.appendChild(new MisirkaSlider(misirka, "saturation", "Saturation", fmt`{3f}`).dom());
    section.appendChild(new MisirkaSlider(misirka, "sharpness", "Sharpness", fmt`{3f}`).dom());

    section = document.createElement("section");
    label = document.createElement("label");
    label.innerText = "Tally";
    section.appendChild(label);
    controls.appendChild(section);
    section.appendChild(new MisirkaRadio(misirka, "tally", "Tally", {
        0: "Off",
        1: "Program",
        2: "Preview",
    }).dom());

});