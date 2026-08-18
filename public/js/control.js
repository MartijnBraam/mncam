class MisirkaSlider {
    constructor(client, topic, label, formatter) {
        this.client = client;
        this.topic = topic;
        this.label = label;
        this.formatter = formatter;

        this.node = undefined;
        this.value = undefined;

        this._val = undefined;

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
                this.node.value = value;
                this.value.innerText = this.formatter(value);
                break;
            case this.topic + "-min":
                this.node.min = value;
                this.node.value = this._val;
                break;
            case this.topic + "-max":
                this.node.max = value;
                this.node.value = this._val;
                break;
        }
    }

    dom() {
        const group = document.createElement("group");
        group.dataset.topic = this.topic;

        const label = document.createElement("label");
        label.htmlFor = this.topic;
        label.innerText = this.label;
        group.appendChild(label);

        const slider = document.createElement("input");
        slider.type = "range";
        slider.id = this.topic;
        slider.step = "0.02";
        slider.disabled = true;
        this.node = slider;
        group.appendChild(slider);

        slider.addEventListener("click", (event) => {
            event.preventDefault();
            this.client.call_unsafe("set-" + this.topic, {"value": parseFloat(slider.value)});
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
    label.innerText = "Tally";
    section.appendChild(label);
    controls.appendChild(section);
    section.appendChild(new MisirkaRadio(misirka, "tally", "Tally", {
        0: "Off",
        1: "Program",
        2: "Preview",
    }).dom());

});